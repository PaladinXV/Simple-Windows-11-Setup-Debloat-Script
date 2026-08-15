# Script by PaladinXV

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

# Duplicate scheme if it doesn't already exist
$ultimateGuid = "e9a42b02-d5df-448d-aa00-03f14749eb61"
$plans = powercfg /list

if ($plans -notmatch $ultimateGuid) {
    powercfg -duplicatescheme $ultimateGuid | Out-Null
}

# Find the duplicated plan GUID and activate it
$plans = powercfg /list
$targetLine = $plans | Where-Object { $_ -match "Ultimate Performance" } | Select-Object -First 1

if (-not $targetLine) {
    throw "Could not find 'Ultimate Performance' plan"
}

if ($targetLine -match '([0-9a-fA-F\-]{36})') {
    $activeGuid = $matches[1]
    powercfg /setactive $activeGuid
    Write-Host "    - Ultimate Performance is now active." -ForegroundColor Green
} else {
    throw "Could not find power plan GUID."
}