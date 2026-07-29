# Script by PaladinXV

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Wait-ForWinget {
    Write-Host ""
    Write-Host "    Press Enter to continue " -ForegroundColor Yellow -NoNewline
    Read-Host | Out-Null
}

function Invoke-WingetWithSilentFallback {
    param(
        [Parameter(Mandatory)][ValidateSet('install','uninstall','upgrade')][string]$Command,
        [string]$Id,
        [switch]$All
    )

    $common = @('--source','winget')
    if ($Command -in @('install','upgrade')) {
        $common += @('--accept-package-agreements','--accept-source-agreements')
    }

    $wingetArgs = @($Command)
    if ($All) { $wingetArgs += '--all' }
    elseif ($Id) { $wingetArgs += @('--id',$Id,'-e') }
    $wingetArgs += $common
    $wingetArgs += '--silent'

    & winget @wingetArgs
    if ($LASTEXITCODE -eq 0) { return }

    Write-Host ""
    Write-Host "    Silent mode failed/unsupported. Retrying without --silent..." -ForegroundColor DarkYellow
    Write-Host ""

    $wingetArgsFallback = @($Command)
    if ($All) { $wingetArgsFallback += '--all' }
    elseif ($Id) { $wingetArgsFallback += @('--id',$Id,'-e') }
    $wingetArgsFallback += $common

    & winget @wingetArgsFallback
}

function Install-ById {
    param([Parameter(Mandatory)][string]$Id,[Parameter(Mandatory)][string]$Name)
    Invoke-WingetWithSilentFallback -Command install -Id $Id
}

