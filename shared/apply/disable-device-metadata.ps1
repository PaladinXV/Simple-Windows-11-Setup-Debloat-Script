# Script by PaladinXV

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$deviceMetadataPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata'
if (-not (Test-Path $deviceMetadataPath)) {
    New-Item -Path $deviceMetadataPath -Force | Out-Null
}
New-ItemProperty -Path $deviceMetadataPath -Name 'PreventDeviceMetadataFromNetwork' -Value 1 -PropertyType DWord -Force | Out-Null

$deviceMetadataPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata'
if (-not (Test-Path $deviceMetadataPolicyPath)) {
    New-Item -Path $deviceMetadataPolicyPath -Force | Out-Null
}
New-ItemProperty -Path $deviceMetadataPolicyPath -Name 'PreventDeviceMetadataFromNetwork' -Value 1 -PropertyType DWord -Force | Out-Null

Write-Host "    - Disabled Device Metadata." -ForegroundColor Green