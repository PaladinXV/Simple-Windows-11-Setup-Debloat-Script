# Script by PaladinXV

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

try {
    $wuPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'

    if (Test-Path $wuPolicyPath) {
        Remove-ItemProperty -Path $wuPolicyPath -Name 'DeferFeatureUpdates' -Force -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $wuPolicyPath -Name 'DeferFeatureUpdatesPeriodInDays' -Force -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $wuPolicyPath -Name 'DeferQualityUpdates' -Force -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $wuPolicyPath -Name 'DeferQualityUpdatesPeriodInDays' -Force -ErrorAction SilentlyContinue
    }

    Write-Host "    - Windows Update Settings Reverted" -ForegroundColor Green
}
catch {
    Write-Host "    ERROR: $($_.Exception.Message)" -ForegroundColor Red
    throw
}