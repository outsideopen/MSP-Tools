<#
.AUTHOR
Outside Open - 2022
https://outsideopen.com/

.SYNOPSIS
Disables the built-in Administrator account and remove local admin from all users except the defined excludedUserName user.

.DESCRIPTION
This PowerShell script disables the built-in Administrator account, removes all other users from the Administrators group except for a specified user, and logs actions. It verifies that the excluded user exists and is an administrator before proceeding.

.PREREQUISITES
- Execution Policy must be set to RemoteSigned.
- Requires administrative privileges.

.WARRANTY
Provided "as is", with no warranties implied. Review and test in a non-production environment before deployment.

.EXAMPLE
Run the script in an administrative PowerShell session:
.\LocalAdminCleanup.ps1

#>

# Configuration
$excludedUserName = "JohnSmith" # Username to retain administrative privileges. Adjust as needed.
$logPath = "C:\ISSO\Audits\Logs"
$logFileName = "Admin-Rights-Log-" + (Get-Date -Format "yyyy-MM-dd-HHmmss") + ".txt"
$logFile = Join-Path -Path $logPath -ChildPath $logFileName

# Ensure the log directory exists
if (-not (Test-Path -Path $logPath)) {
    New-Item -Path $logPath -ItemType Directory | Out-Null
}

# Function to log messages and display in color
function Log-Message {
    param (
        [string]$Message,
        [string]$Color = "White" # Default color
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $Message"
    $logMessage | Out-File -FilePath $logFile -Append
    Write-Host $Message -ForegroundColor $Color
}

# Verify the excluded account exists
$excludedUser = Get-LocalUser -Name $excludedUserName -ErrorAction SilentlyContinue
if (-not $excludedUser) {
    Log-Message "The specified account to exclude ($excludedUserName) does not exist." "Red"
    exit
}

# Check if the excluded account is an administrator by comparing SIDs
$isAdmin = $false
$adminMembers = Get-LocalGroupMember -Group "Administrators"
foreach ($member in $adminMembers) {
    if ($member.Sid -eq $excludedUser.Sid) {
        $isAdmin = $true
        break
    }
}

if (-not $isAdmin) {
    Log-Message "The specified account to exclude ($excludedUserName) is not an administrator." "Red"
    exit
}

# Always disable the built-in Administrator account
try {
    $adminAccount = Get-LocalUser -Name "Administrator"
    if ($adminAccount.Enabled) {
        Disable-LocalUser -Name "Administrator"
        Log-Message "The built-in Administrator account has been disabled." "Green"
    } else {
        Log-Message "The built-in Administrator account is already disabled." "Yellow"
    }
} catch {
    Log-Message "Failed to disable the built-in Administrator account: $_" "Red"
}

# Adjust membership of the Administrators group
$adminGroup = Get-LocalGroup -Name "Administrators"
$adminMembers = Get-LocalGroupMember -Group $adminGroup.Name

foreach ($member in $adminMembers) {
    if ($member.Sid -ne $excludedUser.Sid -and $member.Name -ne "Administrator") {
        try {
            Remove-LocalGroupMember -Group $adminGroup.Name -Member $member.Name -ErrorAction Stop
            Log-Message "Removed $($member.Name) from the Administrators group." "Green"
        } catch {
            Log-Message "Failed to remove $($member.Name) from the Administrators group: $_" "Yellow"
        }
    }
}

Log-Message "Script execution completed. Specified adjustments have been made to the Administrators group." "Green"

