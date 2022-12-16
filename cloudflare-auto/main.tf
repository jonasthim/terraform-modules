terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

data "cloudflare_zone" "domain" {
  name = var.domain.name
}

resource "cloudflare_record" "domain" {
  zone_id         = data.cloudflare_zone.domain.zone_id
  name            = var.domain.name
  value           = var.domain.target
  type            = "A"
  ttl             = 1
  proxied         = var.domain.proxied ? var.domain.proxied : false
  allow_overwrite = true
}

resource "cloudflare_record" "dns" {
  for_each = {
    for index, record in var.dns_records :
    record.name => record
    if record.zero_trust == null || record.zero_trust.tunnel == null
  }
  zone_id         = data.cloudflare_zone.domain.zone_id
  name            = each.value.name 
  value           = each.value.value == null ? var.default_domain : each.value.value
  type            = each.value.type == null ? var.default_dns_type : each.value.type
  ttl             = each.value.proxied ? 1 : var.default_ttl
  proxied         = each.value.proxied
  allow_overwrite = true
}

resource "cloudflare_access_application" "cf_app" {
  for_each = {
    for index, record in var.dns_records : index => record
    if record.zero_trust != null
  }
  zone_id          = data.cloudflare_zone.domain.zone_id
  name             = title(each.value.name)
  domain           = "${each.value.name}.${var.domain.name}"
  session_duration = "1h"
  allowed_idps = each.value.allowed_idps
  auto_redirect_to_identity = true
}

resource "cloudflare_access_policy" "policy" {
  for_each       = cloudflare_access_application.cf_app
  application_id = cloudflare_access_application.cf_app[each.key].id
  zone_id        = data.cloudflare_zone.domain.zone_id
  name           = "Allowed e-mailaddresses for ${var.dns_records[each.key].allowed_emails == null ? var.default_allowed_emails : var.dns_records[each.key].allowed_emails}"
  precedence     = "1"
  decision       = "allow"
  include {
    email = var.dns_records[each.key].allowed_emails == null ? var.default_allowed_emails : var.dns_records[each.key].allowed_emails
  }
}

resource "cloudflare_argo_tunnel" "default" {
  count      = var.default_tunnel_name ? 1 : length(var.dns_records[*].zero_trust.name)
  account_id = data.cloudflare_zone.domain.account_id
  name       = var.default_tunnel_name
  secret     = var.tunnel_secret
}

resource "cloudflare_tunnel_config" "tunnel" {
  account_id = data.cloudflare_zone.domain.account_id
  tunnel_id  = cloudflare_argo_tunnel.default.id
  config {
    warp_routing {
      enabled = false
    }
    dynamic "ingress_rule" {
      for_each = {
        for index, record in var.dns_records :
        record.name => record
        if record.zero_trust.protected == true && record.zero_trust.local-port != ""
      }
      content {
        hostname = "${ingress_rule.value.name}.${var.domain.name}"
        service  = "${ingress_rule.value.zero_trust.local-protocol}://${ingress_rule.value.zero_trust.local-ip != "" ? ingress_rule.value.zero_trust.local-ip : ingress_rule.value.name}:${ingress_rule.value.zero_trust.local-port}"
      }
    }
    ingress_rule {
      service = "https://idontexist"
    }
  }
}

resource "cloudflare_record" "dns-tunnel" {
  for_each = {
    for index, record in var.dns_records :
    record.name => record
    if record.zero_trust.tunnel.local-protocol != ""
  }
  zone_id         = data.cloudflare_zone.domain.zone_id
  name            = each.value.name
  value           = "${cloudflare_tunnel_config.tunnel.id}.cfargotunnel.com"
  type            = each.value.type
  ttl             = each.value.proxied ? 1 : var.default_ttl
  proxied         = each.value.proxied
  allow_overwrite = true
}