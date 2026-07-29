# Script by PaladinXV

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Wait-ForChoco {
    Write-Host ""
    Read-Host "    Press Enter to continue" | Out-Null
}

function Update-ProcessPath {
    $machinePath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath    = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machinePath;$userPath"
}

function Test-ChocoInstalled {
    Update-ProcessPath
    return [bool](Get-Command choco -ErrorAction SilentlyContinue)
}

function Show-ChocoMissingPrompt {
    while ($true) {
        Clear-Host
        Write-Host ""
        Write-Host "    Chocolatey is not installed or not in PATH." -ForegroundColor Red
        Write-Host ""
        Write-Host "    1) Install Chocolatey" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "    0) Back" -ForegroundColor Red
        Write-Host ""

        $c = Read-Host "    Select option (0-1)"
        switch ($c) {
            '0' { return $false }
            '1' {
                Set-ExecutionPolicy Bypass -Scope Process -Force
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

                Update-ProcessPath

                if (Test-ChocoInstalled) {
                    Write-Host ""
                    Write-Host "    Chocolatey installed successfully." -ForegroundColor Green
                    Wait-ForChoco
                    return $true
                } else {
                    Write-Host ""
                    Write-Host "    Chocolatey install completed, but choco is not in this session PATH yet." -ForegroundColor Yellow
                    Write-Host "    Please reopen terminal/menu if commands fail." -ForegroundColor Yellow
                    Wait-ForChoco
                    return $false
                }
            }
            default {
                Write-Host ""
                Write-Host "    Invalid selection: $c" -ForegroundColor Red
                Wait-ForChoco
            }
        }
    }
}

function Invoke-Choco {
    param(
        [Parameter(Mandatory)][ValidateSet('install','uninstall','upgrade')][string]$Command,
        [string]$Id,
        [switch]$All
    )

    $chocoArgs = @($Command)
    if ($All) { $chocoArgs += 'all' }
    elseif ($Id) { $chocoArgs += $Id }

    if ($Command -in @('install','upgrade')) {
        $chocoArgs += @('-y','--no-progress')
    } else {
        $chocoArgs += '-y'
    }

    & choco @chocoArgs
}

function Install-ById {
    param([Parameter(Mandatory)][string]$Id,[Parameter(Mandatory)][string]$Name)
    Invoke-Choco -Command install -Id $Id
}

function Update-All {
    Invoke-Choco -Command upgrade -All
}

function Expand-Selection {
    param([Parameter(Mandatory)][string]$InputText)
    $result = New-Object System.Collections.Generic.List[int]
    foreach ($raw in ($InputText -split ',')) {
        $p = $raw.Trim()
        if (-not $p) { continue }
        if ($p -match '^\d+$') { $result.Add([int]$p); continue }
        if ($p -match '^(\d+)\s*-\s*(\d+)$') {
            $a=[int]$matches[1]; $b=[int]$matches[2]
            if ($b -lt $a) { $t=$a; $a=$b; $b=$t }
            for ($i=$a; $i -le $b; $i++) { $result.Add($i) }
        }
    }
    $result | Sort-Object -Unique
}

