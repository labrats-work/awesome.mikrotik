# modules/backup/variables.tf
variable "backup_name" {
  type        = string
  description = "Name prefix for backup files"
  default     = "router-config"
}

variable "backup_password" {
  type        = string
  description = "Password to encrypt backup files"
  sensitive   = true
  default     = null
}

variable "backup_interval" {
  type        = string
  description = "Interval for scheduled backups (e.g., '1d 00:00:00')"
  default     = "1d 00:00:00"
}