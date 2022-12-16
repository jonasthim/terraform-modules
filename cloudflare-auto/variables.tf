variable "default_allowed_idps" {
  description = "Unless you specify allowed_ips in each `dns_record.zero_trust` this will be used as the default IDPs list"
  type = string
  validation {
    condition = can(regex("^[0-9a-fA-F]{8}\\b-[0-9a-fA-F]{4}\\b-[0-9a-fA-F]{4}\\b-[0-9a-fA-F]{4}\\b-[0-9a-fA-F]{12}$", var.default_allowed_idps))
    error_message = "Misconfigured IDPs (Should be a UUID)"
  }
  default = null
}

variable "default_allowed_emails" {
  description = "Unless you specify dns_record.zero_trust.allowed_mails in each `dns_record` this will be used as the default email list"
  type = string
  validation {
    condition = can(regex("^\\w+([\\.-]?\\w+)*@\\w+([\\.-]?\\w+)*(\\.\\w{2,3})+$", var.default_allowed_emails))
    error_message = "Misconfigured e-mailaddresses!)"
  }
  default = null
}

variable "default_tunnel_name" {
  description = "Unless you specify dns_record.zero_trust.tunnel.name in each `dns_record.zero_trust` this will be used as the default tunnel name"
  type = string
  default = null
}

variable "dns_records" {
  description = "Value of proxied DNS records"
  type = object({
    name       = required(string)
    type       = optional(string)
    value      = optional(string)
    proxied    = optional(bool)
    zero_trust = optional(object({
      protected = bool
      allowed_idps = optional(list(string))
      allowed_emails = optional(list(string))
      tunnel = optional(object({
        name = optional(string)
        local-ip = optional(string)
        local-port = optional(string)
        local-protocol = optional(string)
      }))
    }))
  })

  default = {
    name = null
    type = null
    value = null
    proxied = true
    zero_trust = null
  }
}

variable "cloudflare_api_token" {
  description = "API token for cloudflare"
  type        = string
  default = null
  sensitive = true
}

variable "tunnel_secret" {
  description = "API token for cloudflare"
  type        = string
  default = null
  sensitive = true
  validation {
    condition     = length(var.tunnel_secret) == 184
    error_message = "You must use a 184 length secret"
  }
}

variable "domain" {
  description = "Domain that you want to modify"
  type = object({
    name   = required(string)
    target = optional(string)
    proxied = bool
    ttl = number
  })
  default = null
}

variable "default_ttl" {
  description = "Default TTL"
  type        = number
  default     = 3600
}

variable "allow_dns_overwrite" {
  description = "Allows overwrite of DNS"
  type        = bool
  default     = false
}