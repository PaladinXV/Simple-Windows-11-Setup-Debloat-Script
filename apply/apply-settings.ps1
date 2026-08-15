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

function Set-RegDefaultValue {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] $Value
    )

    try {
        Initialize-RegistryKey -Path $Path
        Set-Item -Path $Path -Value $Value -Force
    }
    catch {
        Write-Host "    [SKIP] Could not set default value at $Path : $($_.Exception.Message)" -ForegroundColor Yellow
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

            $details = @()
            if ($stdout) { $details += "STDOUT: $stdout" }
            if ($stderr) { $details += "STDERR: $stderr" }

            if ($details.Count -gt 0) {
                throw "Command failed: $FilePath exited with code $($process.ExitCode)`n$($details -join "`n")"
            } else {
                throw "Command failed: $FilePath exited with code $($process.ExitCode)"
            }
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
    try {
        $script:ProgressRow = $host.UI.RawUI.CursorPosition.Y - 1
    } catch {
        $script:ProgressRow = -1
    }
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
        if ($line.Length -lt ($width - 1)) {
            $line = $line.PadRight($width - 1)
        }

        if ($script:ProgressRow -ge 0) {
            $raw.CursorPosition = New-Object System.Management.Automation.Host.Coordinates(0, $script:ProgressRow)
            Write-Host $line -NoNewline -ForegroundColor Cyan
            $raw.CursorPosition = $saved
        } else {
            Write-Host ("`r" + $line) -NoNewline -ForegroundColor Cyan
        }
    }
    catch {
        Write-Host ("`r" + $line) -NoNewline -ForegroundColor Cyan
    }
}

function Step-Bar {
    param(
        [Parameter(Mandatory)] [string]$Status,
        [switch]$Delay
    )

    if ($script:ProgressIndex -lt $script:ProgressTotal) {
        $script:ProgressIndex++
    }

    Update-Bar -Status $Status
    if ($Delay) { Start-Sleep -Milliseconds 250 }
}

function Complete-Bar {
    Write-Host ""
}

$script:HadFatalError = $false

