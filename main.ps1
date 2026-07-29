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

function Write-MenuItemColumns {
    param(
        [Parameter(Mandatory)][array]$Items,
        [int]$Columns = 3
    )

    $columnGap = 4
    $texts = $Items | ForEach-Object { "$($_.Number)) $($_.Text)" }
    $maxLen = ($texts | Measure-Object -Property Length -Maximum).Maximum
    $cellWidth = $maxLen + $columnGap
    $rows = [Math]::Ceiling($Items.Count / $Columns)

    for ($r = 0; $r -lt $rows; $r++) {
        Write-Host "    " -NoNewline
        for ($c = 0; $c -lt $Columns; $c++) {
            $idx = ($c * $rows) + $r
            if ($idx -ge $Items.Count) { continue }

            $entry = $Items[$idx]
            $numText = "$($entry.Number)) "
            Write-Host $numText -NoNewline -ForegroundColor Yellow

            $printedLen = $numText.Length + $entry.Text.Length
            if ($c -lt ($Columns - 1)) {
                $pad = [Math]::Max($cellWidth - $printedLen, 0)
                Write-Host ($entry.Text + (" " * $pad)) -NoNewline
            }
            else {
                Write-Host $entry.Text -NoNewline
            }
        }
        Write-Host ""
    }
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

    Write-SectionHeader -Title 'Configuration'
    Write-MenuItem -Number '2' -Text 'Apply'
    Write-MenuItem -Number '3' -Text 'Revert'

    Write-SectionHeader -Title 'Programs'
    Write-MenuItem -Number '4' -Text 'Winget'
    Write-MenuItem -Number '5' -Text 'Chocolatey'
    Write-Host ""

    Write-Host "    0) Exit" -ForegroundColor Red
    Write-Host ""
}

function Show-ApplyMenu {
    Clear-Host
    Write-TitleBanner

    Write-SectionHeader -Title 'Apply'
    Write-MenuItem -Number '1' -Text 'Apply Setup'

    Write-SectionHeader -Title 'Optional'
    Write-MenuItem -Number '2' -Text 'Activate Ultimate Performance Power Plan'
    Write-MenuItem -Number '3' -Text 'Disable Device Metadata (Beta)'
    Write-MenuItem -Number '4' -Text 'Disable Driver Downloads Via Windows Update'
    Write-MenuItem -Number '5' -Text 'Set Solid Color Black As Wallpaper'
    Write-Host ""

    Write-Host "    0) Back to Main Menu" -ForegroundColor Red
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

    Write-SectionHeader -Title 'Submenu'
    Write-MenuItem -Number '7' -Text 'Reinstall UWP Apps (Winget)'
    Write-Host ""

    Write-Host "    0) Back to Main Menu" -ForegroundColor Red
    Write-Host ""
}

function Show-UwpAppsMenu {
    Clear-Host
    Write-TitleBanner

    Write-SectionHeader -Title 'Reinstall UWP Apps'
    $uwpMenuItems = @(
        @{ Number = '1';  Text = 'Clipchamp' },
        @{ Number = '2';  Text = 'Copilot' },
        @{ Number = '3';  Text = 'Copilot - 365' },
        @{ Number = '4';  Text = 'Feedback Hub' },
        @{ Number = '5';  Text = 'Microsoft Teams' },
        @{ Number = '6';  Text = 'OneDrive' },
        @{ Number = '7';  Text = 'Outlook' },
        @{ Number = '8';  Text = 'Power Automate' },
        @{ Number = '9';  Text = 'Quick Assist' },
        @{ Number = '10'; Text = 'Sound Recorder' },
        @{ Number = '11'; Text = 'Sticky Notes' },
        @{ Number = '12'; Text = 'Weather' },
        @{ Number = '13'; Text = 'Widgets' },
        @{ Number = '14'; Text = 'Windows Camera' },
        @{ Number = '15'; Text = 'Windows Clock' },
        @{ Number = '16'; Text = 'Xbox' }
    )
    Write-MenuItemColumns -Items $uwpMenuItems -Columns 3
    Write-Host ""

    Write-Host "    0) Back to Revert Menu" -ForegroundColor Red
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

# Returns $true if the user chose to go back (0), otherwise $false.
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
    '1' = @{ Label = 'Apply Setup';                                   Path = 'apply\apply-setup.ps1';                     RequiresRestart = $true }
    '2' = @{ Label = 'Activate Ultimate Performance Power Plan';     Path = 'apply\activate-ultimate-power-plan.ps1' }
    '3' = @{ Label = 'Disable Device Metadata (Beta)';               Path = 'apply\disable-device-metadata.ps1' }
    '4' = @{ Label = 'Disable Driver Downloads Via Windows Update';  Path = 'apply\disable-drivers-via-windows-update.ps1' }
    '5' = @{ Label = 'Set Solid Color Black As Wallpaper';           Path = 'apply\set-wallpaper-black.ps1' }
}