function Update-All {
    Invoke-WingetWithSilentFallback -Command upgrade -All
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
        $headerWidth = $cat.Length
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
            $h = "$($card.Name)"

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
        @{ N=1; Name="Brave"; Id="Brave.Brave" },
        @{ N=2; Name="Chrome"; Id="Google.Chrome" },
        @{ N=3; Name="FireFox"; Id="Mozilla.Firefox" },
        @{ N=4; Name="Helium"; Id="ImputNet.Helium" },
        @{ N=5; Name="Librewolf"; Id="LibreWolf.LibreWolf" },
        @{ N=6; Name="Vivaldi"; Id="Vivaldi.Vivaldi" },
        @{ N=7; Name="Zen Browser"; Id="Zen-Team.Zen-Browser" }
    )
    "Communication" = @(
        @{ N=8; Name="Discord"; Id="Discord.Discord" },
        @{ N=9; Name="TeamSpeak"; Id="TeamSpeakSystems.TeamSpeakClient" }
    )
    "Documents" = @(
        @{ N=10; Name="LibreOffice"; Id="TheDocumentFoundation.LibreOffice" },
        @{ N=11; Name="Notepad++"; Id="Notepad++.Notepad++" },
        @{ N=12; Name="OpenOffice"; Id="Apache.OpenOffice" }
    )
    "Gaming" = @(
        @{ N=13; Name="EA App"; Id="ElectronicArts.EADesktop" },
        @{ N=14; Name="Epic Games Launcher"; Id="EpicGames.EpicGamesLauncher" },
        @{ N=15; Name="GOG Launcher"; Id="GOG.Galaxy" },
        @{ N=16; Name="Steam"; Id="Valve.Steam" }
    )
    "Multimedia" = @(
        @{ N=17; Name="Foobar2000"; Id="PeterPawlowski.foobar2000" },
        @{ N=18; Name="Handbrake"; Id="HandBrake.HandBrake" },
        @{ N=19; Name="iTunes"; Id="Apple.iTunes" },
        @{ N=20; Name="K-Lite Codec Standard"; Id="CodecGuide.K-LiteCodecPack.Standard" },
        @{ N=21; Name="OBS-Studio"; Id="OBSProject.OBSStudio" },
        @{ N=22; Name="VLC Media Player"; Id="VideoLAN.VLC" }
    )
    "Utilities" = @(
        @{ N=23; Name="7Zip"; Id="7zip.7zip" },
        @{ N=24; Name="Bitwarden"; Id="Bitwarden.Bitwarden" },
        @{ N=25; Name="CPU-Z"; Id="CPUID.CPU-Z" },
        @{ N=26; Name="Crystal Disk Info"; Id="CrystalDewWorld.CrystalDiskInfo" },
        @{ N=27; Name="Crystal Disk Mark"; Id="CrystalDewWorld.CrystalDiskMark" },
        @{ N=28; Name="Display Driver Uninstaller"; Id="Wagnardsoft.DisplayDriverUninstaller" },
        @{ N=29; Name="FanControl"; Id="Rem0o.FanControl" },
        @{ N=30; Name="GPU-Z"; Id="TechPowerUp.GPU-Z" },
        @{ N=31; Name="HWInfo"; Id="REALiX.HWiNFO" },
        @{ N=32; Name="HWMonitor"; Id="CPUID.HWMonitor" },
        @{ N=33; Name="MSI Afterburner"; Id="Guru3D.Afterburner" },
        @{ N=34; Name="Nanazip"; Id="M2Team.NanaZip" },
        @{ N=35; Name="Process Lasso"; Id="Bitsum.ProcessLasso" },
        @{ N=36; Name="qBitTorrent"; Id="qBittorrent.qBittorrent" },
        @{ N=37; Name="Visual C++ (2015+)"; Id="Microsoft.VCRedist.2015+.x64" }
    )
    "Windows UWP Apps" = @(
        @{ N=38; Name="Clipchamp"; Id="9P1J8S7CCWWT" },
        @{ N=39; Name="Copilot"; Id="XP9CXNGPPJ97XX" },
        @{ N=40; Name="Copilot - 365"; Id="9WZDNCRD29V9" },
        @{ N=41; Name="Feedback Hub"; Id="9NBLGGH4R32N" },
        @{ N=42; Name="Microsoft Teams"; Id="XP8BT8DW290MPQ" },
        @{ N=43; Name="OneDrive"; Id="Microsoft.OneDrive" },
        @{ N=44; Name="Outlook"; Id="9NRX63209R7B" },
        @{ N=45; Name="Power Automate"; Id="9NFTCH6J7FHV" },
        @{ N=46; Name="Quick Assist"; Id="9P7BP5VNWKX5" },
        @{ N=47; Name="Sound Recorder"; Id="9WZDNCRFHWKN" },
        @{ N=48; Name="Sticky Notes"; Id="9NBLGGH4QGHW" },
        @{ N=49; Name="Weather"; Id="9WZDNCRFJ3Q2" },
        @{ N=50; Name="Widgets"; Id="9MSSGKG348SP" },
        @{ N=51; Name="Windows Camera"; Id="9WZDNCRFJBBG" },
        @{ N=52; Name="Windows Clock"; Id="9WZDNCRFJ3PR" },
        @{ N=53; Name="Xbox App"; Id="9MV0B5HZVK9Z" }
    )
}

$appsByNumber = @{}
foreach ($cat in $catalog.Keys) {
    foreach ($app in $catalog[$cat]) {
        $appsByNumber[$app.N] = $app
    }
}

while ($true) {
    Clear-Host
    Write-Host ""
    Write-Host "    Simple Windows 11 Setup Script - By PaladinXV" -ForegroundColor Cyan
    Write-Host "    ---------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    Winget" -ForegroundColor Yellow
    Write-Host "    ----------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host '    Multi-Selection is available "1,2,5-8"' -ForegroundColor DarkGray
    Write-Host "    A) Update All" -ForegroundColor Yellow
    Write-Host "    I) Install Winget (Asheroto GitHub)" -ForegroundColor Yellow
    Write-Host "    0) Back" -ForegroundColor Red
    Write-Host ""

    Show-CatalogCardLayout -Catalog $catalog

    $choice = Read-Host "    Select option(s)"
    if ($choice -eq '0') { return }

    if ($choice -match '^[Aa]$') { Write-Host ""; Update-All; Wait-ForWinget; continue }

    if ($choice -match '^[Ii]$') {
        Start-Process powershell.exe -ArgumentList '-NoExit', '-Command', 'irm asheroto.com/winget | iex'
        continue
    }

    $numbers = @(Expand-Selection -InputText $choice)
    if ($numbers.Count -eq 0) {
        Write-Host ""
        Write-Host "    Invalid selection: $choice" -ForegroundColor Red
        Wait-ForWinget
        continue
    }

    Write-Host ""

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

    Wait-ForWinget
}