# Script by PaladinXV

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Wait-ForReturnToMenu {
    Write-Host ""
    Read-Host "    Press Enter to return to menu" | Out-Null
}

function Write-MenuItem {
    param(
        [Parameter(Mandatory)][string]$Number,
        [Parameter(Mandatory)][string]$Text
    )
    Write-Host "    " -NoNewline
    Write-Host "$Number) " -NoNewline -ForegroundColor Yellow
    Write-Host $Text
}

function Read-MenuChoice {
    param(
        [Parameter(Mandatory)][string]$Range,
        [switch]$MultiSelect
    )
    if ($MultiSelect) {
        Write-Host "    Multi-select available (e.g. 1,3,4 or 1-4)" -ForegroundColor DarkGray
    }
    return Read-Host "    Select an option ($Range)"
}

function Write-TitleBanner {
    Write-Host ""
    Write-Host "    Simple Windows 11 Setup Script - By PaladinXV" -ForegroundColor Cyan
    Write-Host "    ---------------------------------------------------------------" -ForegroundColor DarkGray
}

function Write-SectionHeader {
    param(
        [Parameter(Mandatory)][string]$Title
    )
    Write-Host ""
    Write-Host "    $Title" -ForegroundColor Yellow
    Write-Host "    ----------------" -ForegroundColor DarkGray
}

function Show-MainMenu {
    Clear-Host
    Write-TitleBanner

    Write-SectionHeader -Title 'Restore Point'
    Write-MenuItem -Number '1' -Text 'Create Restore Point'

    Write-SectionHeader -Title 'Windows Editions'
    Write-MenuItem -Number '2' -Text 'Windows 11 25H2'
    Write-MenuItem -Number '3' -Text 'Windows 10 LTSC 2021'
    Write-MenuItem -Number '4' -Text 'Windows 11 LTSC 2024'

    Write-SectionHeader -Title 'Programs'
    Write-MenuItem -Number '5' -Text 'Winget'
    Write-MenuItem -Number '6' -Text 'Chocolatey'
    Write-MenuItem -Number '7' -Text 'Configs (beta)'
    Write-Host ""

    Write-Host "    0) Exit" -ForegroundColor Red
    Write-Host ""
}

if (-not (Test-IsAdmin)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

while ($true) {
    Show-MainMenu

    $choice = Read-MenuChoice -Range "0-7"
    if ($null -eq $choice) { continue }
    $choice = $choice.Trim()
    if ([string]::IsNullOrWhiteSpace($choice)) { continue }

    Write-Host ""

    try {
        switch ($choice) {
            '1' {
                & "$PSScriptRoot\restore-point.ps1"
                Wait-ForReturnToMenu
            }
            '2' {
                & "$PSScriptRoot\editions\win11-25h2\edition-menu.ps1"
                continue
            }
            '3' {
                & "$PSScriptRoot\editions\win10-ltsc-2021\edition-menu.ps1"
                continue
            }
            '4' {
                & "$PSScriptRoot\editions\win11-ltsc-2024\edition-menu.ps1"
                continue
            }
            '5' {
                & "$PSScriptRoot\programs\winget-menu.ps1"
                continue
            }
            '6' {
                & "$PSScriptRoot\programs\chocolatey-menu.ps1"
                continue
            }
            '7' {
                & "$PSScriptRoot\programs\configs-menu.ps1"
                continue
            }
            '0' {
                Write-Host "    Exiting..." -ForegroundColor Red
                [Environment]::Exit(0)
            }
            default {
                Write-Host "    Invalid selection: $choice" -ForegroundColor Red
                Wait-ForReturnToMenu
            }
        }
    }
    catch {
        Write-Host "    ERROR: $($_.Exception.Message)" -ForegroundColor Red
        Wait-ForReturnToMenu
    }
}