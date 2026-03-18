# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Monorepo of reusable Terraform modules. Currently contains one module:

- **cloudflare-magic** — Manages Cloudflare DNS records, Zero Trust applications, and Cloudflare Tunnels. Supports public DNS records and Zero Trust-protected services with automatic tunnel creation, ingress rule configuration, and access policy optimization (shared policies for identical configs).

## Commands

```sh
# Validate a module
cd cloudflare-magic && terraform init && terraform validate

# Format all Terraform files
terraform fmt -recursive

# Plan (requires CLOUDFLARE_API_TOKEN or var file)
cd cloudflare-magic && terraform plan

# Run Go tests (Terratest)
cd cloudflare-magic/test && go test -v -timeout 30m
```

## Architecture — cloudflare-magic

The module uses a single `dns_records` list variable that drives all resource creation. Records are split into two paths:

1. **Public records** (`zero_trust == null`) → `cloudflare_dns_record.public`
2. **Zero Trust records** (`zero_trust != null`) → tunnel creation, tunnel config, CNAME to tunnel, access application, and access policy

Key data flow in `main.tf`:
- `tunnel_name_map` resolves each ZT record to a tunnel name (explicit or `default_tunnel_name`)
- `tunnel_names` deduplicates tunnel names; `tunnel_ingress_rules` groups records per tunnel
- `access_policy_configs` → `policy_groups` → `unique_policies` optimizes access policies by grouping identical configurations
- Tunnels get `random_id` secrets, then `cloudflare_zero_trust_tunnel_cloudflared` + `cloudflare_zero_trust_tunnel_cloudflared_config` with ingress list
- Access policies are standalone resources (`cloudflare_zero_trust_access_policy`) linked to applications via the `policies` attribute on `cloudflare_zero_trust_access_application`

Provider: `cloudflare/cloudflare ~> 5.0`, also uses `hashicorp/random ~> 3.5`.

## Conventions

- Each module lives in its own top-level directory with `main.tf`, `variables.tf`, `outputs.tf`
- Examples go in `<module>/examples/<scenario>/`
- Tests use Go/Terratest in `<module>/test/`
- Module README is auto-generated between `<!-- BEGIN_TF_DOCS -->` / `<!-- END_TF_DOCS -->` markers
