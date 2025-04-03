# modules/backup/outputs.tf
output "backup_schedule" {
  description = "Backup schedule interval"
  value       = routeros_system_scheduler.backup.interval
}

output "backup_name_pattern" {
  description = "Pattern of backup filenames"
  value       = "${var.backup_name}-MMM-DD-YYYY"
}
