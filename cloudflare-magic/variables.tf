/**
 * Input variables for the Cloudflare Magic module
 */

variable "cloudflare_api_token" {
  description = "Cloudflare API token with sufficient permissions to manage DNS, Access, and Tunnels"
  type        = string
  sensitive   = true
}

variable "domain" {
  description = "Domain configuration including name, target IP, and proxy settings"
  type = object({
    name    = string
    target  = string
    proxied = optional(bool)
  })
}

variable "dns_records" {
  description = <<-EOT
    List of DNS records to manage. Each record can be either a public DNS record or a Zero Trust protected application.
    For Zero Trust applications, you can specify tunnel configuration and access controls.
    
    Example:
    ```hcl
    dns_records = [
      {
        name = "www"
        type = "CNAME"
        content = "example.com"
      },
      {
        name = "admin"
        zero_trust = {
          protected = true
          allowed_emails = ["admin@example.com"]
          tunnel = {
            name = "admin-tunnel"  # Name of the tunnel to use (will be created if it doesn't exist)
            local_protocol = "https"
            local_port = "8080"
          }
        }
      }
    ]
    ```
  EOT
  type = list(object({
    name    = string
    type    = optional(string)
    content = optional(string) # Updated from deprecated 'value'
    proxied = optional(bool)
    ttl     = optional(number)
    zero_trust = optional(object({
      protected        = optional(bool)
      app_type         = optional(string)
      allowed_idps     = optional(list(string))
      allowed_emails   = optional(list(string))
      session_duration = optional(string)
      tunnel = optional(object({
        name           = optional(string)
        local_ip       = optional(string)
        local_port     = optional(string)
        local_protocol = optional(string)
      }))
    }))
  }))
  default = []
}

variable "default_tunnel_name" {
  description = "Default tunnel name used when no specific tunnel is specified for a Zero Trust application"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.default_tunnel_name)) && length(var.default_tunnel_name) <= 36
    error_message = "Tunnel name must start and end with alphanumeric characters, can contain hyphens in the middle, and be 36 characters or less."
  }
}

variable "default_session_duration" {
  description = "Default session duration for Zero Trust applications (e.g., '24h')"
  type        = string
  default     = "24h"

  validation {
    condition     = can(regex("^[0-9]+[smhd]$", var.default_session_duration))
    error_message = "Session duration must be in format like '1h', '30m', '24h', etc."
  }
}

variable "default_allowed_idps" {
  description = "Default list of allowed identity providers for Zero Trust applications"
  type        = list(string)
  default     = []
}

variable "default_allowed_emails" {
  description = "Default list of allowed email addresses for Zero Trust applications"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for email in var.default_allowed_emails : can(regex("^[^@]+@[^@]+\\.[^@]+$", email))
    ])
    error_message = "All emails must be valid email addresses."
  }
}

variable "default_ttl" {
  description = "Default TTL (Time To Live) for DNS records in seconds"
  type        = number
  default     = 3600
}

variable "tunnel_no_tls_verify" {
  description = "Whether to disable TLS verification for tunnel connections"
  type        = bool
  default     = true
}

variable "tunnel_catch_all_service" {
  description = "Service to use for tunnel catch-all rule (e.g., 'http_status:404')"
  type        = string
  default     = "http_status:404"
}