# Script by PaladinXV

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

try {
    try { Set-MpPreference -SubmitSamplesConsent 1 } catch {}

    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy' -Name 'VerifiedAndReputablePolicyState' -Force -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' -Name 'Enabled' -Force -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard' -Name 'EnableVirtualizationBasedSecurity' -Force -ErrorAction SilentlyContinue

    & bcdedit.exe /set hypervisorlaunchtype auto *> $null

    Write-Host "    - Defender / VBS Settings Reverted" -ForegroundColor Green
}
catch {
    Write-Host "    ERROR: $($_.Exception.Message)" -ForegroundColor Red
    throw
}