function Show-CatalogCardLayout {
    param([Parameter(Mandatory)]$Catalog)

    $indent = "    "
    $cardGap = 5
    $innerGap = 3
    $rowsPerInnerCol = 6

    $consoleWidth = [Math]::Max([Console]::WindowWidth, 80)
    $usableWidth = $consoleWidth - $indent.Length

    $catNames = @($Catalog.Keys)
    $cards = @{}

    foreach ($cat in $catNames) {
        $apps = @($Catalog[$cat])

        $items = @()
        foreach ($a in $apps) {
            $items += [PSCustomObject]@{
                N    = $a.N
                Name = $a.Name
                Text = ("{0}) {1}" -f $a.N, $a.Name)
            }
        }

        $maxItemLen = 0
        if ($items.Count -gt 0) {
            $maxItemLen = ($items.Text | Measure-Object -Maximum Length).Maximum
        }
        if (-not $maxItemLen) { $maxItemLen = 12 }

        $innerColWidth = $maxItemLen + $innerGap
        $innerCols = [Math]::Ceiling([Math]::Max($items.Count,1) / $rowsPerInnerCol)
        if ($innerCols -lt 1) { $innerCols = 1 }

        $rows = [Math]::Ceiling([Math]::Max($items.Count,1) / $innerCols)
        $contentWidth = ($innerCols * $innerColWidth) - $innerGap
        $headerWidth = ("- " + $cat).Length
        $cardWidth = [Math]::Max($headerWidth, $contentWidth)

        $cards[$cat] = [PSCustomObject]@{
            Name          = $cat
            Apps          = $items
            InnerCols     = $innerCols
            Rows          = $rows
            InnerColWidth = $innerColWidth
            Width         = $cardWidth
        }
    }

    $rowsOfCards = @()
    $currentRow = @()
    $currentWidth = 0

    foreach ($cat in $catNames) {
        $w = $cards[$cat].Width
        $needed = if ($currentRow.Count -eq 0) { $w } else { $cardGap + $w }

        if (($currentWidth + $needed) -le $usableWidth -or $currentRow.Count -eq 0) {
            $currentRow += $cat
            $currentWidth += $needed
        } else {
            $rowsOfCards += ,$currentRow
            $currentRow = @($cat)
            $currentWidth = $w
        }
    }
    if ($currentRow.Count -gt 0) { $rowsOfCards += ,$currentRow }

    foreach ($rowCats in $rowsOfCards) {
        Write-Host $indent -NoNewline
        for ($i=0; $i -lt $rowCats.Count; $i++) {
            $cat = $rowCats[$i]
            $card = $cards[$cat]
            $h = "- $($card.Name)"

            if ($i -lt $rowCats.Count - 1) {
                Write-Host $h.PadRight($card.Width + $cardGap) -ForegroundColor Yellow -NoNewline
            } else {
                Write-Host $h -ForegroundColor Yellow -NoNewline
            }
        }
        Write-Host ""

        $maxRows = 0
        foreach ($cat in $rowCats) {
            if ($cards[$cat].Rows -gt $maxRows) { $maxRows = $cards[$cat].Rows }
        }

        for ($r=0; $r -lt $maxRows; $r++) {
            Write-Host $indent -NoNewline

            for ($i=0; $i -lt $rowCats.Count; $i++) {
                $cat = $rowCats[$i]
                $card = $cards[$cat]

                $cellLen = 0
                for ($c=0; $c -lt $card.InnerCols; $c++) {
                    $idx = ($c * $card.Rows) + $r
                    if ($idx -lt $card.Apps.Count) {
                        $n = ("{0})" -f $card.Apps[$idx].N)
                        $name = $card.Apps[$idx].Name
                        $raw = "$n $name"

                        Write-Host $n -ForegroundColor Cyan -NoNewline
                        Write-Host (" " + $name) -ForegroundColor White -NoNewline
                        $printedLen = $raw.Length
                    } else {
                        $printedLen = 0
                    }

                    if ($c -lt ($card.InnerCols - 1)) {
                        $pad = [Math]::Max($card.InnerColWidth - $printedLen, 0)
                        if ($pad -gt 0) { Write-Host (" " * $pad) -NoNewline }
                        $cellLen += $card.InnerColWidth
                    } else {
                        $cellLen += $printedLen
                    }
                }

                if ($i -lt $rowCats.Count - 1) {
                    $padToCard = [Math]::Max(($card.Width + $cardGap) - $cellLen, 0)
                    if ($padToCard -gt 0) { Write-Host (" " * $padToCard) -NoNewline }
                }
            }

            Write-Host ""
        }

        Write-Host ""
    }
}

