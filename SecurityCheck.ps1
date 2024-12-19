# Author: Greg Lawler (greg@outsideopen.com)
# Date: 2024-12-05
#
# This script performs a comprehensive security check of the system. It generates a report with details on:
# - Installed remote access tools
# - Active network connections
# - DNS cache entries
# - Auto-start programs in Run and RunOnce registry keys
# - Scheduled tasks
# - Local user accounts
# - ScreenConnect processes
# - Running processes
# - Running services
#
# Instructions:
# 1. Save this script as `SecurityCheck.ps1` in your desired location.
# 2. Configure the `$outputDirectory` variable to set the location of the log file.

# Define the output file directory and file name
$outputDirectory = "C:\kworking"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outputFile = Join-Path -Path $outputDirectory -ChildPath "SecurityReport-$timestamp.txt"

# Ensure the output directory exists
if (-not (Test-Path -Path $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory -Force
}

# Helper function to append text to the report
function Append-Report {
    param (
        [string]$Text
    )
    $Text | Out-File -FilePath $outputFile -Append
}

# Start the report
"Security Check Report" | Out-File -FilePath $outputFile
"Paste this output into ChatGPT or any AI for security analysis of possible threats and remote access tools." | Out-File -FilePath $outputFile -Append
"Generated on: $(Get-Date)" | Out-File -FilePath $outputFile -Append
"==========================================" | Out-File -FilePath $outputFile -Append

# Check installed remote access tools
Append-Report "`nChecking for installed remote access tools..."
$remoteTools = @(
    "*TeamViewer*",
    "*AnyDesk*",
    "*UltraVNC*",
    "*LogMeIn*",
    "*GoToMyPC*",
    "*Chrome Remote Desktop*",
    "*Splashtop*",
    "*Radmin*",
    "*ConnectWise Control*",
    "*Kaseya*",
    "*ScreenConnect*"
)
foreach ($tool in $remoteTools) {
    $installed = @(
        Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* 2>$null |
        Where-Object { $_.DisplayName -like $tool }
        Get-ItemProperty HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* 2>$null |
        Where-Object { $_.DisplayName -like $tool }
    )
    if ($installed) {
        foreach ($item in $installed) {
            Append-Report "  Found: $($item.DisplayName)"
        }
    } else {
        Append-Report "  $tool not found."
    }
}

# Check for ScreenConnect processes
Append-Report "`nChecking for ScreenConnect processes..."
try {
    $screenConnectProcesses = Get-Process | Where-Object { $_.Name -like "*ScreenConnect*" }
    if ($screenConnectProcesses) {
        foreach ($proc in $screenConnectProcesses) {
            Append-Report "  ScreenConnect Process Found: Name: $($proc.Name), ID: $($proc.Id), Path: $($proc.Path)"
        }
    } else {
        Append-Report "  No ScreenConnect processes found."
    }
} catch {
    Append-Report "  Failed to check for ScreenConnect processes: $($_.Exception.Message)"
}

# Check active network connections
Append-Report "`nChecking active network connections..."
try {
    $netstat = netstat -ano | Select-String "TCP" | Select-String "ESTABLISHED"
    if ($netstat) {
        Append-Report "  Active connections:"
        $netstat | ForEach-Object { Append-Report "    $_" }
    } else {
        Append-Report "  No active connections found."
    }
} catch {
    Append-Report "  Failed to check network connections: $($_.Exception.Message)"
}

# Check DNS cache
Append-Report "`nChecking DNS cache..."
try {
    $dnsCache = ipconfig /displaydns
    if ($dnsCache) {
        Append-Report "  DNS cache entries:"
        $dnsCache | ForEach-Object { Append-Report "    $_" }
    } else {
        Append-Report "  No DNS cache found."
    }
} catch {
    Append-Report "  Failed to check DNS cache: $($_.Exception.Message)"
}

# Check Run and RunOnce registry keys
Append-Report "`nChecking Run and RunOnce registry keys..."
$regKeys = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
)
foreach ($key in $regKeys) {
    Append-Report "`nChecking $key..."
    try {
        $values = Get-ItemProperty -Path $key -ErrorAction Stop
        if ($values.PSObject.Properties.Name -ne "PSPath") {
            $values.PSObject.Properties | ForEach-Object {
                Append-Report "  $($_.Name): $($_.Value)"
            }
        } else {
            Append-Report "  No entries found in $key."
        }
    } catch {
        Append-Report "  Failed to access ${key}: $($_.Exception.Message)"
    }
}

# Check for suspicious scheduled tasks
Append-Report "`nChecking scheduled tasks..."
try {
    $tasks = Get-ScheduledTask | Where-Object { $_.TaskPath -notlike "\Microsoft\*" }
    if ($tasks) {
        Append-Report "  Suspicious scheduled tasks:"
        $tasks | ForEach-Object {
            Append-Report "    Task Name: $($_.TaskName)"
            Append-Report "    Task Path: $($_.TaskPath)"
        }
    } else {
        Append-Report "  No suspicious tasks found."
    }
} catch {
    Append-Report "  Failed to check scheduled tasks: $($_.Exception.Message)"
}

# Check for all running processes
Append-Report "`nChecking all running processes..."
try {
    $processes = Get-Process
    foreach ($proc in $processes) {
        Append-Report "  Process: $($proc.Name), ID: $($proc.Id), Path: $($proc.Path)"
    }
} catch {
    Append-Report "  Failed to check running processes: $($_.Exception.Message)"
}

# Check for all running services
Append-Report "`nChecking all running services..."
try {
    $services = Get-Service
    foreach ($svc in $services) {
        Append-Report "  Service: $($svc.Name), Status: $($svc.Status), StartType: $($svc.StartType)"
    }
} catch {
    Append-Report "  Failed to check services: $($_.Exception.Message)"
}

# End the report
Append-Report "`nSecurity check completed."
Append-Report "=========================================="
Write-Host "Security check completed. Report saved to $outputFile"
Write-Host "Upload this report to ChatGPT 4 or newer and ask for a summary vulnerability analysis" -ForegroundColor Yellow

