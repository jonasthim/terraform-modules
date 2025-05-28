/**
 * # Cloudflare Magic Terraform Module
 * 
 * This module manages Cloudflare resources including DNS records, Zero Trust applications,
 * and Cloudflare Tunnels.
 */

terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.20"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Retrieve the Cloudflare zone information for the domain
data "cloudflare_zone" "domain" {
  name = var.domain.name
}

locals {
  # Separate Zero Trust and public records for clearer logic
  zero_trust_records = [for record in var.dns_records : record if record.zero_trust != null]
  public_records     = [for record in var.dns_records : record if record.zero_trust == null]

  # Create a map for easier record lookups by name
  dns_records_by_name = {
    for record in var.dns_records : record.name => record
  }

  # Determine the effective tunnel name for each Zero Trust record
  # Priority: tunnel.name > default_tunnel_name
  tunnel_name_map = { for record in local.zero_trust_records :
    record.name => coalesce(
      try(record.zero_trust.tunnel.name, null),
      var.default_tunnel_name
    )
  }

  # Extract unique tunnel names from all records
  tunnel_names = distinct(values(local.tunnel_name_map))

  # Validate tunnel names to ensure they meet Cloudflare requirements
  validated_tunnel_names = [
    for name in local.tunnel_names : name
    if can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", name)) && length(name) <= 36
  ]

  # Check if any tunnel names are invalid
  invalid_tunnel_names = setsubtract(toset(local.tunnel_names), toset(local.validated_tunnel_names))
}

# Validation to catch invalid tunnel names early
resource "null_resource" "tunnel_name_validation" {
  count = length(local.invalid_tunnel_names) > 0 ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      echo "❌ ERROR: Invalid tunnel names detected: ${join(", ", local.invalid_tunnel_names)}"
      echo ""
      echo "Tunnel names must:"
      echo "  - Start and end with alphanumeric characters"
      echo "  - Contain only letters, numbers, and hyphens"
      echo "  - Be 36 characters or less"
      echo "  - Cannot be only hyphens"
      echo ""
      echo "Examples of valid names: 'prod-tunnel', 'staging', 'app1'"
      echo "Examples of invalid names: '-invalid', 'invalid-', 'a', 'really-long-tunnel-name-that-exceeds-limits'"
      exit 1
    EOT
  }

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  # Service configuration for each zero trust enabled record with better defaults
  service_config = { for record in local.zero_trust_records :
    record.name => {
      protocol = coalesce(try(record.zero_trust.tunnel.local_protocol, null), "http")
      ip       = coalesce(try(record.zero_trust.tunnel.local_ip, null), record.name)
      port     = coalesce(try(record.zero_trust.tunnel.local_port, null), "80")
    }
  }

  # Map to track which records should use which tunnel (simplified)
  tunnel_ingress_rules = { for tunnel_name in local.validated_tunnel_names :
    tunnel_name => [
      for record_name, mapped_tunnel in local.tunnel_name_map :
      record_name if mapped_tunnel == tunnel_name
    ]
  }

  # Create unique access policy configurations to reduce duplication
  access_policy_configs = {
    for record in local.zero_trust_records :
    record.name => {
      emails           = coalescelist(try(record.zero_trust.allowed_emails, []), var.default_allowed_emails)
      session_duration = coalesce(try(record.zero_trust.session_duration, null), var.default_session_duration, "1h")
      allowed_idps     = coalesce(try(record.zero_trust.allowed_idps, null), var.default_allowed_idps)
      app_type         = coalesce(try(record.zero_trust.app_type, null), "self_hosted")
    }
    if coalesce(try(record.zero_trust.protected, null), false) == true
  }

  # Group applications by their access policy configuration to enable policy sharing
  policy_groups = {
    for config_key, config in local.access_policy_configs :
    "${join("-", sort(config.emails))}-${config.session_duration}-${join("-", sort(config.allowed_idps))}-${config.app_type}" => config_key...
  }

  # Create unique policies based on configuration groups
  unique_policies = {
    for group_key, app_names in local.policy_groups :
    group_key => {
      name             = length(app_names) == 1 ? "Policy for ${title(app_names[0])}" : "Shared policy for ${length(app_names)} applications"
      emails           = local.access_policy_configs[app_names[0]].emails
      session_duration = local.access_policy_configs[app_names[0]].session_duration
      allowed_idps     = local.access_policy_configs[app_names[0]].allowed_idps
      app_type         = local.access_policy_configs[app_names[0]].app_type
      applications     = app_names
    }
  }

  # Map each application to its policy group for easy lookup
  app_to_policy_group = {
    for group_key, policy in local.unique_policies :
    group_key => {
      for app_name in policy.applications :
      app_name => group_key
    }
  }

  # Flatten the app to policy group mapping
  app_policy_mapping = merge(values(local.app_to_policy_group)...)

  # Create individual policy names for each application to avoid conflicts
  app_policy_names = {
    for app_name, group_key in local.app_policy_mapping :
    app_name => length(local.policy_groups[group_key]) == 1 ?
    "Policy for ${title(app_name)}" :
    "Policy for ${title(app_name)} (shared config)"
  }
}