try {
    $totalSteps = 15
    Initialize-Bar -Total $totalSteps

    Step-Bar -Status 'Configuring - Edge' -Delay
    $edgePolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
    Set-RegValue -Path $edgePolicyPath -Name 'HideFirstRunExperience' -Value 1 -Type DWord
    Set-RegValue -Path $edgePolicyPath -Name 'StartupBoostEnabled' -Value 0 -Type DWord
    Set-RegValue -Path $edgePolicyPath -Name 'BackgroundModeEnabled' -Value 0 -Type DWord
    if (Test-Path "$env:PUBLIC\Desktop\Microsoft Edge.lnk") { Remove-Item "$env:PUBLIC\Desktop\Microsoft Edge.lnk" -Force -ErrorAction SilentlyContinue }
    if (Test-Path "$env:USERPROFILE\Desktop\Microsoft Edge.lnk") { Remove-Item "$env:USERPROFILE\Desktop\Microsoft Edge.lnk" -Force -ErrorAction SilentlyContinue }

    Step-Bar -Status 'Configuring - Folder Options' -Delay
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'LaunchTo' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'ShowRecent' -Value 0 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'ShowFrequent' -Value 0 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'ShowCloudFilesInQuickAccess' -Value 0 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'HideFileExt' -Value 0 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'UseCompactMode' -Value 1 -Type DWord

    Step-Bar -Status 'Configuring - Mouse Acceleration' -Delay
    Set-RegValue -Path 'HKCU:\Control Panel\Mouse' -Name 'MouseSpeed' -Value '0' -Type String
    Set-RegValue -Path 'HKCU:\Control Panel\Mouse' -Name 'MouseThreshold1' -Value '0' -Type String
    Set-RegValue -Path 'HKCU:\Control Panel\Mouse' -Name 'MouseThreshold2' -Value '0' -Type String

    Step-Bar -Status 'Configuring - Power Settings' -Delay
    Invoke-External -FilePath 'powercfg.exe' -Arguments '/change','monitor-timeout-dc','15'
    Invoke-External -FilePath 'powercfg.exe' -Arguments '/change','monitor-timeout-ac','15'
    Invoke-External -FilePath 'powercfg.exe' -Arguments '/change','standby-timeout-dc','0'
    Invoke-External -FilePath 'powercfg.exe' -Arguments '/change','standby-timeout-ac','0'
    Set-RegValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name 'HiberbootEnabled' -Value 0 -Type DWord
    Invoke-External -FilePath 'powercfg.exe' -Arguments '/hibernate','off'
    Invoke-External -FilePath 'powercfg.exe' -Arguments '-duplicatescheme','e9a42b02-d5df-448d-aa00-03f14749eb61' -IgnoreExitCode

    Step-Bar -Status 'Configuring - Windows Update Delay' -Delay
    $wuPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
    Set-RegValue -Path $wuPolicyPath -Name 'DeferFeatureUpdates' -Value 1 -Type DWord
    Set-RegValue -Path $wuPolicyPath -Name 'DeferFeatureUpdatesPeriodInDays' -Value 120 -Type DWord
    Set-RegValue -Path $wuPolicyPath -Name 'DeferQualityUpdates' -Value 1 -Type DWord
    Set-RegValue -Path $wuPolicyPath -Name 'DeferQualityUpdatesPeriodInDays' -Value 4 -Type DWord

    Step-Bar -Status 'Configuring - Sound Settings' -Delay
    Set-RegValue -Path 'HKCU:\Software\Microsoft\Multimedia\Audio' -Name 'UserDuckingPreference' -Value 3 -Type DWord

    Step-Bar -Status 'Configuring - System Settings' -Delay
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement' -Name 'ScoobeSystemSettingEnabled' -Value 0 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy' -Name '01' -Value 0 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'MultiTaskingAltTabFilter' -Value 3 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings' -Name 'TaskbarEndTask' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel' -Name '{2cc5ca98-6485-489a-920e-b3e88a6ccce3}' -Value 1 -Type DWord

    Step-Bar -Status 'Configuring - Content Delivery' -Delay
    $cdmPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
    Set-RegValue -Path $cdmPath -Name 'ContentDeliveryAllowed' -Value 0 -Type DWord
    Set-RegValue -Path $cdmPath -Name 'FeatureManagementEnabled' -Value 0 -Type DWord
    Set-RegValue -Path $cdmPath -Name 'SubscribedContentEnabled' -Value 0 -Type DWord
    Set-RegValue -Path $cdmPath -Name 'PreInstalledAppsEnabled' -Value 0 -Type DWord
    Set-RegValue -Path $cdmPath -Name 'PreInstalledAppsEverEnabled' -Value 0 -Type DWord
    Set-RegValue -Path $cdmPath -Name 'SilentInstalledAppsEnabled' -Value 0 -Type DWord
    Set-RegValue -Path $cdmPath -Name 'SoftLandingEnabled' -Value 0 -Type DWord
    Set-RegValue -Path $cdmPath -Name 'SystemPaneSuggestionsEnabled' -Value 0 -Type DWord
    Set-RegValue -Path $cdmPath -Name 'SubscribedContent-338388Enabled' -Value 0 -Type DWord
    Set-RegValue -Path $cdmPath -Name 'SubscribedContent-338389Enabled' -Value 0 -Type DWord
    Set-RegValue -Path $cdmPath -Name 'SubscribedContent-310093Enabled' -Value 0 -Type DWord
    Set-RegValue -Path $cdmPath -Name 'SubscribedContent-338387Enabled' -Value 0 -Type DWord
    Set-RegValue -Path $cdmPath -Name 'SubscribedContent-338393Enabled' -Value 0 -Type DWord
    Set-RegValue -Path $cdmPath -Name 'SubscribedContent-353694Enabled' -Value 0 -Type DWord
    Set-RegValue -Path $cdmPath -Name 'SubscribedContent-353696Enabled' -Value 0 -Type DWord
    Set-RegValue -Path $cdmPath -Name 'SubscribedContent-353698Enabled' -Value 0 -Type DWord
    Set-RegValue -Path $cdmPath -Name 'SubscribedContent-314563Enabled' -Value 0 -Type DWord
    Set-RegValue -Path $cdmPath -Name 'SubscribedContent-353699Enabled' -Value 0 -Type DWord

    $cloudContentPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'
    Set-RegValue -Path $cloudContentPolicyPath -Name 'DisableWindowsConsumerFeatures' -Value 1 -Type DWord
    Set-RegValue -Path $cloudContentPolicyPath -Name 'DisableConsumerAccountStateContent' -Value 1 -Type DWord
    Set-RegValue -Path $cloudContentPolicyPath -Name 'DisableCloudOptimizedContent' -Value 1 -Type DWord

    Step-Bar -Status 'Configuring - Dark Theme' -Delay
    Set-RegValue -Path $cdmPath -Name 'RotatingLockScreenEnabled' -Value 0 -Type DWord
    Set-RegValue -Path $cdmPath -Name 'RotatingLockScreenOverlayEnabled' -Value 0 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableSpotlightCollectionOnDesktop' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableWindowsSpotlightFeatures' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'SystemUsesLightTheme' -Value 0 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'AppsUseLightTheme' -Value 0 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'EnableTransparency' -Value 0 -Type DWord
    Set-RegValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'DisableLogonBackgroundImage' -Value 1 -Type DWord

    Step-Bar -Status 'Configuring - Start Menu' -Delay
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Start' -Name 'ShowRecentList' -Value 0 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Start_TrackDocs' -Value 0 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Start_IrisRecommendations' -Value 0 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Start_AccountNotifications' -Value 0 -Type DWord
    Set-RegValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Start' -Name 'AllAppsViewMode' -Value 2 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'HideRecommendedSection' -Value 1 -Type DWord
    Set-RegValue -Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start' -Name 'ConfigureStartPins' -Value '{"pinnedList":[]}' -Type String

    $startMenuHost = Get-Process -Name 'StartMenuExperienceHost' -ErrorAction SilentlyContinue
    if ($startMenuHost) {
        $startMenuHost | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
    }

    $startHostLocalState = "$env:LOCALAPPDATA\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState"
    if (Test-Path $startHostLocalState) {
        Get-ChildItem -Path $startHostLocalState -Filter 'start*.bin' -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
        }
    }

    $shellHostLocalState = "$env:LOCALAPPDATA\Packages\Microsoft.Windows.ShellExperienceHost_cw5n1h2txyewy\LocalState"
    if (Test-Path $shellHostLocalState) {
        Get-ChildItem -Path $shellHostLocalState -Filter '*start*' -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-Item $_.FullName -Force -Recurse -ErrorAction SilentlyContinue
        }
    }

    Step-Bar -Status 'Configuring - Task Bar' -Delay
    Set-RegValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarAl' -Value 0 -Type DWord
    Set-RegValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowTaskViewButton' -Value 0 -Type DWord
    Set-RegValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'SearchboxTaskbarMode' -Value 0 -Type DWord

    try {
        $pinnedNamespace = 'shell:::{4234d49b-0245-4df3-b780-3893943456e1}'
        $shell = New-Object -ComObject Shell.Application
        $folder = $shell.Namespace($pinnedNamespace)

        foreach ($item in $folder.Items()) {
            if ($item.Name -eq 'Microsoft Edge' -or $item.Name -eq 'Microsoft Store') {
                foreach ($verb in $item.Verbs()) {
                    $normalized = $verb.Name.Replace('&', '').Trim()
                    if ($normalized -match 'Unpin from taskbar') {
                        $verb.DoIt()
                    }
                }
            }
        }
    }
    catch {}

    Step-Bar -Status 'Configuring - Remote Connection' -Delay
    Set-RegValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value 1 -Type DWord
    Set-RegValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'UserAuthentication' -Value 1 -Type DWord

    $oldProgressPreference = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    try { Disable-NetFirewallRule -DisplayGroup 'Remote Desktop' -ErrorAction SilentlyContinue } catch {}
    $ProgressPreference = $oldProgressPreference

    try { Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'fAllowToGetHelp' -ErrorAction SilentlyContinue } catch {}
    try { Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'fAllowUnsolicited' -ErrorAction SilentlyContinue } catch {}
    Set-RegValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance' -Name 'fAllowToGetHelp' -Value 0 -Type DWord

    Step-Bar -Status 'Configuring - Privacy & Misc. Settings' -Delay
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\GameBar' -Name 'UseNexusForGameBarEnabled' -Value 0 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR' -Name 'AppCaptureEnabled' -Value 0 -Type DWord
    Set-RegValue -Path 'HKCU:\Control Panel\Accessibility\StickyKeys' -Name 'Flags' -Value '506' -Type String
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo' -Name 'Enabled' -Value 0 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CPSS\Store\AdvertisingInfo' -Name 'Value' -Value 0 -Type DWord
    Set-RegValue -Path 'HKCU:\Control Panel\International\User Profile' -Name 'HttpAcceptLanguageOptOut' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Start_TrackProgs' -Value 0 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings' -Name 'IsMSACloudSearchEnabled' -Value 0 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings' -Name 'IsAADCloudSearchEnabled' -Value 0 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy' -Name 'TailoredExperiencesWithDiagnosticDataEnabled' -Value 0 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' -Name 'HasAccepted' -Value 0 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\InputPersonalization' -Name 'RestrictImplicitInkCollection' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\InputPersonalization' -Name 'RestrictImplicitTextCollection' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore' -Name 'HarvestContacts' -Value 0 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Personalization\Settings' -Name 'AcceptedPrivacyPolicy' -Value 0 -Type DWord
    Set-RegValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -Value 0 -Type DWord
    Set-RegValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\dmwappushservice' -Name 'Start' -Value 4 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CPSS\Store' -Name 'ImproveInkingAndTypingRecognition' -Value 0 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Siuf\Rules' -Name 'NumberOfSIUFInPeriod' -Value 0 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Siuf\Rules' -Name 'PeriodInNanoSeconds' -Value 0 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings' -Name 'IsDeviceSearchHistoryEnabled' -Value 0 -Type DWord
    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings' -Name 'IsDynamicSearchBoxEnabled' -Value 0 -Type DWord
    Set-RegValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'DisableSearchBoxSuggestions' -Value 1 -Type DWord
    Set-RegValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config' -Name 'DODownloadMode' -Value 0 -Type DWord
    Set-RegValue -Path 'HKCU:\Software\Microsoft\Input\TIPC' -Name 'Enabled' -Value 0 -Type DWord
    Set-RegValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'PublishUserActivities' -Value 0 -Type DWord
    Set-RegValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'EnableActivityFeed' -Value 0 -Type DWord
    Set-RegValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'UploadUserActivities' -Value 0 -Type DWord
    Set-RegValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'DisableAutomaticRestartSignOn' -Value 1 -Type DWord
    Set-RegDefaultValue -Path 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' -Value ''
    Set-RegValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' -Name 'TurnOffWindowsCopilot' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager' -Name 'EnthusiastMode' -Value 1 -Type DWord
    Set-RegValue -Path 'HKCU:\Control Panel\Desktop' -Name 'MenuShowDelay' -Value '0' -Type String

    $recallFeature = Get-WindowsOptionalFeature -Online -ErrorAction SilentlyContinue | Where-Object {
        $_.State -eq 'Enabled' -and $_.FeatureName -like 'Recall'
    }
    if ($recallFeature) {
        Disable-WindowsOptionalFeature -Online -FeatureName 'Recall' -Remove -ErrorAction SilentlyContinue | Out-Null
    }

    Step-Bar -Status 'Configuring - Defender / VBS' -Delay
    try { Set-MpPreference -SubmitSamplesConsent 2 } catch {}
    Set-RegValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy' -Name 'VerifiedAndReputablePolicyState' -Value 0 -Type DWord
    Set-RegValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' -Name 'Enabled' -Value 0 -Type DWord
    Set-RegValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard' -Name 'EnableVirtualizationBasedSecurity' -Value 0 -Type DWord
    Invoke-External -FilePath 'bcdedit.exe' -Arguments '/set','hypervisorlaunchtype','off'

    Step-Bar -Status 'Done!'
    Complete-Bar
}
catch {
    $script:HadFatalError = $true
    Write-Host ""
    Write-Host "    FATAL ERROR: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    if ($script:HadFatalError) {
        Write-Host "    - Apply Settings completed with errors." -ForegroundColor Yellow
    } else {
        Write-Host "    - Apply Settings Complete." -ForegroundColor Green
    }
}
