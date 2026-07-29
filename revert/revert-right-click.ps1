# Script by PaladinXV

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

try {
    Remove-Item -Path 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}' -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "    - Right Click Menu Settings Reverted" -ForegroundColor Green
}
catch {
    Write-Host "    ERROR: $($_.Exception.Message)" -ForegroundColor Red
    throw
}