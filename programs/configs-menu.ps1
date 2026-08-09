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

$ApplyConfigs = [ordered]@{
    '1' = @{ Name = 'Brave'; Path = 'configs\apply\brave.ps1' }
}

$RevertConfigs = [ordered]@{
    '1' = @{ Name = 'Brave'; Path = 'configs\revert\brave.ps1' }
}

function Show-ConfigList {
    param(
        [Parameter(Mandatory)][string]$Title,
        [Parameter(Mandatory)][System.Collections.Specialized.OrderedDictionary]$Configs
    )

    Clear-Host
    Write-Host ""
    Write-Host "    Simple Windows 11 Setup Script - By PaladinXV" -ForegroundColor Cyan
    Write-Host "    ---------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    Configs (beta) - $Title" -ForegroundColor Yellow
    Write-Host "    ----------------" -ForegroundColor DarkGray
    Write-Host ""

    foreach ($key in $Configs.Keys) {
        Write-Host "    $key) " -NoNewline -ForegroundColor Yellow
        Write-Host $Configs[$key].Name
    }
    Write-Host ""
    Write-Host "    0) Back" -ForegroundColor Red
    Write-Host ""
}

function Invoke-ConfigMenu {
    param(
        [Parameter(Mandatory)][string]$Title,
        [Parameter(Mandatory)][System.Collections.Specialized.OrderedDictionary]$Configs
    )

    while ($true) {
        Show-ConfigList -Title $Title -Configs $Configs

        $choice = Read-Host "    Select an option"
        if ([string]::IsNullOrWhiteSpace($choice)) { continue }
        $choice = $choice.Trim()

        if ($choice -eq '0') { return }

        if ($Configs.Contains($choice)) {
            $config = $Configs[$choice]
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
    Write-Host "    1) Apply" -ForegroundColor Yellow
    Write-Host "    2) Revert" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    0) Back" -ForegroundColor Red
    Write-Host ""

    $choice = Read-Host "    Select an option"
    if ([string]::IsNullOrWhiteSpace($choice)) { continue }
    $choice = $choice.Trim()

    switch ($choice) {
        '1' { Invoke-ConfigMenu -Title 'Apply' -Configs $ApplyConfigs }
        '2' { Invoke-ConfigMenu -Title 'Revert' -Configs $RevertConfigs }
        '0' { return }
        default {
            Write-Host ""
            Write-Host "    Invalid selection: $choice" -ForegroundColor Red
            Wait-ForConfigs
        }
    }
}