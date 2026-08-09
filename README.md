# Simple Windows 11 25H2 Setup Script
A simple, interactive PowerShell script to help setup/debloat Windows 11 Home/Pro for a better experience.

# Features
- Sets good defaults for a better experience (ie Folder Options, Immersive Control Panel settings) without breaking functionality.
- Removes pre-installed UWP apps/shortcuts (ie OneDrive, Copilot, Xbox).
- Able to revert most settings manually, or sepererately revert some that might not want to be changed.

# Warning
> [!Warning]
> If you are doing this on an existing install, be mindful that it will remove Microsoft Apps. It is ideal if you use this script after updating Windows. Use at your own risk!

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
- It has been tested on **Windows 11 25H2 Home/Pro**.

**Can I change or revert things?**
- Yes, most settings can be reverted either manually within Windows or via the script.
- Seperate options for subjective settings (ie Old Context Menu, Windows Updates, Defender Settings).
- Windows Apps can be reinstalled.

**Can this be used on an existing install?**
- Yes. If you use Microsoft Apps, please be mindful it will remove them.
- A Restore Point can be created.

**Was AI used in creating this?**
- Yes