# Script by PaladinXV

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$driverSearchingPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching'
if (-not (Test-Path $driverSearchingPath)) {
    New-Item -Path $driverSearchingPath -Force | Out-Null
}
New-ItemProperty -Path $driverSearchingPath -Name 'SearchOrderConfig' -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path $driverSearchingPath -Name 'DontSearchWindowsUpdate' -Value 1 -PropertyType DWord -Force | Out-Null

$driverSearchingPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching'
if (-not (Test-Path $driverSearchingPolicyPath)) {
    New-Item -Path $driverSearchingPolicyPath -Force | Out-Null
}
New-ItemProperty -Path $driverSearchingPolicyPath -Name 'SearchOrderConfig' -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path $driverSearchingPolicyPath -Name 'DontSearchWindowsUpdate' -Value 1 -PropertyType DWord -Force | Out-Null

Write-Host "    - Disabled Driver Downloads Via Windows Update." -ForegroundColor Green