$RevertActions = [ordered]@{
    '1' = @{ Label = 'Revert Setup Script (Settings Only)'; Path = 'revert\revert-settings.ps1'; RequiresRestart = $true }
    '2' = @{ Label = 'Enable Hibernate';                    Path = 'revert\enable-hibernate.ps1' }
    '3' = @{ Label = 'Revert Edge Settings';                Path = 'revert\revert-edge.ps1' }
    '4' = @{ Label = 'Revert Defender Settings';            Path = 'revert\revert-defender.ps1' }
    '5' = @{ Label = 'Revert Windows Update Settings';      Path = 'revert\revert-windows-update.ps1' }
    '6' = @{ Label = 'Revert Right-Click Context Menu';     Path = 'revert\revert-right-click.ps1' }
}

$UwpApps = [ordered]@{
    '1'  = @{ Label = 'Clipchamp';       Id = '9P1J8S7CCWWT' }
    '2'  = @{ Label = 'Copilot';         Id = 'XP9CXNGPPJ97XX' }
    '3'  = @{ Label = 'Copilot - 365';   Id = '9WZDNCRD29V9' }
    '4'  = @{ Label = 'Feedback Hub';    Id = '9NBLGGH4R32N' }
    '5'  = @{ Label = 'Microsoft Teams'; Id = 'XP8BT8DW290MPQ' }
    '6'  = @{ Label = 'OneDrive';        Id = 'Microsoft.OneDrive' }
    '7'  = @{ Label = 'Outlook';         Id = '9NRX63209R7B' }
    '8'  = @{ Label = 'Power Automate';  Id = '9NFTCH6J7FHV' }
    '9'  = @{ Label = 'Quick Assist';    Id = '9P7BP5VNWKX5' }
    '10' = @{ Label = 'Sound Recorder';  Id = '9WZDNCRFHWKN' }
    '11' = @{ Label = 'Sticky Notes';    Id = '9NBLGGH4QGHW' }
    '12' = @{ Label = 'Weather';         Id = '9WZDNCRFJ3Q2' }
    '13' = @{ Label = 'Widgets';         Id = '9MSSGKG348SP' }
    '14' = @{ Label = 'Windows Camera';  Id = '9WZDNCRFJBBG' }
    '15' = @{ Label = 'Windows Clock';   Id = '9WZDNCRFJ3PR' }
    '16' = @{ Label = 'Xbox';            Id = '9MV0B5HZVK9Z' }
}

function Invoke-ApplyMenu {
    while ($true) {
        Show-ApplyMenu

        $choice = Read-MenuChoice -Range "0-5" -MultiSelect
        if ($null -eq $choice) { continue }
        if ([string]::IsNullOrWhiteSpace($choice)) { continue }

        if (Invoke-SelectedActions -RawChoice $choice -Actions $ApplyActions) { return }
    }
}

function Invoke-UwpAppsMenu {
    while ($true) {
        Show-UwpAppsMenu

        $choice = Read-MenuChoice -Range "0-16" -MultiSelect
        if ($null -eq $choice) { continue }
        if ([string]::IsNullOrWhiteSpace($choice)) { continue }

        $wingetInstall = {
            param($action)
            Start-Process -FilePath 'winget' -ArgumentList @(
                'install', '--id', $action.Id, '-e',
                '--accept-package-agreements', '--accept-source-agreements'
            ) -NoNewWindow -Wait
        }

        if (Invoke-SelectedActions -RawChoice $choice -Actions $UwpApps -Execute $wingetInstall) { return }
    }
}

function Invoke-RevertMenu {
    while ($true) {
        Show-RevertMenu

        $choice = Read-MenuChoice -Range "0-7" -MultiSelect
        if ($null -eq $choice) { continue }
        if ([string]::IsNullOrWhiteSpace($choice)) { continue }

        $tokens = Expand-ChoiceTokens -RawChoice $choice

        if ($tokens -contains '7') {
            if ($tokens.Count -eq 1) {
                Invoke-UwpAppsMenu
            }
            else {
                Write-Host ""
                Write-Host "    Reinstall UWP Apps (Winget) must be selected on its own." -ForegroundColor Red
                Wait-ForReturnToMenu
            }
            continue
        }

        if (Invoke-SelectedActions -RawChoice $choice -Actions $RevertActions) { return }
    }
}

if (-not (Test-IsAdmin)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

while ($true) {
    Show-MainMenu

    $choice = Read-MenuChoice -Range "0-5"
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
                Invoke-ApplyMenu
            }
            '3' {
                Invoke-RevertMenu
            }
            '4' {
                & "$PSScriptRoot\programs\winget-menu.ps1"
                continue
            }
            '5' {
                & "$PSScriptRoot\programs\chocolatey-menu.ps1"
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