# Script by PaladinXV

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repoZip = 'https://github.com/PaladinXV/Simple-Windows-11-Setup-Debloat-Script/archive/refs/heads/main.zip'
$tempRoot = Join-Path $env:TEMP ('paladinxv-setup-' + [guid]::NewGuid().ToString())
$zipPath = Join-Path $tempRoot 'repo.zip'
$extractPath = Join-Path $tempRoot 'repo'

New-Item -ItemType Directory -Path $extractPath -Force | Out-Null

Write-Host ""
Write-Host "Downloading script package..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $repoZip -OutFile $zipPath

Write-Host "Extracting..." -ForegroundColor Cyan
Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

$mainScript = Get-ChildItem -Path $extractPath -Recurse -Filter 'main.ps1' | Select-Object -First 1
if (-not $mainScript) {
    throw "main.ps1 not found in downloaded package."
}

Write-Host "Launching main menu..." -ForegroundColor Cyan
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $mainScript.FullName
