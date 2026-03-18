module "cloudflare_magic" {
  source = "../../"

  cloudflare_api_token = var.cloudflare_api_token

  domain = {
    name    = "example.com"
    target  = "203.0.113.1"
    proxied = true
  }

  default_tunnel_name = "default-tunnel"

  dns_records = [
    {
      name    = "www"
      type    = "CNAME"
      content = "example.com"
      proxied = true
    },
    {
      name    = "blog"
      type    = "CNAME"
      content = "example.com"
      proxied = true
    }
  ]
}
