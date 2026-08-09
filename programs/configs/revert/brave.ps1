# Script by PaladinXV

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Remove-RegValue {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$Name
    )

    try {
        if (Test-Path $Path) {
            Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Host "    [SKIP] Could not remove $Path\$Name : $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

$bravePolicyPath = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'

Remove-RegValue -Path $bravePolicyPath -Name 'BraveVPNDisabled'
Remove-RegValue -Path $bravePolicyPath -Name 'BraveWalletDisabled'
Remove-RegValue -Path $bravePolicyPath -Name 'BraveAIChatEnabled'
Remove-RegValue -Path $bravePolicyPath -Name 'BraveRewardsDisabled'
Remove-RegValue -Path $bravePolicyPath -Name 'BraveTalkDisabled'
Remove-RegValue -Path $bravePolicyPath -Name 'BraveNewsDisabled'
Remove-RegValue -Path $bravePolicyPath -Name 'BraveWebDiscoveryEnabled'
Remove-RegValue -Path $bravePolicyPath -Name 'BraveP3AEnabled'
Remove-RegValue -Path $bravePolicyPath -Name 'BraveStatsPingEnabled'
Remove-RegValue -Path $bravePolicyPath -Name 'BraveWaybackMachineEnabled'
Remove-RegValue -Path $bravePolicyPath -Name 'BravePlaylistEnabled'
Remove-RegValue -Path $bravePolicyPath -Name 'TorDisabled'

Write-Host "    - Brave config reverted." -ForegroundColor Green