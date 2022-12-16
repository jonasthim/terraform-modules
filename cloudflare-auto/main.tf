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
  proxied         = var.domain.proxied != null ? var.domain.proxied : false
  allow_overwrite = true
}

resource "cloudflare_record" "dns" {
  for_each = {
    for record in var.dns_records : "${record["zero_trust"] != null ? record["zero_trust"]["tunnel"] != null ? true : false : false }" => record
    if !record.value 
  }
  zone_id         = data.cloudflare_zone.domain.zone_id
  name            = each.value.name
  value           = each.value.value == null ? var.domain.name : each.value.value
  type            = each.value.type == null ? "CNAME" : each.value.type
  ttl             = each.value.proxied != null ? each.value.proxied ? 1 : each.value.ttl != null ? each.value.ttl : var.default_ttl : var.default_ttl
  proxied         = each.value.proxied == null ? true : each.value.proxied
  allow_overwrite = true
}

# resource "cloudflare_access_application" "cf_app" {
#   for_each = {
#     for index, record in var.dns_records : record.name => record
#     if record.zero_trust != null ? record.zero_trust.protected != null : false
#   }
#   zone_id          = data.cloudflare_zone.domain.zone_id
#   name             = title(each.value.name)
#   domain           = "${each.value.name}.${var.domain.name}"
#   session_duration = "1h"
#   allowed_idps = each.value.zero_trust.allowed_idps == null ? var.default_allowed_idps : each.value.zero_trust.allowed_idps
#   auto_redirect_to_identity = true
# }

# resource "cloudflare_access_policy" "policy" {
#   for_each = {
#     for index, record in var.dns_records : record.name => record
#     if record.zero_trust != null ? record.zero_trust.protected != null : false
#   }
#   application_id = cloudflare_access_application.cf_app[each.value.name].id
#   zone_id        = data.cloudflare_zone.domain.zone_id
#   name           = "Allowed e-mailaddresses"
#   precedence     = "1"
#   decision       = "allow"
#   include {
#     email = each.value.zero_trust.allowed_emails == null ? var.default_allowed_emails : each.value.zero_trust.allowed_emails
#   }
# }

# resource "cloudflare_argo_tunnel" "default" {
#   for_each = {
#     for index, tunnel in compact(concat([var.default_tunnel_name], [for record in var.dns_records: record.zero_trust != null ? record.zero_trust.tunnel != null ? record.zero_trust.tunnel.name : "" : "" ])) : tunnel => tunnel
#   }
#   account_id = data.cloudflare_zone.domain.account_id
#   name       = each.value
#   secret     = var.tunnel_secret
# }

# resource "cloudflare_tunnel_config" "tunnel" {
#   for_each   = cloudflare_argo_tunnel.default
#   account_id = data.cloudflare_zone.domain.account_id
#   tunnel_id  = cloudflare_argo_tunnel.default[each.key].id
#   config {
#     warp_routing {
#       enabled = false
#     }
#     dynamic "ingress_rule" {
#       for_each = {
#         for index, record in var.dns_records :
#         record.name => record
#         if record.zero_trust != null ? record.zero_trust.protected == true ? record.zero_trust.tunnel != null ? record.zero_trust.tunnel.local-port != null : false : false : false
#       }
#       content {
#         hostname = "${ingress_rule.value.name}.${var.domain.name}"
#         service  = "${ingress_rule.value.zero_trust.tunnel.local-protocol == null ? "http" : ingress_rule.value.zero_trust.tunnel.local-protocol}://${ingress_rule.value.zero_trust.tunnel.local-ip != null ? ingress_rule.value.zero_trust.tunnel.local-ip : ingress_rule.value.name}:${ingress_rule.value.zero_trust.tunnel.local-port}"
#       }
#     }
#     ingress_rule {
#       service = "https://idontexist"
#     }
#   }
# }

# resource "cloudflare_record" "dns-tunnel" {
#   for_each = {
#     for index, record in var.dns_records :
#     record.name => record
#     if record.zero_trust != null ? record.zero_trust.tunnel != null : false
#   }
#   zone_id         = data.cloudflare_zone.domain.zone_id
#   name            = each.value.name
#   value           = "${cloudflare_tunnel_config.tunnel.id}.cfargotunnel.com"
#   type            = each.value.type
#   ttl             = each.value.proxied ? 1 : var.default_ttl
#   proxied         = each.value.proxied
#   allow_overwrite = true
# }