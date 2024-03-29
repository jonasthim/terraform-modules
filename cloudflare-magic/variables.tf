variable "default_allowed_idps" {
  description = "Unless you specify allowed_ips in each `dns_record.zero_trust` this will be used as the default IDPs list"
  type        = list(string)
  # validation {
  #   condition = contains([regex("^[0-9a-fA-F]{8}\\b-[0-9a-fA-F]{4}\\b-[0-9a-fA-F]{4}\\b-[0-9a-fA-F]{4}\\b-[0-9a-fA-F]{12}$", var.default_allowed_idps)], var.default_allowed_idps)
  #   error_message = "Misconfigured IDPs (Should be a UUID)"
  # }
}

variable "default_allowed_emails" {
  description = "Unless you specify dns_record.zero_trust.allowed_mails in each `dns_record` this will be used as the default email list"
  type        = list(string)
  # validation {
  #   condition = contains([regex("^\\w+([\\.-]?\\w+)*@\\w+([\\.-]?\\w+)*(\\.\\w{2,3})+$", var.default_allowed_emails)], var.default_allowed_emails)
  #   error_message = "Misconfigured e-mailaddresses!)"
  # }
}

variable "default_tunnel_name" {
  description = "Unless you specify dns_record.zero_trust.tunnel.name in each `dns_record.zero_trust` this will be used as the default tunnel name"
  type        = string
}

variable "default_session_duration" {
  description = "How often a user will be forced to re-authorise. Must be in the format 48h or 2h45m."
  type        = string
}

variable "dns_records" {
  description = "Value of proxied DNS records"
  type = list(object({
    name    = string
    type    = optional(string)
    value   = optional(string)
    proxied = optional(bool)
    ttl     = optional(number)
    zero_trust = optional(object({
      protected      = optional(bool)
      app_type       = optional(string)
      allowed_idps   = optional(list(string))
      allowed_emails = optional(list(string))
      session_duration = optional(string)
      tunnel = optional(object({
        name           = optional(string)
        local-ip       = optional(string)
        local-port     = optional(string)
        local-protocol = optional(string)
      }))
    }))
  }))

}

variable "cloudflare_api_token" {
  description = "API token for cloudflare"
  type        = string
  sensitive   = true
}

variable "tunnel_secret" {
  description = "API token for cloudflare"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.tunnel_secret) == 184
    error_message = "You must use a 184 length secret"
  }
}

variable "domain" {
  description = "Domain that you want to modify"
  type = object({
    name    = string
    target  = optional(string)
    proxied = optional(bool)
    ttl     = optional(number)
  })
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