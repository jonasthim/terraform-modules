# This example intentionally uses an invalid tunnel name to test validation.
# Running terraform validate on this should succeed (it's syntactically valid),
# but terraform plan/apply would fail due to the tunnel name validation.

module "cloudflare_magic" {
  source = "../../"

  cloudflare_api_token = var.cloudflare_api_token

  domain = {
    name    = "example.com"
    target  = "203.0.113.1"
    proxied = true
  }

  default_tunnel_name    = "fallback-tunnel"
  default_allowed_emails = ["admin@example.com"]

  dns_records = [
    {
      name = "app"
      zero_trust = {
        protected = true
        tunnel = {
          name           = "-invalid-name"
          local_protocol = "http"
          local_port     = "3000"
        }
      }
    }
  ]
}
