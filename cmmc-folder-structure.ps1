# by Greg Lawler 2/12/2020

# Define the base directory for CMMC Compliance
$baseDir = "C:\CMMC_Compliance"

# Define the CMMC control families and their subdirectories
$controlFamilies = @(
    "3.1 AC - Access Control",
    "3.2 AM - Asset Management",
    "3.3 AU - Audit and Accountability",
    "3.4 AT - Awareness and Training",
    "3.5 CM - Configuration Management",
    "3.6 IA - Identification and Authentication",
    "3.7 IR - Incident Response",
    "3.8 MA - Maintenance",
    "3.9 MP - Media Protection",
    "3.10 PS - Personnel Security",
    "3.11 PE - Physical Protection",
    "3.12 RE - Recovery",
    "3.13 RM - Risk Management",
    "3.14 CA - Security Assessment",
    "3.15 SA - Situational Awareness",
    "3.16 SC - System and Communications Protection",
    "3.17 SI - System and Information Integrity"
)

# Define the common subdirectories for each control family
$subDirectories = @(
    "Policies",
    "Procedures",
    "Screenshots",
    "Evidence"
)

# Create the control family folders and their subdirectories
foreach ($family in $controlFamilies) {
    foreach ($subDir in $subDirectories) {
        $fullPath = Join-Path -Path $baseDir -ChildPath "$family\$subDir"
        if (-not (Test-Path -Path $fullPath)) {
            New-Item -ItemType Directory -Path $fullPath -Force
            Write-Output "Created folder: $fullPath"
        } else {
            Write-Output "Folder already exists: $fullPath"
        }
    }
}

# Create additional general directories
$additionalDirs = @(
    "Policy Documents\General Policies",
    "Policy Documents\Specific Policies by Control",
    "Procedures\General Procedures",
    "Procedures\Specific Procedures by Control",
    "Evidence\Screenshots",
    "Evidence\Logs",
    "Evidence\Reports",
    "Training\Training Materials",
    "Training\Training Records",
    "PO&M (Plan of Actions & Milestones)",
    "SSP (System Security Plan)"
)

foreach ($dir in $additionalDirs) {
    $fullPath = Join-Path -Path $baseDir -ChildPath $dir
    if (-not (Test-Path -Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force
        Write-Output "Created folder: $fullPath"
    } else {
        Write-Output "Folder already exists: $fullPath"
    }
}

Write-Output "Folder structure creation complete."

