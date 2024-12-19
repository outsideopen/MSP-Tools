<#
.AUTHOR
Greg Lawler, Outside Open - 2022
https://outsideopen.com/

.SYNOPSIS
Generate comprehensive user account information as well as login/logoff activity reports for local accounts, exporting to two CSV files.

.DESCRIPTION
Enumerates local user accounts capturing detailed information, and queries the Windows event logs for login and logoff events by human users, exporting this information to separate CSV files.

.PREREQUISITES
- Execution Policy set to RemoteSigned:
  `Set-ExecutionPolicy RemoteSigned`
- Requires administrative privileges.

.WARRANTY
- This script is provided "as is" with no warranties implied.
- Users are advised to thoroughly review and test the script in a controlled environment before deployment in production settings.
- Ensure adherence to privacy policies and security guidelines when accessing and backing up user-specific data.

#>

# Configurable Options
$reportFolderPath = "C:\ISSO\Audits\Logs\UserInfoReports"
$currentDate = Get-Date -Format "yyyy-MM-dd-HHmmss"

# User Info Report
$userInfoReportFileName = "ExtendedUserInfoReport-" + $currentDate + ".csv"
$userInfoReportFilePath = Join-Path -Path $reportFolderPath -ChildPath $userInfoReportFileName

# Login/Logoff Activity Report
$activityReportFileName = "LoginLogoffActivity-" + $currentDate + ".csv"
$activityReportFilePath = Join-Path -Path $reportFolderPath -ChildPath $activityReportFileName

# Ensure the report folder exists
if (!(Test-Path -Path $reportFolderPath)) {
    New-Item -Path $reportFolderPath -ItemType Directory | Out-Null
    Write-Host "Created report folder: $reportFolderPath"
}

# Function to check if a user is an admin
function Is-Admin($userName) {
    try {
        $adminGroup = Get-LocalGroup -Name "Administrators" -ErrorAction Stop
        $isAdmin = Get-LocalGroupMember -Group $adminGroup.Name -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $userName } | Measure-Object | ForEach-Object { $_.Count -gt 0 }
        return $isAdmin
    } catch {
        return $false
    }
}

# Generate extended user information report
$usersInfo = Get-LocalUser | ForEach-Object {
    $user = $_
    $isAdmin = Is-Admin $user.Name

    [PSCustomObject]@{
        UserName          = $user.Name
        LastLogin         = if ($null -ne $user.LastLogon) { $user.LastLogon.ToString("g") } else { "Never" }
        IsAdmin           = $isAdmin
        IsDisabled        = -not $user.Enabled
        PasswordLastSet   = if ($null -ne $user.PasswordLastSet) { $user.PasswordLastSet.ToString("g") } else { "Not Available" }
        AccountExpiration = if ($null -ne $user.AccountExpires -and $user.AccountExpires -ne [datetime]::MaxValue) { $user.AccountExpires.ToString("g") } else { "Never" }
        AccountCreation   = if ($null -ne $user.UserMayChangePassword) { $user.UserMayChangePassword.ToString() } else { "Not Available" }
        Description       = $user.Description
    }
} 

$usersInfo | Export-Csv -Path $userInfoReportFilePath -NoTypeInformation -Encoding UTF8
Write-Host "Extended user information report has been generated and saved to $userInfoReportFilePath" -ForegroundColor Green

# Capture and process login and logoff activity
$eventIDs = @(4624, 4634) # Logon and Logoff Event IDs
$events = Get-WinEvent -FilterHashtable @{LogName='Security'; ID=$eventIDs} -ErrorAction SilentlyContinue | Where-Object {$_.Properties[5].Value -notmatch '^(SYSTEM|LOCAL SERVICE|NETWORK SERVICE)$'}

$activityInfo = $events | ForEach-Object {
    $eventID = $_.Id
    $timestamp = $_.TimeCreated.ToString("g")
    $username = $_.Properties[5].Value

    [PSCustomObject]@{
        TimeStamp = $timestamp
        EventType = if ($eventID -eq 4624) { "Login" } else { "Logoff" }
        UserName  = $username
    }
} | Sort-Object TimeStamp

$activityInfo | Export-Csv -Path $activityReportFilePath -NoTypeInformation -Encoding UTF8
Write-Host "Login and logoff activity report has been generated and saved to $activityReportFilePath" -ForegroundColor Green

