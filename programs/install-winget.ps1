# Script by PaladinXV

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Test-WingetInstalled {
    return [bool](Get-Command winget.exe -ErrorAction SilentlyContinue)
}

if (Test-WingetInstalled) {
    Write-Host "    - Winget is already installed." -ForegroundColor Green
    return
}

Write-Host "    - Winget not found. Installing from Microsoft's official winget-cli releases..." -ForegroundColor Yellow

try {
    $arch = switch ($env:PROCESSOR_ARCHITECTURE) {
        'ARM64'  { 'arm64' }
        'AMD64'  { 'x64' }
        default  { 'x64' }
    }

    $workDir = Join-Path $env:TEMP "winget-install-$([guid]::NewGuid())"
    New-Item -ItemType Directory -Path $workDir -Force | Out-Null

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        Write-Host "    - Checking latest winget-cli release..." -ForegroundColor Cyan
        $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/microsoft/winget-cli/releases/latest'

        $msixBundleAsset = $release.assets | Where-Object { $_.name -eq 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle' } | Select-Object -First 1
        $dependenciesAsset = $release.assets | Where-Object { $_.name -eq 'DesktopAppInstaller_Dependencies.zip' } | Select-Object -First 1
        $licenseAsset = $release.assets | Where-Object { $_.name -like '*_License1.xml' } | Select-Object -First 1

        if (-not $msixBundleAsset -or -not $dependenciesAsset -or -not $licenseAsset) {
            throw "Could not find all required assets in the latest winget-cli release."
        }

        $msixBundlePath = Join-Path $workDir $msixBundleAsset.name
        $dependenciesZipPath = Join-Path $workDir $dependenciesAsset.name
        $licensePath = Join-Path $workDir $licenseAsset.name

        Write-Host "    - Downloading dependencies..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $dependenciesAsset.browser_download_url -OutFile $dependenciesZipPath -UseBasicParsing

        Write-Host "    - Downloading Winget package..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $msixBundleAsset.browser_download_url -OutFile $msixBundlePath -UseBasicParsing
        Invoke-WebRequest -Uri $licenseAsset.browser_download_url -OutFile $licensePath -UseBasicParsing

        $depsExtractPath = Join-Path $workDir 'Dependencies'
        Expand-Archive -Path $dependenciesZipPath -DestinationPath $depsExtractPath -Force

        $archFolder = Join-Path $depsExtractPath $arch
        if (-not (Test-Path $archFolder)) {
            throw "Dependencies folder for architecture '$arch' was not found in the downloaded package."
        }

        Write-Host "    - Installing dependencies..." -ForegroundColor Cyan
        Get-ChildItem -Path $archFolder -Filter '*.appx' | ForEach-Object {
            try {
                Add-AppxPackage -Path $_.FullName -ErrorAction Stop
            }
            catch {
                # Dependencies may already be present at an equal/newer version; safe to continue.
                Write-Host "    [SKIP] $($_.Name): $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }

        Write-Host "    - Installing Winget..." -ForegroundColor Cyan
        Add-AppxPackage -Path $msixBundlePath -LicensePath $licensePath

        if (Test-WingetInstalled) {
            Write-Host "    - Winget installed successfully." -ForegroundColor Green
        }
        else {
            Write-Host "    - Install completed, but winget.exe was not found on PATH. You may need to restart your terminal or sign out/in." -ForegroundColor Yellow
        }
    }
    finally {
        Remove-Item -Path $workDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Host "    ERROR: $($_.Exception.Message)" -ForegroundColor Red
}
