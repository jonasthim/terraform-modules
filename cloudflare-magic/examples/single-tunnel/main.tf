module "cloudflare_magic" {
  source = "../../"

  cloudflare_api_token = var.cloudflare_api_token

  domain = {
    name    = "example.com"
    target  = "203.0.113.1"
    proxied = true
  }

  default_tunnel_name      = "prod-tunnel"
  default_allowed_emails   = ["admin@example.com"]
  default_session_duration = "24h"

  dns_records = [
    {
      name = "app"
      zero_trust = {
        protected = true
        tunnel = {
          name           = "prod-tunnel"
          local_protocol = "http"
          local_port     = "3000"
        }
      }
    },
    {
      name = "api"
      zero_trust = {
        protected = true
        tunnel = {
          name           = "prod-tunnel"
          local_protocol = "http"
          local_port     = "8080"
        }
      }
    }
  ]
}
