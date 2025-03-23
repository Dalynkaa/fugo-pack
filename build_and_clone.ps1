param(
    [Parameter(Mandatory=$false)]
    [string]$DestinationPath = ""
)

$ErrorActionPreference = "Stop"

# Project name and current directory path
$projectName = "fugo-pack"
$currentDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentDir = Split-Path -Parent $currentDir

# Read from .env file if DestinationPath is not provided
if ([string]::IsNullOrEmpty($DestinationPath)) {
    $envFilePath = Join-Path $currentDir ".env"
    if (Test-Path $envFilePath) {
        Get-Content $envFilePath | ForEach-Object {
            if ($_ -match "^DESTINATION_PATH=(.*)$") {
                $DestinationPath = $matches[1].Trim('"').Trim("'")
                Write-Host "Using destination path from .env file: $DestinationPath"
            }
        }
    }
    
    # Set default path if still empty
    if ([string]::IsNullOrEmpty($DestinationPath)) {
        $DestinationPath = "C:\Users\zambo\AppData\Roaming\ModrinthApp\profiles\Fabulously Optimized (1)\resourcepacks"
        Write-Host "Using default destination path: $DestinationPath"
    }
}

# Create temporary directory for building
$tempDir = Join-Path $env:TEMP "temp_$projectName"
if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempDir | Out-Null

# Copy all files from current directory to temporary one, excluding specific files and folders
Write-Host "Copying files to temporary directory..."
$excludeItems = @("build_and_clone.ps1", ".git", ".gitignore", ".vscode", "README.md", "*.zip", ".github", ".env")
Get-ChildItem -Path $currentDir -Exclude $excludeItems | 
    Copy-Item -Destination $tempDir -Recurse -Force

# Create zip archive
$zipFileName = "${projectName}.zip"
$zipFilePath = Join-Path $currentDir $zipFileName

Write-Host "Creating archive $zipFileName..."
Compress-Archive -Path "$tempDir\*" -DestinationPath $zipFilePath -Force

# Check if destination directory exists
if (-not (Test-Path $DestinationPath)) {
    Write-Host "Destination directory $DestinationPath does not exist. Creating..."
    New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
}

# Copy zip file to destination directory
Write-Host "Copying archive to $DestinationPath..."
Copy-Item -Path $zipFilePath -Destination $DestinationPath -Force

# Cleanup
Write-Host "Cleaning up temporary files..."
if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}

Write-Host "Done! Archive $zipFileName has been successfully created and copied to $DestinationPath"