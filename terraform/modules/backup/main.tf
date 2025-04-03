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
