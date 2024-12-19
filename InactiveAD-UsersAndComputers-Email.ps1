<#
.AUTHOR
Outside Open - 2019
https://outsideopen.com/

.SYNOPSIS
This script performs audits on inactive computers and user object statuses in Active Directory, emails the findings, and stores logs in a specified directory.

.DESCRIPTION
This PowerShell script automates the process of auditing inactive computers and user object statuses within Active Directory. It generates reports, sends them via email to specified recipients, and stores the report logs in the 'c:\isso\audits\' directory.

.PREREQUISITES - IMPORTANT
- Execution Policy must be set to RemoteSigned to allow this script to run. This is only required per target computer:
  Set-ExecutionPolicy RemoteSigned

.WARRANTY
- This script is provided "as is" with no warranties implied. 
- Users are advised to thoroughly review and test the script in a controlled environment before deployment in production
- As always, audit free scripts to remain vigilant against supply chain attacks.

.EXAMPLE
Navigate to the script's directory in an administrative PowerShell session and enter:
.\InactiveAD-UsersAndComputers-Email.ps1

.PARAMETER HelpParam
Outputs usage instructions when provided with `/?`.

.CONFIGURATION
- $backupFolderPath: Specifies the path where backup files are stored.
- $filesToKeep: Specifies the number of recent backup files to retain.
#>

# Import the ActiveDirectory module
Import-Module activedirectory

# Shared variables
$logdate = Get-Date -format yyyyMMdd
$smtpserver = "foo.mail.protection.office365.us"
$emailFrom = "foo@example.com"
$emailTo = @('reports@example.com', 'alerts@example.com')
$DaysInactive = "60.00:00:00"

# Audit Inactive Computers
$compLogfile = "c:\isso\audits\ExpiredComputers - "+$logdate+".csv"
$compSubject = "Old computers in Active Directory"
$compBody = "Attached you will find the list of computers that have been inactive for greater than 60 days and have been disabled."
# Generate and email the computer audit log
Search-ADAccount -ComputersOnly -AccountInactive -TimeSpan $DaysInactive | Where-Object {$_.Enabled -eq "True"} | Where-Object {$_.DistinguishedName -notlike "*OU=Servers*"} | Where-Object {$_.DistinguishedName -notlike "*OU=Domain Controllers*"} | Select-Object Name, DistinguishedName, LastLogonDate | Export-Csv $compLogfile -NoTypeInformation
Search-ADAccount -ComputersOnly -AccountInactive -TimeSpan $DaysInactive | Where-Object {$_.Enabled -eq "True"} | Where-Object {$_.DistinguishedName -notlike "*OU=Servers*"} | Where-Object {$_.DistinguishedName -notlike "*OU=Domain Controllers*"} | Disable-ADAccount
Send-MailMessage -To $emailTo -From $emailFrom -Subject $compSubject -Body $compBody -Attachments $compLogfile -SmtpServer $smtpserver

# Audit User Objects
$userLogfile = "c:\isso\audits\UserAudit - "+$logdate+".csv"
$userSubject = "User object status in Active Directory"
$userBody = "Attached you will find the list of user objects in AD and their status. Any user in an OU containing the word 'Disabled' is excluded from this report."
# Generate and email the user audit log
Get-ADUser -ldapfilter "(objectClass=user)" -Properties SamAccountname, DisplayName, enabled | Where-Object {$_.DistinguishedName -notlike "*OU=Disabled*"} | Select sAMAccountNAme, DisplayName, enabled | Export-Csv $userLogfile -NoTypeInformation
Send-MailMessage -To $emailTo -From $emailFrom -Subject $userSubject -Body $userBody -Attachments $userLogfile -SmtpServer $smtpserver

