terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}
output "test" {
  value = var.cloudflare_api_token
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
  proxied         = true
  allow_overwrite = true
}

resource "cloudflare_record" "dns" {
  for_each = {
    for index, record in var.dns_records :
    record.name => record
    if record.protected != true || record.local-port != ""
  }
  zone_id         = data.cloudflare_zone.domain.zone_id
  name            = each.value.name
  value           = each.value.value
  type            = each.value.type
  ttl             = each.value.proxied ? 1 : var.default_ttl
  proxied         = each.value.proxied
  allow_overwrite = true
}

resource "cloudflare_access_application" "cf_app" {
  for_each = {
    for index, record in var.dns_records : index => record
    if record.protected == true
  }
  zone_id          = data.cloudflare_zone.domain.zone_id
  name             = each.value.name
  domain           = "${each.value.name}.${var.domain.name}"
  session_duration = "1h"
}

resource "cloudflare_access_policy" "policy" {
  for_each       = cloudflare_access_application.cf_app
  application_id = cloudflare_access_application.cf_app[each.key].id
  zone_id        = data.cloudflare_zone.domain.zone_id
  name           = "Allowed e-mailaddresses for ${var.dns_records[each.key].name}"
  precedence     = "1"
  decision       = "allow"

  include {
    email = var.dns_records[each.key].allowed_emails
  }
}

resource "cloudflare_argo_tunnel" "home" {
  account_id = data.cloudflare_zone.domain.account_id
  name       = "Home"
  secret     = var.tunnel_secret
}

output "key" {
  value     = cloudflare_argo_tunnel.home.tunnel_token
  sensitive = true
}

resource "cloudflare_tunnel_config" "tunnel" {
  account_id = data.cloudflare_zone.domain.account_id
  tunnel_id  = cloudflare_argo_tunnel.home.id
  config {
    dynamic "ingress_rule" {
      for_each = {
        for index, record in var.dns_records :
        record.name => record
        if record.protected == true && record.local-port != ""
      }
      content {
        hostname = "${ingress_rule.value.name}.${var.domain.name}"
        service  = "${ingress_rule.value.protocol}://${ingress_rule.value.name}:${ingress_rule.value.local-port}"
      }
    }
    ingress_rule {
      service = "https://idontexist"
    }
  }

}