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

# modules/backup/main.tf
resource "routeros_system_scheduler" "backup" {
  name       = "daily-backup"
  start_time = "03:00:00"
  interval   = var.backup_interval
  on_event   = var.backup_password != null ? "/system backup save name=${var.backup_name}-$([:pick [/system clock get date] 0 3])-$([:pick [/system clock get date] 4 6])-$([:pick [/system clock get date] 7 11]) password=${var.backup_password}" : "/system backup save name=${var.backup_name}-$([:pick [/system clock get date] 0 3])-$([:pick [/system clock get date] 4 6])-$([:pick [/system clock get date] 7 11])"
  comment    = "Automated daily backup"
}

# FTP export script if needed
resource "routeros_system_script" "export_backup" {
  count   = var.backup_password != null ? 1 : 0
  name    = "export-backup-to-ftp"
  source  = <<-EOT
    # Script to export the latest backup to FTP server
    # Remember to set up FTP credentials separately for security
    :local backupFiles [/file find name~"^${var.backup_name}-"];
    :if ([:len $backupFiles] > 0) do={
      :local latestFile [:tostr [/file get [:pick $backupFiles ([:len $backupFiles] - 1)] name]];
      # Uncomment and edit next line to enable FTP export
      # /tool fetch address=ftp.example.com src-path=$latestFile user=ftpuser password=ftpsecret dst-path=$latestFile upload=yes
    }
  EOT
  comment = "Export the latest backup to FTP server"
}

# modules/backup/outputs.tf
output "backup_schedule" {
  description = "Backup schedule interval"
  value       = routeros_system_scheduler.backup.interval
}

output "backup_name_pattern" {
  description = "Pattern of backup filenames"
  value       = "${var.backup_name}-MMM-DD-YYYY"
}