[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$restorePointName = "Restore Point - PaladinXV Script"

try {
    Enable-ComputerRestore -Drive "$($env:SystemDrive)\" -ErrorAction SilentlyContinue

    $warnings = @()
    $null = Checkpoint-Computer `
        -Description $restorePointName `
        -RestorePointType "MODIFY_SETTINGS" `
        -WarningVariable +warnings `
        -WarningAction SilentlyContinue

    $warningText = ($warnings | Out-String)
    if ($warningText -match 'already been created within the past 1440 minutes') {
        Write-Host "    - No Restore Point Created (24-hour Windows limitation)" -ForegroundColor Yellow
        return
    }

    Write-Host "    - Restore Point Created" -ForegroundColor Green
}
catch {
    Write-Host "    ERROR: $($_.Exception.Message)" -ForegroundColor Red
    throw
}