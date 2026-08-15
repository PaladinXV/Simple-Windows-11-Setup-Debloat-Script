# Script by PaladinXV

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

if (-not (Test-Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers')) {
    New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers' -Force | Out-Null
}
if (-not (Test-Path 'HKCU:\Control Panel\Desktop')) {
    New-Item -Path 'HKCU:\Control Panel\Desktop' -Force | Out-Null
}
if (-not (Test-Path 'HKCU:\Control Panel\Colors')) {
    New-Item -Path 'HKCU:\Control Panel\Colors' -Force | Out-Null
}

Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers' -Name 'BackgroundType' -Type DWord -Value 0
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'Wallpaper' -Type String -Value ''
Set-ItemProperty -Path 'HKCU:\Control Panel\Colors' -Name 'Background' -Type String -Value '0 0 0'

Start-Process -FilePath 'rundll32.exe' -ArgumentList 'user32.dll,UpdatePerUserSystemParameters' -Wait -NoNewWindow

Write-Host "    - Set Wallpaper." -ForegroundColor Green