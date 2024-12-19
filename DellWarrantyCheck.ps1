<#
.AUTHOR
Found somewhere online but lost the source.
Please send me attribution if you know the origins.

--Greg

.SYNOPSIS
Retrieves Dell warranty information for specified service tags and exports it to an optional INI file.

.DESCRIPTION
This PowerShell script retrieves warranty details for a list of Dell service tags by making authenticated API requests. The script supports exporting the retrieved information to an INI file for easy storage and reference. It handles authentication, processes service tag data, and formats the output accordingly.

.PREREQUISITES - IMPORTANT
- Execution Policy must be set to RemoteSigned to allow this script to run:
  Set-ExecutionPolicy RemoteSigned

- You will need your own API Key and Secret.
- Internet access is required to reach the Dell API endpoints.

.WARRANTY
- This script is provided "as is" with no warranties implied.
- Users are advised to thoroughly review and test the script in a controlled environment before deployment in production.
- As always, audit free scripts to remain vigilant against supply chain attacks.

.PARAMETER ServiceTags
A mandatory parameter that accepts an array of Dell service tags (1 to 100).

.PARAMETER ExportToIniFile
An optional parameter specifying the path to an INI file where the warranty details will be saved.

.CONFIGURATION
- `$API_KEY`: The API key for authenticating with Dell's API (stored securely).
- `$KEY_SECRET`: The API secret for authentication (stored securely).
- `$AUTH_URI`: The endpoint for obtaining an access token.
- `$WARRANTY_URI`: The endpoint for retrieving warranty information.
- `$DATE_FORMAT`: The date format used for displaying dates (`yyyy-MM-dd`).

.EXAMPLE
Retrieve warranty details for specified service tags and display them:

```powershell
.\Get-DellWarranty.ps1 -ServiceTags "ABC1234", "XYZ5678"
#>

[CmdletBinding()]
Param(
	[Parameter(Mandatory=$true)]
	[ValidateCount(1,100)]
	[String[]]
	$ServiceTags,
	
	[Parameter(Mandatory=$false)]
	[System.IO.FileInfo]
	$ExportToIniFile
)

Set-Variable API_KEY -Option Constant -Value 'SEE_BITWARDEN'
Set-Variable KEY_SECRET -Option Constant -Value 'SEE_BITWARDEN'

Set-Variable AUTH_URI -Option Constant -Value 'https://apigtwb2c.us.dell.com/auth/oauth/v2/token'
Set-Variable WARRANTY_URI -Option Constant -Value 'https://apigtwb2c.us.dell.com/PROD/sbil/eapi/v5/asset-entitlements'

Set-Variable DATE_FORMAT -Option Constant -Value 'yyyy-MM-dd'

function Delete-IniFile-IfNecessary() {
	if ($ExportToIniFile -eq $null) {
		Return
	}
	if ([System.IO.File]::Exists($ExportToIniFile)) {
		Remove-Item -Path $ExportToIniFile | Out-Null
	}
}

function AppendTo-IniFile-IfNecessary($InputObject) {
	if ($ExportToIniFile -eq $null) {
		Return
	}
	
	if (![System.IO.File]::Exists($ExportToIniFile)) {
		New-Item -ItemType File -Path $ExportToIniFile | Out-Null
	}
	
	Add-Content -Path $ExportToIniFile -Value "[$($InputObject.'Service Tag')]"
	Add-Content -Path $ExportToIniFile -Value "Model=$($InputObject.'Model')"
	Add-Content -Path $ExportToIniFile -Value "ModelSeries=$($InputObject.'Model Series')"
	Add-Content -Path $ExportToIniFile -Value "ShipDate=$($InputObject.'Ship Date')"
	Add-Content -Path $ExportToIniFile -Value "EndDate=$($InputObject.'End Date')"
	Add-Content -Path $ExportToIniFile -Value "ServiceLevelDescription=$($InputObject.'Service Level Description')"
	Add-Content -Path $ExportToIniFile -Value ""
}

function Get-Token {
	$encodedOAuth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$API_KEY`:$KEY_SECRET"))
	$authHeaders = @{'Authorization' = "Basic $encodedOAuth"}
	$authBody = 'grant_type=client_credentials'
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
	$authResult = Invoke-RestMethod -Uri $AUTH_URI -Method Post -Headers $authHeaders -Body $authBody
	return $authResult.access_token
}

Delete-IniFile-IfNecessary

$token = Get-Token
$headers = @{'Accept' = 'application/json'; 'Authorization' = "Bearer $token"}
$body = @{'servicetags' = ($ServiceTags -Join ', ')}
$assets = Invoke-RestMethod -Uri $WARRANTY_URI -Method Get -Headers $headers -Body $body -ContentType "application/json" -ea 0

foreach ($asset in $assets) {
	if ($asset.invalid) {
		continue
	}
	
	$serviceTag = $asset.serviceTag
	$model = $asset.productLineDescription
	$modelSeries = $asset.productLobDescription
	$shipDate = $asset.shipDate | Get-Date -f $DATE_FORMAT
	$serviceLevelDescription = ''
	$entitlementEndDate = $null
	foreach ($entitlement in $asset.entitlements) {
		if ($entitlement.endDate -gt $entitlementEndDate) {
			$serviceLevelDescription = $entitlement.serviceLevelDescription
			$entitlementEndDate = $entitlement.endDate
		}
	}
	$endDate = $entitlementEndDate | Get-Date -f $DATE_FORMAT

	$object = New-Object PSObject -Property @{
		'Service Tag' = $serviceTag
		'Model' =  $model
		'Model Series' = $modelSeries
		'Ship Date' = $shipDate
		'End Date' = $endDate
		'Service Level Description' = $serviceLevelDescription
	}
	
	AppendTo-IniFile-IfNecessary $object
	
	$object
}
