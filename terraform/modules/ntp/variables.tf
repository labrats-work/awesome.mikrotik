# modules/ntp/variables.tf
variable "ntp_servers" {
  type        = list(string)
  description = "List of NTP server addresses"
  default     = ["pool.ntp.org", "time.google.com"]
}

variable "timezone" {
  type        = string
  description = "System timezone"
  default     = "UTC"
}