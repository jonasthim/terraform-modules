<!-- BEGIN_TF_DOCS -->
# Cloudflare Magic Terraform Module

This Terraform module manages Cloudflare resources including DNS records, Zero Trust applications, and Cloudflare Tunnels. It provides complete management of your Cloudflare infrastructure using Terraform.

## Module Source

```hcl
module "cloudflare_magic" {
  source = "github.com/thim/terraform-modules//cloudflare-magic"
  # version = "~> 1.0"  # Recommended: pin to a specific version
  
  # Your configuration here...
}
```

For production use, it's recommended to pin to a specific version or tag:

```hcl
module "cloudflare_magic" {
  source = "github.com/thim/terraform-modules//cloudflare-magic?ref=v1.0.0"
  
  # Your configuration here...
}
```

## Features

- 🔒 Zero Trust Application management
- 🚇 Automated tunnel creation and configuration
- 🌐 DNS record management (both public and tunnel-protected)
- 🔑 Access policy configuration
- 🔄 Multiple tunnel support with flexible routing

## Prerequisites

1. Install cloudflared (needed only for running tunnels):
```zsh
brew install cloudflare/cloudflare/cloudflared
```

2. Log in to Cloudflare:
```zsh
cloudflared tunnel login
```

## Usage

```hcl
module "cloudflare_magic" {
  source = "github.com/thim/terraform-modules//cloudflare-magic"

  cloudflare_api_token = var.cloudflare_api_token
  
  domain = {
    name    = "example.com"
    target  = "203.0.113.1"
    proxied = true
  }

  # All tunnels will be automatically created and configured
  dns_records = [
    # Public DNS record
    {
      name    = "www"
      type    = "CNAME"
      content = "example.com"
      proxied = true
    },
    
    # Zero Trust protected applications using the same tunnel
    {
      name = "app"
      zero_trust = {
        protected = true
        allowed_emails = ["user@example.com"]
        tunnel = {
          name = "prod-tunnel"  # This tunnel will be created automatically
          local_protocol = "http"
          local_port     = "3000"
        }
      }
    },
    {
      name = "api"
      zero_trust = {
        protected = true
        allowed_emails = ["user@example.com"]
        tunnel = {
          name = "prod-tunnel"  # Reuse the same tunnel
          local_protocol = "http"
          local_port     = "8080"
        }
      }
    }
  ]

  default_allowed_emails = ["user@example.com"]
  default_session_duration = "24h"
}
```

## How It Works

1. **Tunnel Creation**: The module automatically creates all required tunnels
2. **Tunnel Configuration**: Ingress rules are configured based on your DNS records
3. **DNS Setup**: CNAME records are created to point to your tunnels
4. **Access Control**: Zero Trust applications and policies are configured

## Running Your Tunnels

After Terraform has created and configured your tunnels, you can run them:

```zsh
# Run a specific tunnel
cloudflared tunnel run prod-tunnel

# Or run multiple tunnels in different terminals
cloudflared tunnel run prod-tunnel
cloudflared tunnel run staging-tunnel
```

## DNS Record Configuration

Each DNS record in the `dns_records` list can have the following attributes:

```hcl
{
  name    = string
  type    = optional(string)
  content = optional(string)  # Updated from deprecated 'value'
  proxied = optional(bool)
  ttl     = optional(number)
  zero_trust = optional(object({
    protected        = optional(bool)
    app_type        = optional(string)
    allowed_idps    = optional(list(string))
    allowed_emails  = optional(list(string))
    session_duration = optional(string)
    tunnel = optional(object({
      name           = optional(string)  # Name of the tunnel to create/use
      local_ip       = optional(string)  # Defaults to record name
      local_port     = optional(string)  # Defaults to "80"
      local_protocol = optional(string)  # Defaults to "http"
    }))
  }))
}
```

## Examples

### Multiple Applications, One Tunnel

```hcl
dns_records = [
  {
    name = "app"
    zero_trust = {
      protected = true
      tunnel = {
        name = "prod-tunnel"
        local_port = "3000"
      }
    }
  },
  {
    name = "api"
    zero_trust = {
      protected = true
      tunnel = {
        name = "prod-tunnel"  # Reuse the same tunnel
        local_port = "8080"
      }
    }
  }
]
```

### Multiple Environments

```hcl
dns_records = [
  {
    name = "app"
    zero_trust = {
      protected = true
      tunnel = {
        name = "prod-tunnel"
        local_port = "3000"
      }
    }
  },
  {
    name = "app-staging"
    zero_trust = {
      protected = true
      tunnel = {
        name = "staging-tunnel"  # Separate tunnel for staging
        local_port = "3000"
      }
    }
  }
]
```

## Notes

- Ensure your Cloudflare API token has sufficient permissions
- All tunnel configuration is handled by Terraform
- You only need cloudflared CLI for running the tunnels
- Changes to tunnel configuration are applied through your normal Terraform workflow
- The module automatically generates secure random secrets for new tunnels

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
<!-- END_TF_DOCS -->