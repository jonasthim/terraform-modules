<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | ~> 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [cloudflare_access_application.cf_app](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_application) | resource |
| [cloudflare_access_policy.policy](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_policy) | resource |
| [cloudflare_argo_tunnel.default](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/argo_tunnel) | resource |
| [cloudflare_record.dns](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record) | resource |
| [cloudflare_record.dns-tunnel](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record) | resource |
| [cloudflare_record.domain](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record) | resource |
| [cloudflare_tunnel_config.tunnel](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/tunnel_config) | resource |
| [cloudflare_zone.domain](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/data-sources/zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allow_dns_overwrite"></a> [allow\_dns\_overwrite](#input\_allow\_dns\_overwrite) | Allows overwrite of DNS | `bool` | `false` | no |
| <a name="input_cloudflare_api_token"></a> [cloudflare\_api\_token](#input\_cloudflare\_api\_token) | API token for cloudflare | `string` | `null` | no |
| <a name="input_default_allowed_emails"></a> [default\_allowed\_emails](#input\_default\_allowed\_emails) | Unless you specify dns\_record.zero\_trust.allowed\_mails in each `dns_record` this will be used as the default email list | `list(string)` | `null` | no |
| <a name="input_default_allowed_idps"></a> [default\_allowed\_idps](#input\_default\_allowed\_idps) | Unless you specify allowed\_ips in each `dns_record.zero_trust` this will be used as the default IDPs list | `list(string)` | `null` | no |
| <a name="input_default_ttl"></a> [default\_ttl](#input\_default\_ttl) | Default TTL | `number` | `3600` | no |
| <a name="input_default_tunnel_name"></a> [default\_tunnel\_name](#input\_default\_tunnel\_name) | Unless you specify dns\_record.zero\_trust.tunnel.name in each `dns_record.zero_trust` this will be used as the default tunnel name | `string` | `null` | no |
| <a name="input_dns_records"></a> [dns\_records](#input\_dns\_records) | Value of proxied DNS records | <pre>list(object({<br>    name       = string<br>    type       = optional(string)<br>    value      = optional(string)<br>    proxied    = optional(bool)<br>    ttl        = optional(number)<br>    zero_trust = optional(object({<br>      protected = optional(bool)<br>      allowed_idps = optional(list(string))<br>      allowed_emails = optional(list(string))<br>      tunnel = optional(object({<br>        name = optional(string)<br>        local-ip = optional(string)<br>        local-port = optional(string)<br>        local-protocol = optional(string)<br>      }))<br>    }))<br>  }))</pre> | <pre>[<br>  {<br>    "name": null,<br>    "proxied": true,<br>    "ttl": null,<br>    "type": null,<br>    "value": null,<br>    "zero_trust": {<br>      "allowed_emails": null,<br>      "allowed_idps": null,<br>      "protected": null,<br>      "tunnel": {<br>        "local-ip": null,<br>        "local-port": null,<br>        "local-protcol": null,<br>        "name": null<br>      }<br>    }<br>  }<br>]</pre> | no |
| <a name="input_domain"></a> [domain](#input\_domain) | Domain that you want to modify | <pre>object({<br>    name   = string<br>    target = optional(string)<br>    proxied = optional(bool)<br>    ttl = optional(number)<br>  })</pre> | `null` | no |
| <a name="input_tunnel_secret"></a> [tunnel\_secret](#input\_tunnel\_secret) | API token for cloudflare | `string` | `null` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->