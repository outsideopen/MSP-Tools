<#
.AUTHOR
Greg Lawler - Outside Open - 2019
https://outsideopen.com/

.SYNOPSIS
This script backs up and clears specified Windows event logs, managing backups by retaining a specified number of recent backup files.

.DESCRIPTION
This PowerShell script automates the backup and clearance of "Application", "System", and "Security" Windows event logs. It stores backups in a designated directory and maintains only a specified number of the most recent backups, deleting older ones to manage storage efficiently.

.PREREQUISITES - IMPORTANT
- Execution Policy must be set to RemoteSigned to allow this script to run. This is only required per target computer:
  Set-ExecutionPolicy RemoteSigned

.WARRANTY
- This script is provided "as is" with no warranties implied. 
- Users are advised to thoroughly review and test the script in a controlled environment before deployment in production
- As always, audit free scripts to remain vigilant against supply chain attacks.

.EXAMPLE
Navigate to the script's directory in an administrative PowerShell session and enter:
.\EventLogRotation.ps1

.PARAMETER HelpParam
Outputs usage instructions when provided with `/?`.

.CONFIGURATION
- $backupFolderPath: Specifies the path where backup files are stored.
- $filesToKeep: Specifies the number of recent backup files to retain.

#>
param (
    [string]$HelpParam
)

# Configurable Options
$backupFolderPath = "C:\ISSO\Audits\Logs" # Destination folder for backups
$filesToKeep = 365 # Number of backup files to keep

if ($HelpParam -eq "/?") {
    Write-Host "Usage: .\EventLogRotation.ps1" -ForegroundColor Green
    Write-Host "Backs up and clears specified Windows event logs, retaining a specified number of recent backups." -ForegroundColor Green
    Write-Host "Configure the destination folder and number of backups to retain within the script." -ForegroundColor Green
    Write-Host "Requires administrative privileges and the execution policy set to RemoteSigned." -ForegroundColor Yellow
    exit
}

$currentDate = Get-Date
$timestamp = Get-Date -Format "HHmmss"
$backupPath = Join-Path -Path $backupFolderPath -ChildPath $currentDate.ToString("yyyy-MM-dd")
$logNames = @("Application", "System", "Security")

# Create backup directory if it doesn't exist
if (!(Test-Path -Path $backupPath)) {
    New-Item -Path $backupPath -ItemType Directory | Out-Null
}

# Backup event logs and clear them
foreach ($logName in $logNames) {
    $exportFileName = "$logName-$($currentDate.ToString("yyyy-MM-dd"))-$timestamp.evtx"
    $exportFilePath = Join-Path -Path $backupPath -ChildPath $exportFileName

    # Export the log
    Write-Host "Exporting $logName log to $exportFilePath"
    wevtutil epl $logName $exportFilePath

    # Clear the log
    Write-Host "Clearing $logName event log"
    wevtutil cl $logName
}

# Maintain only the specified number of recent backup files
$backedUpFiles = Get-ChildItem -Path $backupFolderPath -File | Sort-Object CreationTime -Descending | Select-Object -Skip $filesToKeep
foreach ($file in $backedUpFiles) {
    Remove-Item $file.FullName -Force
}

Write-Host "Script execution completed. Event logs have been backed up and cleared, with only the most recent $filesToKeep backups retained." -ForegroundColor Green

