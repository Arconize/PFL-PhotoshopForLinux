# PFL - Photoshop For Linux (Wine) Auto-Installer

A bash script to automate the installation of Adobe Photoshop (2021/2022) on Linux using Wine.

With the recent removal of `wine64` and broken resource links in older scripts (like gmanka), installing Photoshop has become a nightmare. This script provides a clean, up-to-date, and stable method to get Photoshop running smoothly on modern Linux distributions without using custom Wine patches.

## Features

- **Distro Agnostic**: Automatically detects and installs dependencies for Arch, Ubuntu/Debian, and Fedora.
- **UI Lag Fix**
- **Freeze Fix**: Patches the Adobe CEF (Chromium) helpers to prevent the infamous UI freezes and blank screens.
- **Debugger Fix**: Disables `winedbg` pop-ups when background Adobe processes crash.
- **Legacy Dialogs**: Forces Photoshop to use classic Win32 dialogs (New File, Open File) instead of the laggy modern ones.
- **Automated Dependencies**: Downloads and installs the latest Visual C++ Redistributables AIO automatically.

## Prerequisites

- An active internet connection.
- `sudo` privileges.
- An offline/cracked Photoshop 2021 or 2022 installer (e.g., `Set-up.exe`).

## Usage

**1. Clone the repository:**

```bash
git clone https://github.com/Arconize/PFL-PhotoshopForLinux.git
```

**2. Make the script executable:**

```bash
chmod +x ps-setup.sh
```

**3. Run the initial setup:** This will install system dependencies, create the Wine prefix, apply registry fixes, and install VCRedist.

```bash
./ps-setup.sh
```


**4. Install Photoshop:** Once the setup is complete, run the Adobe installer through the script.

```bash
./ps-setup.sh --install /path/to/your/Set-up.exe
```

**5. Apply Post-Install Patch (CRITICAL):** After the installation is completely finished, you **must** run the patch command. This replaces the crashing CEF web helpers with a harmless dummy file, preventing the app from freezing when opening files.

```bash
./ps-setup.sh --patch
```

## How to Launch Photoshop

After installation, you can launch Photoshop via terminal:

```bash
WINEPREFIX=$HOME/.photoshop wine "/home/$USER/.photoshop/drive_c/Program Files/Adobe/Adobe Photoshop 2021/Photoshop.exe"
```

_(Tip: You can add this command to a `.desktop` file or your application launcher)._

## Important Notes

- if You are using hybrid graphics (intel + NVIDIA) please use prime-run for launching the app.
- If you want to test a newer version (like 2023+), **create a separate Wine prefix** to avoid breaking this stable setup.
