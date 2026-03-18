module "cloudflare_magic" {
  source = "../../"

  cloudflare_api_token = var.cloudflare_api_token

  domain = {
    name    = "example.com"
    target  = "203.0.113.1"
    proxied = true
  }

  default_tunnel_name      = "main-tunnel"
  default_allowed_emails   = ["team@example.com"]
  default_session_duration = "12h"

  dns_records = [
    # Public DNS records
    {
      name    = "www"
      type    = "CNAME"
      content = "example.com"
      proxied = true
    },
    {
      name    = "mail"
      type    = "CNAME"
      content = "mail.provider.com"
      proxied = false
      ttl     = 3600
    },
    # Zero Trust protected services
    {
      name = "dashboard"
      zero_trust = {
        protected = true
        tunnel = {
          name           = "main-tunnel"
          local_protocol = "https"
          local_port     = "443"
        }
      }
    },
    {
      name = "grafana"
      zero_trust = {
        protected        = true
        allowed_emails   = ["ops@example.com"]
        session_duration = "8h"
        tunnel = {
          name           = "monitoring-tunnel"
          local_protocol = "http"
          local_port     = "3000"
        }
      }
    }
  ]
}
