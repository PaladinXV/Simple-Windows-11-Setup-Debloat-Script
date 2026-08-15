# Script by PaladinXV
# Windows 11 25H2

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

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

function Show-EditionMenu {
    Clear-Host
    Write-TitleBanner

    Write-SectionHeader -Title 'Windows 11 25H2'
    Write-MenuItem -Number '1' -Text 'Apply'
    Write-MenuItem -Number '2' -Text 'Revert'
    Write-Host ""

    Write-Host "    0) Back to Main Menu" -ForegroundColor Red
    Write-Host ""
}

function Show-ApplyMenu {
    Clear-Host
    Write-TitleBanner

    Write-SectionHeader -Title 'Apply'
    Write-MenuItem -Number '1' -Text 'Apply All'
    Write-MenuItem -Number '2' -Text 'Apply Settings Only'

    Write-SectionHeader -Title 'Optional'
    Write-MenuItem -Number '3' -Text 'Activate Ultimate Performance Power Plan'
    Write-MenuItem -Number '4' -Text 'Disable Device Metadata (Beta)'
    Write-MenuItem -Number '5' -Text 'Disable Driver Downloads Via Windows Update'
    Write-MenuItem -Number '6' -Text 'Set Solid Color Black As Wallpaper'
    Write-Host ""

    Write-Host "    0) Back" -ForegroundColor Red
    Write-Host ""
}

function Show-RevertMenu {
    Clear-Host
    Write-TitleBanner

    Write-SectionHeader -Title 'Revert'
    Write-MenuItem -Number '1' -Text 'Revert Setup Script (Settings Only)'

    Write-SectionHeader -Title 'Individual'
    Write-MenuItem -Number '2' -Text 'Enable Hibernate'
    Write-MenuItem -Number '3' -Text 'Revert Edge Settings'
    Write-MenuItem -Number '4' -Text 'Revert Defender Settings'
    Write-MenuItem -Number '5' -Text 'Revert Windows Update Settings'
    Write-MenuItem -Number '6' -Text 'Revert Right-Click Context Menu'
    Write-Host ""

    Write-Host "    0) Back" -ForegroundColor Red
    Write-Host ""
}

function Expand-ChoiceTokens {
    param([Parameter(Mandatory)][string]$RawChoice)

    $rawTokens = $RawChoice -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }

    $tokens = New-Object System.Collections.Generic.List[string]
    foreach ($rt in $rawTokens) {
        if ($rt -match '^(\d+)-(\d+)$') {
            $start = [int]$Matches[1]
            $end = [int]$Matches[2]
            ($start..$end) | ForEach-Object { $tokens.Add("$_") }
        }
        else {
            $tokens.Add($rt)
        }
    }

    return ,$tokens
}

function Invoke-SelectedActions {
    param(
        [Parameter(Mandatory)][string]$RawChoice,
        [Parameter(Mandatory)][System.Collections.Specialized.OrderedDictionary]$Actions,
        [scriptblock]$Execute = { param($action) & (Join-Path $PSScriptRoot $action.Path) }
    )

    $tokens = Expand-ChoiceTokens -RawChoice $RawChoice

    if ($tokens -contains '0') {
        return $true
    }

    $validTokens = New-Object System.Collections.Generic.List[string]
    foreach ($t in $tokens) {
        if ($Actions.Contains($t)) {
            if (-not $validTokens.Contains($t)) { $validTokens.Add($t) }
        }
        else {
            Write-Host "    Invalid selection: $t" -ForegroundColor Red
        }
    }

    if ($validTokens.Count -eq 0) {
        Wait-ForReturnToMenu
        return $false
    }

    Write-Host ""

    $needsRestart = $false
    foreach ($t in $validTokens) {
        $action = $Actions[$t]
        try {
            & $Execute $action | Out-Host
            if ($action.Contains('RequiresRestart') -and $action.RequiresRestart) { $needsRestart = $true }
        }
        catch {
            Write-Host "    ERROR: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    if ($needsRestart) {
        Write-Host ""
        Write-Host "    Please Restart Your PC." -ForegroundColor Yellow
    }

    Wait-ForReturnToMenu
    return $false
}

$ApplyActions = [ordered]@{
    '1' = @{ Label = 'Apply All';                                     Path = 'apply\apply-setup.ps1';                                RequiresRestart = $true }
    '2' = @{ Label = 'Apply Settings Only';                           Path = 'apply\apply-settings.ps1';                             RequiresRestart = $true }
    '3' = @{ Label = 'Activate Ultimate Performance Power Plan';     Path = '..\..\shared\apply\activate-ultimate-power-plan.ps1' }
    '4' = @{ Label = 'Disable Device Metadata (Beta)';               Path = '..\..\shared\apply\disable-device-metadata.ps1' }
    '5' = @{ Label = 'Disable Driver Downloads Via Windows Update';  Path = '..\..\shared\apply\disable-drivers-via-windows-update.ps1' }
    '6' = @{ Label = 'Set Solid Color Black As Wallpaper';           Path = '..\..\shared\apply\set-wallpaper-black.ps1' }
}

$RevertActions = [ordered]@{
    '1' = @{ Label = 'Revert Setup Script (Settings Only)'; Path = 'revert\revert-settings.ps1'; RequiresRestart = $true }
    '2' = @{ Label = 'Enable Hibernate';                    Path = '..\..\shared\revert\enable-hibernate.ps1' }
    '3' = @{ Label = 'Revert Edge Settings';                Path = '..\..\shared\revert\revert-edge.ps1' }
    '4' = @{ Label = 'Revert Defender Settings';            Path = '..\..\shared\revert\revert-defender.ps1' }
    '5' = @{ Label = 'Revert Windows Update Settings';      Path = '..\..\shared\revert\revert-windows-update.ps1' }
    '6' = @{ Label = 'Revert Right-Click Context Menu';     Path = '..\..\shared\revert\revert-right-click.ps1' }
}

function Invoke-ApplyMenu {
    while ($true) {
        Show-ApplyMenu

        $choice = Read-MenuChoice -Range "0-6" -MultiSelect
        if ($null -eq $choice) { continue }
        if ([string]::IsNullOrWhiteSpace($choice)) { continue }

        if (Invoke-SelectedActions -RawChoice $choice -Actions $ApplyActions) { return }
    }
}

function Invoke-RevertMenu {
    while ($true) {
        Show-RevertMenu

        $choice = Read-MenuChoice -Range "0-6" -MultiSelect
        if ($null -eq $choice) { continue }
        if ([string]::IsNullOrWhiteSpace($choice)) { continue }

        if (Invoke-SelectedActions -RawChoice $choice -Actions $RevertActions) { return }
    }
}

while ($true) {
    Show-EditionMenu

    $choice = Read-MenuChoice -Range "0-2"
    if ($null -eq $choice) { continue }
    $choice = $choice.Trim()
    if ([string]::IsNullOrWhiteSpace($choice)) { continue }

    switch ($choice) {
        '1' { Invoke-ApplyMenu }
        '2' { Invoke-RevertMenu }
        '0' { return }
        default {
            Write-Host ""
            Write-Host "    Invalid selection: $choice" -ForegroundColor Red
            Wait-ForReturnToMenu
        }
    }
}