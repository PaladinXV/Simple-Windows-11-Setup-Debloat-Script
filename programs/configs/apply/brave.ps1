# Script by PaladinXV

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Initialize-RegistryKey {
    param([Parameter(Mandatory)] [string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
}

function Set-RegValue {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$Name,
        [Parameter(Mandatory)] $Value,
        [ValidateSet('String','ExpandString','Binary','DWord','MultiString','QWord')]
        [string]$Type = 'String'
    )

    try {
        Initialize-RegistryKey -Path $Path
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
    }
    catch {
        Write-Host "    [SKIP] Could not set $Path\$Name : $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

$bravePolicyPath = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'

Set-RegValue -Path $bravePolicyPath -Name 'BraveVPNDisabled'         -Value 1 -Type DWord
Set-RegValue -Path $bravePolicyPath -Name 'BraveWalletDisabled'      -Value 1 -Type DWord
Set-RegValue -Path $bravePolicyPath -Name 'BraveAIChatEnabled'       -Value 0 -Type DWord
Set-RegValue -Path $bravePolicyPath -Name 'BraveRewardsDisabled'     -Value 1 -Type DWord
Set-RegValue -Path $bravePolicyPath -Name 'BraveTalkDisabled'        -Value 1 -Type DWord
Set-RegValue -Path $bravePolicyPath -Name 'BraveNewsDisabled'        -Value 1 -Type DWord
Set-RegValue -Path $bravePolicyPath -Name 'BraveWebDiscoveryEnabled' -Value 0 -Type DWord
Set-RegValue -Path $bravePolicyPath -Name 'BraveP3AEnabled'          -Value 0 -Type DWord
Set-RegValue -Path $bravePolicyPath -Name 'BraveStatsPingEnabled'    -Value 0 -Type DWord
Set-RegValue -Path $bravePolicyPath -Name 'BraveWaybackMachineEnabled' -Value 0 -Type DWord
Set-RegValue -Path $bravePolicyPath -Name 'BravePlaylistEnabled'     -Value 0 -Type DWord
Set-RegValue -Path $bravePolicyPath -Name 'TorDisabled'              -Value 1 -Type DWord

Write-Host "    - Brave config applied." -ForegroundColor Green