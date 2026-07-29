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
    Initialize-RegistryKey -Path $Path
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

function Remove-RegValue {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$Name
    )
    if (Test-Path $Path) {
        Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
    }
}

function Invoke-External {
    param(
        [Parameter(Mandatory)] [string]$FilePath,
        [string[]]$Arguments = @(),
        [switch]$IgnoreExitCode
    )

    $stdoutFile = [System.IO.Path]::GetTempFileName()
    $stderrFile = [System.IO.Path]::GetTempFileName()

    try {
        $process = Start-Process -FilePath $FilePath `
            -ArgumentList $Arguments `
            -Wait `
            -PassThru `
            -NoNewWindow `
            -RedirectStandardOutput $stdoutFile `
            -RedirectStandardError $stderrFile

        if (-not $IgnoreExitCode -and $process.ExitCode -ne 0) {
            $stdout = Get-Content -Path $stdoutFile -Raw -ErrorAction SilentlyContinue
            $stderr = Get-Content -Path $stderrFile -Raw -ErrorAction SilentlyContinue
            throw "Command failed: $FilePath exited with code $($process.ExitCode)`nSTDOUT: $stdout`nSTDERR: $stderr"
        }
    }
    finally {
        Remove-Item $stdoutFile -Force -ErrorAction SilentlyContinue
        Remove-Item $stderrFile -Force -ErrorAction SilentlyContinue
    }
}

# Progress Bar
$script:ProgressIndex = 0
$script:ProgressTotal = 1
$script:ProgressBarWidth = 40
$script:ProgressRow = -1

function Initialize-Bar {
    param([Parameter(Mandatory)] [int]$Total)
    $script:ProgressIndex = 0
    $script:ProgressTotal = [Math]::Max($Total, 1)
    Write-Host ""
    try { $script:ProgressRow = $host.UI.RawUI.CursorPosition.Y - 1 } catch { $script:ProgressRow = -1 }
}

function Update-Bar {
    param([Parameter(Mandatory)] [string]$Status)

    $percent = [int][Math]::Round(($script:ProgressIndex / $script:ProgressTotal) * 100)
    if ($percent -gt 100) { $percent = 100 }

    $filled = [int][Math]::Round(($percent / 100) * $script:ProgressBarWidth)
    if ($filled -gt $script:ProgressBarWidth) { $filled = $script:ProgressBarWidth }

    $empty = $script:ProgressBarWidth - $filled
    $bar = ('#' * $filled) + ('-' * $empty)
    $line = ("    [{0}] {1,3}%  - {2}" -f $bar, $percent, $Status)

    try {
        $raw = $host.UI.RawUI
        $saved = $raw.CursorPosition
        $width = $raw.BufferSize.Width
        if ($line.Length -lt ($width - 1)) { $line = $line.PadRight($width - 1) }

        if ($script:ProgressRow -ge 0) {
            $raw.CursorPosition = New-Object System.Management.Automation.Host.Coordinates(0, $script:ProgressRow)
            Write-Host $line -NoNewline -ForegroundColor Cyan
            $raw.CursorPosition = $saved
        } else {
            Write-Host ("`r" + $line) -NoNewline -ForegroundColor Cyan
        }
    } catch {
        Write-Host ("`r" + $line) -NoNewline -ForegroundColor Cyan
    }
}

function Step-Bar {
    param([Parameter(Mandatory)] [string]$Status, [switch]$Delay)
    if ($script:ProgressIndex -lt $script:ProgressTotal) { $script:ProgressIndex++ }
    Update-Bar -Status $Status
    if ($Delay) { Start-Sleep -Milliseconds 250 }
}

function Complete-Bar {
    Write-Host ""
    Write-Host ""
}

$script:HadFatalError = $false

