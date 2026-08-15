# Simple Windows 11 25H2 Setup Script
A simple, interactive PowerShell script to help setup/debloat Windows for a better experience.

# Features
- Sets good defaults for a better experience (ie Folder Options, Immersive Control Panel settings) without breaking functionality.
- Removes pre-installed UWP apps/shortcuts (ie OneDrive, Copilot, Xbox).
- Able to revert most settings manually, or sepererately revert some that might not want to be changed.
- Setup for Windows 11 25H2, Windows 10 LTSC IoT 2021 and Windows 11 LTSC IoT 2024.

# Warning
> [!Warning]
> Please use at your own risk. If you use Microsoft Apps, select the "Settings only" option.

# Known Issues
- Widget registry key blocked with latest Windows updated. Testing package removal instead.

# Documentation
- I am currently working on documenting all changes and features.
[Documentation](https://github.com/PaladinXV/Simple-Windows-11-Setup-Debloat-Script/blob/main/documentation.md)

# How To Use
Open PowerShell or Terminal and Copy + Paste the link below.

```
Set-ExecutionPolicy Bypass -Scope Process -Force; irm "https://raw.githubusercontent.com/PaladinXV/Simple-Windows-11-Setup-Debloat-Script/main/install.ps1" | iex
```

# FAQ
**What versions of Windows will this work on?**
- It has currently been tested on **Windows 11 25H2 Home/Pro**.

**Can I change or revert things?**
- Yes, most settings can be reverted either manually within Windows or via the script.
- Seperate options for subjective settings (ie Old Context Menu, Windows Updates, Defender Settings).
- Windows Apps can be reinstalled.

**Can this be used on an existing install?**
- Yes. If you use Microsoft Apps, please be mindful it will remove them.
- A Restore Point can be created.

**Was AI used in creating this?**
- Yes