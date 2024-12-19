<#
.AUTHOR
Greg Lawler / Outside Open - 2022
https://outsideopen.com/

.SYNOPSIS
This script backs up the PowerShell command history for all users, appending a unique timestamp to ensure uniqueness.

.DESCRIPTION
Automates the backup of the PowerShell command history from the ConsoleHost_history.txt file located in each user's profile directory. Each user's backup is timestamped and stored in a designated directory, facilitating a comprehensive audit trail of PowerShell usage across the system.

.PREREQUISITES - IMPORTANT
- Execution Policy must be set to RemoteSigned to allow this script to run. This is required once per target computer:
  Set-ExecutionPolicy RemoteSigned
- Administrative privileges are required to access all users' profile directories.

.WARRANTY
- This script is provided "as is" with no warranties implied.
- Users are advised to thoroughly review and test the script in a controlled environment before deployment in production settings.
- Ensure adherence to privacy policies and security guidelines when accessing and backing up user-specific data.

.EXAMPLE
Navigate to the script's directory in an administrative PowerShell session and enter:
.\PSHistoryBackupAllUsers.ps1

#>

# Configurable Options
$allUsersProfilePath = "C:\Users"
$backupFolderPath = "C:\ISSO\Audits\Logs\PSHistoryBackups" # Destination folder for backups
$currentDate = Get-Date -Format "yyyy-MM-dd-HHmmss"

# Ensure the backup folder exists
if (!(Test-Path -Path $backupFolderPath)) {
    New-Item -Path $backupFolderPath -ItemType Directory | Out-Null
    Write-Host "Created backup folder: $backupFolderPath"
}

# Backup PowerShell command history for all users
Get-ChildItem -Path $allUsersProfilePath -Directory | ForEach-Object {
    $userName = $_.Name
    $historyFilePath = Join-Path -Path $_.FullName -ChildPath "AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt"
    
    if (Test-Path -Path $historyFilePath) {
        $backupFileName = "$userName-$currentDate.txt"
        $backupFilePath = Join-Path -Path $backupFolderPath -ChildPath $backupFileName
        Copy-Item -Path $historyFilePath -Destination $backupFilePath
        Write-Host "Backed up PowerShell history for $userName to $backupFilePath" -ForegroundColor Green
    } else {
        Write-Host "No PowerShell history found for $userName" -ForegroundColor Yellow
    }
}

Write-Host "Script execution completed. PowerShell command history for all users has been backed up." -ForegroundColor Green

