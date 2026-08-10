# Documentation (NOT FINISHED)
1) Short summary of each script
2) Proper documentation of everything that is changed


# 1) Scripts 


# Restore Point

> Restore Point
- Creates a Restore Point 


# Apply

> Apply Setup
- Uninstalls pre-installed UWP apps/shortcuts (ie Copilot, OneDrive, Xbox)
- Sets all the registry keys (settings) 

> Disable Device Metadata (beta)
- Prevents Windows from downloading device metadata from Microsoft (I currently do not have a device to be able to test this so it will remain as a beta)

> Disable Drivers via Windows Update
- Prevents Windows from downloading drivers from Windows Update

> Activate Ultimate Performance Power Plan
- In "Apply Setup", Ultimate Performance Power Plan is added, but not activated

> Set Solid Colour Wallpaper (Black)
- Sets the wallpaper to solid black. More of a personal use option


# Revert

> Revert Setup Script (Settings Only)
- Reverts all the registry keys (settings) that were applied in the "Apply Setup" script. Reverting everything in a single prompt is possible but would take a long time due to Winget, downloads etc.

> Enable Hibernate
- Re-enables Hibernate as it was disabled in the "Apply-Setup" script

> Revert Edge Settings
- Reverts Edge "First Time Run, Startup Boost, Running in the Background" settings

> Revert Defender Settings
- Reverts Defender "Core Isolation, VBS and Automatic Sample Submission" settings

> Revert Windows Update Settings
- Reverts Windows Update "Delay Feature Updates by 120 days, Delay Security Updates by 4 days" changes

> Revert Right-Click Context Menu
- Reverts back to the new Windows 11 Right-Click menu


# Programs

> Winget
- Uses Winget to install programs 
- Can be used to update installed programs

> Chocolatey
- Checks and asks to install the Chocolatey installer
- Uses Chocolatey to install programs
- Can be used to update installed programs

> Configs (beta)
- Deploys configs for programs
- Can be reverted if required


# 2) Documentation of changes (Apply-Setup Script order)

> Removal of the following pre-installed UWP Apps 
- 365 Copilot
- Alarms
- Bing News
- Camera
- Clipchamp
- Copilot
- Feedback Hub
- Microsoft Teams
- Office
- OneDrive
- Outlook
- Power Automate
- Quick Assist
- Solitaire
- Sound Recorder
- Sticky Notes
- To Do List
- Widgets
- Xbox

User can reinstall these with the "Winget" option. These are considered bloat and can be annoying with notifications or even hijacking user files (OneDrive).


> Changes to Microsoft Edge browser
- HideFirstRunExperience (Disables the annoying first Edge setup)
- StartupBoostEnabled (Disables the background processes running that reduce browser startup time)
- BackgroundModeEnabled (Disables Edge from running in the background when closed)

> Folder Options
- Launches to "This PC"
- Disables "Show recently used files"
- Disables "Show frequently used folders"
- Disables "Show files from Office.com"
- Enables "Hide extensions for known file types"
- Enables Compact Mode in File Explorer (This setting can be toggled in File Explorer itself)

> Mouse Properties
- Disables Mouse Acceleration

> Power Settings
- Disables Hibernate (session continually writes to disk. Useful for laptops though)
- Adds Ultimate Performance Power Plan (not activated, harmless)

> Windows Update Changes
- Delays Windows Feature Updates by 120 days (Delays feature updates for 4 months so that any issues are most likely fixed. Will still be secure as Microsoft supports Home/Pro builds for 2 years)
- Delays Windows Security Updates by 4 days (Same as above but within a time threshold of being secure)
- Disables Delivery Optimization (uses computers on the local network to pull updates from. From personal experience, this slows down update downloads) (Registry Key is later in the script down in the Immersive Control Panel section)

> Sound Settings
- Sets "Do nothing" in "Sound -> Communications" legacy panel


# Immersive Control Panel

> System Settings
- Disables Microsoft's "Lets finish setting up this device" and other Welcome Screen prompts
- Disables Storage Sense
- Changes Alt-Tab to show open Windows only
- Enables "End Task" in the Taskbar
- Hides the "Windows Spotlight" desktop icon

> Content Delivery
- Disables "Suggested Apps"
- Disables "Silent App Installation"
- Disables "Promotional Content"
- Disables "Windows Suggestions"
- Disables "Tips/Soft Landing"
- Disables "Subscribed content"
- Disables various "Microsoft Content Experiences"

> Cloud Content
- Disables "Consumer Experiences"
- Disables "Cloud Consumer-Account Content"
- Disables "CLoud-Optimized content"

> Theme
- Disables Spotlight on the lock-screen
- Disables Spotlight/Info overlay on the lock-screen
- Prevents Windows Spotlight on the Desktop
- Disables Windows Spotlight features
- Sets Dark Mode
- sets Dark Mode for Apps
- Disables Windows Transparency Effects
- Removes Windows Sign-in Background Image


