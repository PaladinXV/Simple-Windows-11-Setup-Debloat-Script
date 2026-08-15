# Script by PaladinXV

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Remove-RegValue {
    param([string]$Path, [string]$Name)
    if (Test-Path $Path) { Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction SilentlyContinue }
}

try {
    $edgePolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
    Remove-RegValue -Path $edgePolicyPath -Name 'HideFirstRunExperience'
    Remove-RegValue -Path $edgePolicyPath -Name 'StartupBoostEnabled'
    Remove-RegValue -Path $edgePolicyPath -Name 'BackgroundModeEnabled'

    Write-Host "    - Edge Settings Reverted" -ForegroundColor Green
}
catch {
    Write-Host "    ERROR: $($_.Exception.Message)" -ForegroundColor Red
    throw
}