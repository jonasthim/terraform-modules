/**
 * Output values for the Cloudflare Magic module
 */

output "zone_id" {
  description = "The zone ID of the domain"
  value       = data.cloudflare_zone.domain.zone_id
}

output "zone_name" {
  description = "The zone name of the domain"
  value       = data.cloudflare_zone.domain.name
}

output "account_id" {
  description = "The account ID associated with the zone"
  value       = data.cloudflare_zone.domain.account_id
}

output "tunnels" {
  description = "Information about created tunnels"
  value = {
    for name, tunnel in cloudflare_zero_trust_tunnel_cloudflared.tunnel : name => {
      id    = tunnel.id
      name  = tunnel.name
      cname = "${tunnel.id}.cfargotunnel.com"
    }
  }
}

output "dns_records" {
  description = "Information about created DNS records"
  value = {
    domain = {
      name    = cloudflare_record.domain.name
      content = cloudflare_record.domain.content
      type    = cloudflare_record.domain.type
      proxied = cloudflare_record.domain.proxied
    }
    public = {
      for name, record in cloudflare_record.public : name => {
        name    = record.name
        content = record.content
        type    = record.type
        proxied = record.proxied
      }
    }
    tunneled = {
      for name, record in cloudflare_record.tunnel : name => {
        name    = record.name
        content = record.content
        type    = record.type
        proxied = record.proxied
      }
    }
  }
}

output "access_applications" {
  description = "Information about created Access applications"
  value = {
    for name, app in cloudflare_zero_trust_access_application.protected : name => {
      id               = app.id
      name             = app.name
      domain           = app.domain
      session_duration = app.session_duration
    }
  }
}

output "tunnel_commands" {
  description = "Commands to run cloudflared for each tunnel"
  value = {
    for name, tunnel in cloudflare_zero_trust_tunnel_cloudflared.tunnel : name =>
    "cloudflared tunnel run ${name}"
  }
}

output "debug_tunnel_mapping" {
  description = "Debug information showing tunnel name mapping"
  value = {
    tunnel_name_map      = local.tunnel_name_map
    tunnel_names         = local.tunnel_names
    tunnel_ingress_rules = local.tunnel_ingress_rules
    zero_trust_records   = local.zero_trust_records
    public_records       = local.public_records
  }
}

output "debug_policy_optimization" {
  description = "Debug information showing policy optimization and grouping"
  value = {
    access_policy_configs = local.access_policy_configs
    policy_groups        = local.policy_groups
    unique_policies      = local.unique_policies
    app_policy_mapping   = local.app_policy_mapping
    app_policy_names     = local.app_policy_names
  }
}
