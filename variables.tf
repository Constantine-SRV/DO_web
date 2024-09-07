variable "do_token" {
  type        = string
  description = "DigitalOcean API Token"
}

variable "spaces_access_key" {
  type        = string
  description = "Access Key for DigitalOcean Spaces"
  default     = ""
}

variable "spaces_secret_key" {
  type        = string
  description = "Secret Key for DigitalOcean Spaces"
  default     = ""
}

variable "db_password" {
  description = "The password for the PostgreSQL database"
  type        = string
  sensitive   = true
}

variable "hetzner_dns_key" {
  description = "The API key for Hetzner DNS"
  type        = string
  sensitive   = true
}
#ARM_ACCESS_KEY
variable "arm_access_key" {
  type        = string
  description = "az storage key"
  default     = ""
}