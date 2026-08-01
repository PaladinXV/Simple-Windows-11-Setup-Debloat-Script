# Script by PaladinXV

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Wait-ForConfigs {
    Write-Host ""
    Write-Host "    Press Enter to continue " -ForegroundColor Yellow -NoNewline
    Read-Host | Out-Null
}

$configs = [ordered]@{
    '1' = @{ Name = 'Brave'; Path = 'configs\brave.ps1' }
}

while ($true) {
    Clear-Host
    Write-Host ""
    Write-Host "    Simple Windows 11 Setup Script - By PaladinXV" -ForegroundColor Cyan
    Write-Host "    ---------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    Configs (beta)" -ForegroundColor Yellow
    Write-Host "    ----------------" -ForegroundColor DarkGray
    Write-Host ""

    foreach ($key in $configs.Keys) {
        Write-Host "    $key) " -NoNewline -ForegroundColor Yellow
        Write-Host $configs[$key].Name
    }
    Write-Host ""
    Write-Host "    0) Back" -ForegroundColor Red
    Write-Host ""

    $choice = Read-Host "    Select an option"
    if ([string]::IsNullOrWhiteSpace($choice)) { continue }
    $choice = $choice.Trim()

    if ($choice -eq '0') { return }

    if ($configs.Contains($choice)) {
        $config = $configs[$choice]
        Write-Host ""
        try {
            & (Join-Path $PSScriptRoot $config.Path)
        }
        catch {
            Write-Host "    ERROR: $($_.Exception.Message)" -ForegroundColor Red
        }
        Wait-ForConfigs
    }
    else {
        Write-Host ""
        Write-Host "    Invalid selection: $choice" -ForegroundColor Red
        Wait-ForConfigs
    }
}