try {
    $totalSteps = 15
    Initialize-Bar -Total $totalSteps

    Step-Bar -Status 'Reverting - Edge' -Delay
    Remove-RegValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'HideFirstRunExperience'
    Remove-RegValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'StartupBoostEnabled'
    Remove-RegValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'BackgroundModeEnabled'

    Step-Bar -Status 'Reverting - Folder Options' -Delay
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'LaunchTo' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'ShowRecent' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'ShowFrequent' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'ShowCloudFilesInQuickAccess' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'HideFileExt' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'UseCompactMode' -Value 0 -Type DWord

    Step-Bar -Status 'Reverting - Mouse Acceleration' -Delay
    Set-RegValue -Path 'HKCU:\Control Panel\Mouse' -Name 'MouseSpeed' -Value '1' -Type String
    Set-RegValue -Path 'HKCU:\Control Panel\Mouse' -Name 'MouseThreshold1' -Value '6' -Type String
    Set-RegValue -Path 'HKCU:\Control Panel\Mouse' -Name 'MouseThreshold2' -Value '10' -Type String

    Step-Bar -Status 'Reverting - Power Settings' -Delay
    Invoke-External -FilePath 'powercfg.exe' -Arguments '/change','monitor-timeout-dc','5' -IgnoreExitCode
    Invoke-External -FilePath 'powercfg.exe' -Arguments '/change','monitor-timeout-ac','10' -IgnoreExitCode
    Invoke-External -FilePath 'powercfg.exe' -Arguments '/change','standby-timeout-dc','15' -IgnoreExitCode
    Invoke-External -FilePath 'powercfg.exe' -Arguments '/change','standby-timeout-ac','30' -IgnoreExitCode
    Set-RegValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name 'HiberbootEnabled' -Value 1 -Type DWord
    Invoke-External -FilePath 'powercfg.exe' -Arguments '/hibernate','on' -IgnoreExitCode

    Step-Bar -Status 'Reverting - Windows Update Delay' -Delay
    Remove-RegValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name 'DeferFeatureUpdates'
    Remove-RegValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name 'DeferFeatureUpdatesPeriodInDays'
    Remove-RegValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name 'DeferQualityUpdates'
    Remove-RegValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name 'DeferQualityUpdatesPeriodInDays'

    Step-Bar -Status 'Reverting - Sound Settings' -Delay
    Set-RegValue -Path 'HKCU:\Software\Microsoft\Multimedia\Audio' -Name 'UserDuckingPreference' -Value 0 -Type DWord

    Step-Bar -Status 'Reverting - System Settings' -Delay
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement' -Name 'ScoobeSystemSettingEnabled' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy' -Name '01' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'MultiTaskingAltTabFilter' -Value 1 -Type DWord
    Remove-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings' -Name 'TaskbarEndTask'
    Remove-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel' -Name '{2cc5ca98-6485-489a-920e-b3e88a6ccce3}'

    Step-Bar -Status 'Reverting - Content Delivery' -Delay
    $cdm = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
    Set-RegValue -Path $cdm -Name 'ContentDeliveryAllowed' -Value 1 -Type DWord
    Set-RegValue -Path $cdm -Name 'FeatureManagementEnabled' -Value 1 -Type DWord
    Set-RegValue -Path $cdm -Name 'SubscribedContentEnabled' -Value 1 -Type DWord
    Set-RegValue -Path $cdm -Name 'PreInstalledAppsEnabled' -Value 1 -Type DWord
    Set-RegValue -Path $cdm -Name 'PreInstalledAppsEverEnabled' -Value 1 -Type DWord
    Set-RegValue -Path $cdm -Name 'SilentInstalledAppsEnabled' -Value 1 -Type DWord
    Set-RegValue -Path $cdm -Name 'SoftLandingEnabled' -Value 1 -Type DWord
    Set-RegValue -Path $cdm -Name 'SystemPaneSuggestionsEnabled' -Value 1 -Type DWord

    $subscribedKeys = @(
        'SubscribedContent-338388Enabled','SubscribedContent-338389Enabled','SubscribedContent-310093Enabled',
        'SubscribedContent-338387Enabled','SubscribedContent-338393Enabled','SubscribedContent-353694Enabled',
        'SubscribedContent-353696Enabled','SubscribedContent-353698Enabled','SubscribedContent-314563Enabled',
        'SubscribedContent-353699Enabled'
    )
    foreach ($k in $subscribedKeys) { Set-RegValue -Path $cdm -Name $k -Value 1 -Type DWord }

    Remove-RegValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableWindowsConsumerFeatures'
    Remove-RegValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableConsumerAccountStateContent'
    Remove-RegValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableCloudOptimizedContent'

    Step-Bar -Status 'Reverting - Theme' -Delay
    Set-RegValue -Path $cdm -Name 'RotatingLockScreenEnabled' -Value 1 -Type DWord
    Set-RegValue -Path $cdm -Name 'RotatingLockScreenOverlayEnabled' -Value 1 -Type DWord
    Remove-RegValue -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableSpotlightCollectionOnDesktop'
    Remove-RegValue -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableWindowsSpotlightFeatures'
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'SystemUsesLightTheme' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'AppsUseLightTheme' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'EnableTransparency' -Value 1 -Type DWord
    Remove-RegValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'DisableLogonBackgroundImage'

    Step-Bar -Status 'Reverting - Start Menu' -Delay
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Start' -Name 'ShowRecentList' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Start_TrackDocs' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Start_IrisRecommendations' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Start_AccountNotifications' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Start' -Name 'AllAppsViewMode' -Value 0 -Type DWord
    Remove-RegValue -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'HideRecommendedSection'
    Remove-RegValue -Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start' -Name 'ConfigureStartPins'

    Step-Bar -Status 'Reverting - Task Bar' -Delay
    Set-RegValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarAl' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowTaskViewButton' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'SearchboxTaskbarMode' -Value 2 -Type DWord
    Remove-RegValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' -Name 'AllowNewsAndInterests'

    Step-Bar -Status 'Reverting - Remote Connection' -Delay
    Set-RegValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value 0 -Type DWord
    Remove-RegValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'UserAuthentication'
    try { Enable-NetFirewallRule -DisplayGroup 'Remote Desktop' -ErrorAction SilentlyContinue } catch {}
    Remove-RegValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance' -Name 'fAllowToGetHelp'

    Step-Bar -Status 'Reverting - Privacy & Misc. Settings' -Delay
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\GameBar' -Name 'UseNexusForGameBarEnabled' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR' -Name 'AppCaptureEnabled' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\Control Panel\Accessibility\StickyKeys' -Name 'Flags' -Value '510' -Type String
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo' -Name 'Enabled' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CPSS\Store\AdvertisingInfo' -Name 'Value' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\Control Panel\International\User Profile' -Name 'HttpAcceptLanguageOptOut' -Value 0 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Start_TrackProgs' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings' -Name 'IsMSACloudSearchEnabled' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings' -Name 'IsAADCloudSearchEnabled' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy' -Name 'TailoredExperiencesWithDiagnosticDataEnabled' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' -Name 'HasAccepted' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\InputPersonalization' -Name 'RestrictImplicitInkCollection' -Value 0 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\InputPersonalization' -Name 'RestrictImplicitTextCollection' -Value 0 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore' -Name 'HarvestContacts' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Personalization\Settings' -Name 'AcceptedPrivacyPolicy' -Value 1 -Type DWord
    Remove-RegValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry'
    Set-RegValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\dmwappushservice' -Name 'Start' -Value 3 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CPSS\Store' -Name 'ImproveInkingAndTypingRecognition' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Siuf\Rules' -Name 'NumberOfSIUFInPeriod' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Siuf\Rules' -Name 'PeriodInNanoSeconds' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings' -Name 'IsDeviceSearchHistoryEnabled' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings' -Name 'IsDynamicSearchBoxEnabled' -Value 1 -Type DWord
    Remove-RegValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'DisableSearchBoxSuggestions'
    Set-RegValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config' -Name 'DODownloadMode' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\Software\Microsoft\Input\TIPC' -Name 'Enabled' -Value 1 -Type DWord
    Remove-RegValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'PublishUserActivities'
    Remove-RegValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'EnableActivityFeed'
    Remove-RegValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'UploadUserActivities'
    Remove-RegValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'DisableAutomaticRestartSignOn'
    Remove-Item -Path 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}' -Recurse -Force -ErrorAction SilentlyContinue
    Remove-RegValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' -Name 'TurnOffWindowsCopilot'
    Remove-RegValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager' -Name 'EnthusiastMode'
    Set-RegValue -Path 'HKCU:\Control Panel\Desktop' -Name 'MenuShowDelay' -Value '400' -Type String

    Step-Bar -Status 'Reverting - Defender / VBS' -Delay
    Remove-RegValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy' -Name 'VerifiedAndReputablePolicyState'
    Set-RegValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' -Name 'Enabled' -Value 1 -Type DWord
    Set-RegValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard' -Name 'EnableVirtualizationBasedSecurity' -Value 1 -Type DWord
    Invoke-External -FilePath 'bcdedit.exe' -Arguments '/set','hypervisorlaunchtype','auto' -IgnoreExitCode

    Step-Bar -Status 'Done!' -Delay
    Complete-Bar
}
catch {
    $script:HadFatalError = $true
    Write-Host ""
    Write-Host "    FATAL ERROR: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    if ($script:HadFatalError) {
        Write-Host "    - Revert Settings completed with errors." -ForegroundColor Yellow
    } else {
        Write-Host "    - Revert Settings Complete." -ForegroundColor Green
    }
}