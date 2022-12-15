variable "dns_records" {
  description = "Value of proxied DNS records"
  type = list(object({
    name       = string
    type       = string
    value      = string
    protected  = bool
    proxied    = bool
    local-ip   = string
    local-port = string
    protocol   = string
    allowed_emails = list(string)
  }))
  default = [{ "name" : "", "type" : "", "value" : "", "protected" : false, "proxied" : true, "local-ip": "", "local-port" : "", "protocol" : "", "allowed_emails": [""] }]
}

variable "cloudflare_api_token" {
  description = "API token for cloudflare"
  type        = string
  default     = ""
  sensitive = true
}

variable "tunnel_secret" {
  description = "API token for cloudflare"
  type        = string
  default     = ""
  sensitive = true
  validation {
    condition     = length(var.tunnel_secret) == 184
    error_message = "You must use a 184 length secret"
  }
}

variable "domain" {
  description = "Domain that you want to modify"
  type = object({
    name   = string
    target = string
  })
  default = {
    name   = ""
    target = ""
  }
}

variable "allowed_emails" {
  description = "A list of e-mailaddresses that can login via Cloudflare Access"
  type        = list(string)
  default     = [""]
}

variable "default_ttl" {
  description = "Default TTL"
  type        = number
  default     = 3600
}