# Backup Module

This module configures automated backups for RouterOS configuration.

## Features

- **Scheduled Backups**:
  - Configurable backup intervals
  - Automated execution

- **Backup Security**:
  - Optional password encryption
  - Secure storage

- **Export Options**:
  - Optional FTP export script
  - External storage integration

## Usage Examples

### Basic Configuration

```hcl
module "backup" {
  source      = "./modules/backup"
  backup_name = "router-config"
  backup_interval = "1d 00:00:00"  # Daily at midnight
}
```

### Encrypted Backups

```hcl
module "backup" {
  source          = "./modules/backup"
  backup_name     = "router-config-secure"
  backup_interval = "1d 00:00:00"
  backup_password = var.backup_encryption_password  # From a secure variable
}
```

### Custom Backup Schedule

```hcl
module "backup" {
  source          = "./modules/backup"
  backup_name     = "router-weekly"
  backup_interval = "7d 02:00:00"  # Weekly at 2 AM
}
```

## Required Inputs

No required inputs. All inputs have default values.

## Optional Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| backup_name | Name prefix for backup files | string | `"router-config"` |
| backup_password | Password to encrypt backup files | string | `null` |
| backup_interval | Interval for scheduled backups | string | `"1d 00:00:00"` |

## Outputs

| Name | Description |
|------|-------------|
| backup_schedule | Backup schedule interval |
| backup_name_pattern | Pattern of backup filenames |

## Backup Filename Format

Backups are automatically named according to the pattern:
```
<backup_name>-<month>-<day>-<year>
```

For example: `router-config-Jan-15-2025`

## FTP Export Script

When `backup_password` is provided, the module creates an export script that can be used to send backups to an external FTP server. The script needs to be manually edited to configure the FTP server details:

```
# Script to export the latest backup to FTP server
:local backupFiles [/file find name~"^${var.backup_name}-"];
:if ([:len $backupFiles] > 0) do={
  :local latestFile [:tostr [/file get [:pick $backupFiles ([:len $backupFiles] - 1)] name]];
  # Uncomment and edit next line to enable FTP export
  # /tool fetch address=ftp.example.com src-path=$latestFile user=ftpuser password=ftpsecret dst-path=$latestFile upload=yes
}
```

## Best Practices

1. **Regular Backups**: Schedule backups at least daily
2. **Password Protection**: Always encrypt backups when possible
3. **Off-Device Storage**: Export backups to an external server
4. **Backup Testing**: Regularly verify backup restoration process
5. **Backup Before Changes**: Create a manual backup before making significant changes
6. **Retention Policy**: Implement a policy for how many backups to retain