# Generate secrets for tunnels
resource "random_id" "tunnel_secret" {
  for_each    = toset(local.validated_tunnel_names)  # Use validated names only
  byte_length = 32

  keepers = {
    tunnel_name = each.key
  }
}

# Create all required tunnels
resource "cloudflare_zero_trust_tunnel_cloudflared" "tunnel" {
  for_each   = toset(local.validated_tunnel_names)  # Use validated names only
  account_id = data.cloudflare_zone.domain.account_id
  name       = each.key
  secret     = random_id.tunnel_secret[each.key].b64_std  # Use standard base64 instead of URL-safe
}

# Configure tunnels with ingress rules
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "tunnel" {
  for_each   = cloudflare_zero_trust_tunnel_cloudflared.tunnel
  account_id = data.cloudflare_zone.domain.account_id
  tunnel_id  = each.value.id

  config {
    dynamic "ingress_rule" {
      for_each = local.tunnel_ingress_rules[each.key]

      content {
        hostname = "${ingress_rule.value}.${var.domain.name}"
        service  = "${local.service_config[ingress_rule.value].protocol}://${local.service_config[ingress_rule.value].ip}:${local.service_config[ingress_rule.value].port}"
        origin_request {
          no_tls_verify = coalesce(var.tunnel_no_tls_verify, true)
        }
      }
    }

    # Catch-all rule
    ingress_rule {
      service = var.tunnel_catch_all_service
    }
  }
}

# Create the main domain A record
resource "cloudflare_record" "domain" {
  zone_id         = data.cloudflare_zone.domain.zone_id
  name            = var.domain.name
  content         = var.domain.target
  type            = "A"
  ttl             = 1
  proxied         = coalesce(var.domain.proxied, false)
  allow_overwrite = true
}

# Create DNS records for non-zero-trust (public) services
resource "cloudflare_record" "public" {
  for_each = {
    for record in local.public_records : record.name => record
  }
  zone_id         = data.cloudflare_zone.domain.zone_id
  name            = each.value.name
  content         = coalesce(each.value.content, var.domain.name)
  type            = coalesce(each.value.type, "CNAME")
  ttl             = each.value.proxied == true ? 1 : coalesce(each.value.ttl, var.default_ttl)
  proxied         = coalesce(each.value.proxied, true)
  allow_overwrite = true
}

# Create Access Applications for protected (Zero Trust) services
resource "cloudflare_zero_trust_access_application" "protected" {
  for_each = local.access_policy_configs

  zone_id                   = data.cloudflare_zone.domain.zone_id
  name                      = title(each.key)
  domain                    = "${each.key}.${var.domain.name}"
  session_duration          = each.value.session_duration
  allowed_idps              = each.value.allowed_idps
  auto_redirect_to_identity = true
  type                      = each.value.app_type
}

# Create Access Policies - one policy per application with optimized naming
resource "cloudflare_zero_trust_access_policy" "protected" {
  for_each = local.access_policy_configs

  application_id = cloudflare_zero_trust_access_application.protected[each.key].id
  zone_id        = data.cloudflare_zone.domain.zone_id
  name           = local.app_policy_names[each.key]
  precedence     = "1"
  decision       = "allow"
  include {
    email = each.value.emails
  }
}

# Create CNAME records for tunnel-protected services
resource "cloudflare_record" "tunnel" {
  for_each = local.tunnel_name_map

  zone_id         = data.cloudflare_zone.domain.zone_id
  name            = each.key
  content         = "${cloudflare_zero_trust_tunnel_cloudflared.tunnel[each.value].id}.cfargotunnel.com"
  type            = "CNAME"
  ttl             = 1
  proxied         = true
  allow_overwrite = true
}