# Script by PaladinXV

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Wait-ForRevertUwp {
    Write-Host ""
    Read-Host "    Press Enter to continue" | Out-Null
}

function Invoke-WingetInstallWithSilentFallback {
    param(
        [Parameter(Mandatory)][string]$Id
    )

    $args = @(
        'install',
        '--id', $Id, '-e',
        '--source', 'msstore',
        '--accept-package-agreements',
        '--accept-source-agreements',
        '--silent'
    )

    & winget @args
    if ($LASTEXITCODE -eq 0) { return }

    Write-Host ""
    Write-Host "    Silent mode failed/unsupported. Retrying without --silent..." -ForegroundColor DarkYellow
    Write-Host ""

    $args2 = @(
        'install',
        '--id', $Id, '-e',
        '--source', 'msstore',
        '--accept-package-agreements',
        '--accept-source-agreements'
    )
    & winget @args2
}

function Install-ById {
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Name
    )

    Write-Host ""
    Write-Host "    Installing - $Name" -ForegroundColor Cyan
    Write-Host ""

    Invoke-WingetInstallWithSilentFallback -Id $Id

    if ($LASTEXITCODE -eq 0) {
        Write-Host "    [OK] $Name" -ForegroundColor Green
    } else {
        Write-Host "    [FAIL] $Name (Exit: $LASTEXITCODE)" -ForegroundColor Yellow
    }

    Write-Host ""
}

function Expand-Selection {
    param([Parameter(Mandatory)][string]$InputText)

    $result = New-Object System.Collections.Generic.List[int]

    foreach ($raw in ($InputText -split ',')) {
        $p = $raw.Trim()
        if (-not $p) { continue }

        if ($p -match '^\d+$') {
            $result.Add([int]$p)
            continue
        }

        if ($p -match '^(\d+)\s*-\s*(\d+)$') {
            $a = [int]$matches[1]
            $b = [int]$matches[2]
            if ($b -lt $a) { $t = $a; $a = $b; $b = $t }

            for ($i = $a; $i -le $b; $i++) {
                $result.Add($i)
            }
        }
    }

    $result | Sort-Object -Unique
}

function Show-UwpGrid {
    param(
        [Parameter(Mandatory)][array]$Items,
        [int]$PerRow = 1,
        [int]$CellWidth = 34
    )

    $i = 0
    foreach ($app in $Items) {
        $n = "{0})" -f $app.N
        $name = $app.Name
        $raw = "$n $name"

        Write-Host "    " -NoNewline
        Write-Host $n -ForegroundColor Cyan -NoNewline
        Write-Host (" " + $name) -ForegroundColor White -NoNewline

        $i++
        if (($i % $PerRow) -eq 0) {
            Write-Host ""
        }
        else {
            $pad = [Math]::Max($CellWidth - $raw.Length, 1)
            Write-Host (" " * $pad) -NoNewline
        }
    }

    if (($i % $PerRow) -ne 0) {
        Write-Host ""
    }
}

$apps = @(
    @{ N=1;  Name="Clipchamp";      Id="9P1J8S7CCWWT" },
    @{ N=2;  Name="Copilot";        Id="XP9CXNGPPJ97XX" },
    @{ N=3;  Name="Copilot - 365";  Id="9WZDNCRD29V9" },
    @{ N=4;  Name="Feedback Hub";   Id="9NBLGGH4R32N" },
    @{ N=5;  Name="Microsoft Teams";Id="XP8BT8DW290MPQ" },
    @{ N=6;  Name="Outlook";        Id="9NRX63209R7B" },
    @{ N=7;  Name="Power Automate"; Id="9NFTCH6J7FHV" },
    @{ N=8;  Name="Quick Assist";   Id="9P7BP5VNWKX5" },
    @{ N=9;  Name="Sound Recorder"; Id="9WZDNCRFHWKN" },
    @{ N=10; Name="Sticky Notes";   Id="9NBLGGH4QGHW" },
    @{ N=11; Name="Weather";        Id="9WZDNCRFJ3Q2" },
    @{ N=12; Name="Windows Camera"; Id="9WZDNCRFJBBG" },
    @{ N=13; Name="Windows Clock";  Id="9WZDNCRFJ3PR" },
    @{ N=14; Name="Xbox";           Id="9MV0B5HZVK9Z" },
    @{ N=15; Name="Widgets";        Id="9MSSGKG348SP" }
)

$appsByNumber = @{}
foreach ($app in $apps) {
    $appsByNumber[$app.N] = $app
}

while ($true) {
    Clear-Host
    Write-Host ""
    Write-Host "    Reinstall UWP Apps (Microsoft Store)" -ForegroundColor Cyan
    Write-Host "    ---------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host '    Multi-Selection is available "1,2,5-8"' -ForegroundColor DarkGray
    Write-Host "    A) Install All" -ForegroundColor Yellow
    Write-Host "    0) Back" -ForegroundColor Red
	Write-Host ""
	Write-Host "    Please note: This will download and install the full app package" 
    Write-Host ""

    Show-UwpGrid -Items $apps -PerRow 1 -CellWidth 34
    Write-Host ""

    $choice = Read-Host "    Select option(s)"
    if ($null -eq $choice) { continue }

    $choice = $choice.Trim()
    if ([string]::IsNullOrWhiteSpace($choice)) { continue }

    if ($choice -eq '0') { return }

    if ($choice -match '^[Aa]$') {
        foreach ($app in $apps) {
            Install-ById -Id $app.Id -Name $app.Name
        }
        Wait-ForRevertUwp
        continue
    }

    $numbers = @(Expand-Selection -InputText $choice)
    if ($numbers.Count -eq 0) {
        Write-Host ""
        Write-Host "    Invalid selection: $choice" -ForegroundColor Red
        Wait-ForRevertUwp
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

    Wait-ForRevertUwp
}