#!/bin/bash

# Define the Wine prefix directory
WINEPREFIX="$HOME/.photoshop"

#Formatting variables
BOLD='\e[1m'
RED='\e[31m'
YEL='\e[33m'
GRE='\e[32m'
DEF='\e[0m'


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
            echo -e ${YEL} "Detected Arch-based distro. Installing dependencies..."${DEF}
            sudo pacman -S --needed wine winetricks lib32-mesa lib32-gnutls lib32-libpulse lib32-v4l-utils lib32-libxcomposite lib32-libxinerama
            ;;
        ubuntu|linuxmint|pop|debian)
            echo -e ${YEL} "Detected Debian/Ubuntu-based distro. Installing dependencies..."${DEF}
            sudo dpkg --add-architecture i386 && sudo apt update
            sudo apt install -y wine64 wine32 winetricks libgl1-mesa-dri:i386 libgl1-mesa-glx:i386
            ;;
        fedora)
            echo -e ${YEL} "Detected Fedora-based distro. Installing dependencies..."${DEF}
            sudo dnf install -y wine winetricks mesa-libGL.i686
            ;;
        *)
            echo -e ${RED} ${BOLD}"Unsupported distro: $ID. Please install Wine and Winetricks manually."${DEF}
            exit 1
            ;;
    esac
}

# Function to create the Wine prefix and apply essential configurations
create_prefix() {
    echo -e ${YEL} "Creating Wine prefix at $WINEPREFIX..."${DEF}
    WINEPREFIX="$WINEPREFIX" wineboot

    echo -e ${YEL} "Disabling d2d1 to prevent UI lag and rendering issues..."${DEF}
    WINEPREFIX="$WINEPREFIX" wine reg add "HKCU\Software\Wine\DllOverrides" /v d2d1 /d disable /f

    echo -e ${YEL} "Disabling winedbg popups on crash..."${DEF}
    WINEPREFIX="$WINEPREFIX" wine reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AeDebug" /v Auto /d "0" /f

    echo -e ${YEL} "Applying Photoshop registry fixes (Disabling Home Screen & forcing Legacy Dialogs)..."${DEF}
    # Registry paths for Photoshop 2021 (22.x)
    WINEPREFIX="$WINEPREFIX" wine reg add "HKCU\Software\Adobe\Photoshop\140.0" /v HomeScreenOnStartDocumentView /t REG_DWORD /d 0 /f
    WINEPREFIX="$WINEPREFIX" wine reg add "HKCU\Software\Adobe\Photoshop\140.0" /v UseLegacyNewFileDialog /t REG_DWORD /d 1 /f
    # Registry paths for Photoshop 2022 (23.x)
    WINEPREFIX="$WINEPREFIX" wine reg add "HKCU\Software\Adobe\Photoshop\220.0" /v HomeScreenOnStartDocumentView /t REG_DWORD /d 0 /f
    WINEPREFIX="$WINEPREFIX" wine reg add "HKCU\Software\Adobe\Photoshop\220.0" /v UseLegacyNewFileDialog /t REG_DWORD /d 1 /f

    echo -e ${YEL} "Downloading and installing Visual C++ Redistributables (AIO)..."${DEF}
    if [ -f /tmp/VisualCppRedist_AIO_x86_x64.exe ]; then
        WINEPREFIX="$WINEPREFIX" wine /tmp/VisualCppRedist_AIO_x86_x64.exe
        rm /tmp/VisualCppRedist_AIO_x86_x64.exe
    else
    	curl -fsSL -o "/tmp/VisualCppRedist_AIO_x86_x64.exe" "https://github.com/abbodi1406/vcredist/releases/latest/download/VisualCppRedist_AIO_x86_x64.exe"
    	if [ -f /tmp/VisualCppRedist_AIO_x86_x64.exe ]; then
            WINEPREFIX="$WINEPREFIX" wine /tmp/VisualCppRedist_AIO_x86_x64.exe
            rm /tmp/VisualCppRedist_AIO_x86_x64.exe
    	else
    		echo -e ${BOLD} ${RED}"ERROR: VisualCppRedist_AIO_x86_X64.exe does not exist in /tmp. it's either deleted or not downloaded. Exiting."${DEF}
    		exit 1
    	fi
    fi
    

    # Gracefully shut down the Wine server to save all changes
    WINEPREFIX="$WINEPREFIX" wineserver -k
}

# Function to patch CEF helpers to prevent freezes and winedbg crashes
patch_cef() {
    echo -e ${YEL} "Patching CEF helpers to prevent UI freezes..."${DEF}
    # Replace the Chromium-based helpers with cmd.exe so they fail silently
    find "$WINEPREFIX" -type f \( -name "Adobe Spaces Helper.exe" -o -name "Adobe CEF Helper.exe" \) -exec cp -v "$WINEPREFIX/drive_c/windows/system32/cmd.exe" {} \;
    WINEPREFIX="$WINEPREFIX" wineserver -k
    echo -e ${GRE} ${BOLD}"Patch applied successfully!"${DEF}
}

# Function to launch the Adobe installer
run_installer() {
    INSTALLER="$2"
    if [ ! -f "$INSTALLER" ]; then
        echo -e ${BOLD} ${RED}"Error: Installer file not found at $INSTALLER"${DEF}
        exit 1
    fi
    echo -e ${YEL} "Launching Photoshop installer..."${DEF}
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
    echo -e ${GRE} ${BOLD}""
    echo -e "=================================================="
    echo -e " done now you should run installer"
    echo -e " Usage: ./ps-setup.sh --install /path/to/Set-up.exe"
    echo -e " After installation, run: ./ps-setup.sh --patch"
    echo -e "=================================================="${DEF}
fi