$catalog = [ordered]@{
    "Browsers" = @(
        @{ N=1; Name="Brave"; Id="brave" },
        @{ N=2; Name="Chrome"; Id="googlechrome" },
        @{ N=3; Name="FireFox"; Id="firefox" },
        @{ N=4; Name="Helium"; Id="helium" },
        @{ N=5; Name="Librewolf"; Id="librewolf" },
        @{ N=6; Name="Vivaldi"; Id="vivaldi" },
        @{ N=7; Name="Zen Browser"; Id="zen-browser" }
    )
    "Communication" = @(
        @{ N=8; Name="Discord"; Id="discord" },
        @{ N=9; Name="TeamSpeak"; Id="teamspeak" }
    )
    "Documents" = @(
        @{ N=10; Name="LibreOffice"; Id="libreoffice-fresh" },
        @{ N=11; Name="Notepad++"; Id="notepadplusplus" },
        @{ N=12; Name="OpenOffice"; Id="openoffice" }
    )
    "Gaming" = @(
        @{ N=13; Name="EA App"; Id="ea-app" },
        @{ N=14; Name="Epic Games Launcher"; Id="epicgameslauncher" },
        @{ N=15; Name="GOG Launcher"; Id="goggalaxy" },
        @{ N=16; Name="Steam"; Id="steam" }
    )
    "Windows Software" = @(
        @{ N=17; Name="Microsoft Teams (Classic)"; Id="microsoft-teams" },
        @{ N=18; Name="OneDrive"; Id="onedrive" },
        @{ N=19; Name="Visual C++ (2015+)"; Id="vcredist140" }
    )
    "Multimedia" = @(
        @{ N=20; Name="Foobar2000"; Id="foobar2000" },
        @{ N=21; Name="Handbrake"; Id="handbrake" },
        @{ N=22; Name="iTunes"; Id="itunes" },
        @{ N=23; Name="K-Lite Codec Standard"; Id="k-litecodecpackstandard" },
        @{ N=24; Name="OBS-Studio"; Id="obs-studio" },
        @{ N=25; Name="VLC Media Player"; Id="vlc" }
    )
    "Utilities" = @(
        @{ N=26; Name="7Zip"; Id="7zip" },
        @{ N=27; Name="Bitwarden"; Id="bitwarden" },
        @{ N=28; Name="CPU-Z"; Id="cpu-z" },
        @{ N=29; Name="Crystal Disk Info"; Id="crystaldiskinfo" },
        @{ N=30; Name="Crystal Disk Mark"; Id="crystaldiskmark" },
        @{ N=31; Name="Display Driver Uninstaller"; Id="ddu" },
        @{ N=32; Name="GPU-Z"; Id="gpu-z" },
        @{ N=33; Name="HWInfo"; Id="hwinfo" },
        @{ N=34; Name="HWMonitor"; Id="hwmonitor" },
        @{ N=35; Name="MSI Afterburner"; Id="msiafterburner" },
        @{ N=36; Name="Nanazip"; Id="nanazip" },
        @{ N=37; Name="Process Lasso"; Id="plasso" },
        @{ N=38; Name="qBitTorrent"; Id="qbittorrent" }
    )
}

$appsByNumber = @{}
foreach ($cat in $catalog.Keys) {
    foreach ($app in $catalog[$cat]) {
        $appsByNumber[$app.N] = $app
    }
}

while ($true) {
    if (-not (Test-ChocoInstalled)) {
        $ready = Show-ChocoMissingPrompt
        if (-not $ready) { return }
    }

    Clear-Host
    Write-Host ""
    Write-Host "    Simple Windows 11 Setup Script - By PaladinXV" -ForegroundColor Cyan
    Write-Host "    ---------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    Chocolatey" -ForegroundColor Yellow
    Write-Host "    ----------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host '    Multi-Selection is available "1,2,5-8"' -ForegroundColor DarkGray
    Write-Host "    A) Upgrade All" -ForegroundColor Yellow
    Write-Host "    0) Back" -ForegroundColor Red
    Write-Host ""

    Show-CatalogCardLayout -Catalog $catalog

    $choice = Read-Host "    Select option(s)"
    if ($choice -eq '0') { return }

    if ($choice -match '^[Aa]$') { Update-All; Wait-ForChoco; continue }

    $numbers = @(Expand-Selection -InputText $choice)
    if ($numbers.Count -eq 0) {
        Write-Host ""
        Write-Host "    Invalid selection: $choice" -ForegroundColor Red
        Wait-ForChoco
        continue
    }

    foreach ($n in $numbers) {
        if ($appsByNumber.ContainsKey($n)) {
            $app = $appsByNumber[$n]
            Install-ById -Id $app.Id -Name $app.Name
        } else {
            Write-Host ""
            Write-Host "    [SKIP] Unknown option: $n" -ForegroundColor Yellow
            Write-Host ""
        }
    }

    Wait-ForChoco
}