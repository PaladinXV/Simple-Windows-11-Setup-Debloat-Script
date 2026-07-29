# Script by PaladinXV

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

try {
    & powercfg.exe /hibernate on
    if ($LASTEXITCODE -ne 0) {
        throw "powercfg returned exit code $LASTEXITCODE"
    }

    Write-Host "    - Hibernate Enabled" -ForegroundColor Green
}
catch {
    Write-Host "    ERROR: $($_.Exception.Message)" -ForegroundColor Red
    throw
}