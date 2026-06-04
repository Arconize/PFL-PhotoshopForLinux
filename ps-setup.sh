#!/bin/bash

# Define the Wine prefix directory
WINEPREFIX="$HOME/.photoshop"

# Function to detect the Linux distribution and install required packages
install_deps() {
    echo "Detecting Linux distribution..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
    else
        echo "Cannot detect OS. Exiting."
        exit 1
    fi

    case "$ID" in
        arch|manjaro|endeavouros|garuda)
            echo "Detected Arch-based distro. Installing dependencies..."
            sudo pacman -S --needed wine winetricks lib32-mesa lib32-gnutls lib32-libpulse lib32-v4l-utils lib32-libxcomposite lib32-libxinerama
            ;;
        ubuntu|linuxmint|pop|debian)
            echo "Detected Debian/Ubuntu-based distro. Installing dependencies..."
            sudo dpkg --add-architecture i386 && sudo apt update
            sudo apt install -y wine64 wine32 winetricks libgl1-mesa-dri:i386 libgl1-mesa-glx:i386
            ;;
        fedora)
            echo "Detected Fedora-based distro. Installing dependencies..."
            sudo dnf install -y wine winetricks mesa-libGL.i686
            ;;
        *)
            echo "Unsupported distro: $ID. Please install Wine and Winetricks manually."
            exit 1
            ;;
    esac
}

# Function to create the Wine prefix and apply essential configurations
create_prefix() {
    echo "Creating Wine prefix at $WINEPREFIX..."
    WINEPREFIX="$WINEPREFIX" wineboot

    echo "Disabling d2d1 to prevent UI lag and rendering issues..."
    WINEPREFIX="$WINEPREFIX" wine reg add "HKCU\Software\Wine\DllOverrides" /v d2d1 /d disable /f

    echo "Disabling winedbg popups on crash..."
    WINEPREFIX="$WINEPREFIX" wine reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AeDebug" /v Auto /d "0" /f

    echo "Applying Photoshop registry fixes (Disabling Home Screen & forcing Legacy Dialogs)..."
    # Registry paths for Photoshop 2021 (22.x)
    WINEPREFIX="$WINEPREFIX" wine reg add "HKCU\Software\Adobe\Photoshop\140.0" /v HomeScreenOnStartDocumentView /t REG_DWORD /d 0 /f
    WINEPREFIX="$WINEPREFIX" wine reg add "HKCU\Software\Adobe\Photoshop\140.0" /v UseLegacyNewFileDialog /t REG_DWORD /d 1 /f
    # Registry paths for Photoshop 2022 (23.x)
    WINEPREFIX="$WINEPREFIX" wine reg add "HKCU\Software\Adobe\Photoshop\220.0" /v HomeScreenOnStartDocumentView /t REG_DWORD /d 0 /f
    WINEPREFIX="$WINEPREFIX" wine reg add "HKCU\Software\Adobe\Photoshop\220.0" /v UseLegacyNewFileDialog /t REG_DWORD /d 1 /f

    echo "Downloading and installing Visual C++ Redistributables (AIO)..."
    wget -O "/tmp/VisualCppRedist_AIO_x86_x64.exe" "https://github.com/abbodi1406/vcredist/releases/latest/download/VisualCppRedist_AIO_x86_x64.exe"
    WINEPREFIX="$WINEPREFIX" wine /tmp/VisualCppRedist_AIO_x86_x64.exe
    rm /tmp/VisualCppRedist_AIO_x86_x64.exe

    # Gracefully shut down the Wine server to save all changes
    WINEPREFIX="$WINEPREFIX" wineserver -k
}

# Function to patch CEF helpers to prevent freezes and winedbg crashes
patch_cef() {
    echo "Patching CEF helpers to prevent UI freezes..."
    # Replace the Chromium-based helpers with cmd.exe so they fail silently
    find "$WINEPREFIX" -type f \( -name "Adobe Spaces Helper.exe" -o -name "Adobe CEF Helper.exe" \) -exec cp -v "$WINEPREFIX/drive_c/windows/system32/cmd.exe" {} \;
    WINEPREFIX="$WINEPREFIX" wineserver -k
    echo "Patch applied successfully!"
}

# Function to launch the Adobe installer
run_installer() {
    INSTALLER="$2"
    if [ ! -f "$INSTALLER" ]; then
        echo "Error: Installer file not found at $INSTALLER"
        exit 1
    fi
    echo "Launching Photoshop installer..."
    WINEPREFIX="$WINEPREFIX" wine "$INSTALLER"
}

# Main logic to handle script arguments
if [ "$1" == "--install" ]; then
    run_installer "$@"
elif [ "$1" == "--patch" ]; then
    patch_cef
else
    # If no argument is provided, run the initial setup
    install_deps
    create_prefix
    echo ""
    echo "=================================================="
    echo " done now you should run installer"
    echo " Usage: ./ps-setup.sh --install /path/to/Set-up.exe"
    echo " After installation, run: ./ps-setup.sh --patch"
    echo "=================================================="
fi
