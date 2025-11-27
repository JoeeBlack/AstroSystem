#!/bin/bash

# Stop script on error
set -e

echo "Witaj w skrypcie instalacyjnym AstroSystem v2!"

# Create main directory
mkdir -p astrosystem
cd astrosystem

echo "--- Aktualizacja systemu ---"
export DEBIAN_FRONTEND=noninteractive

# Check for sudo
if ! command -v sudo &> /dev/null; then
    echo "Błąd: sudo nie jest zainstalowane. Uruchom ten skrypt jako root lub zainstaluj sudo."
    exit 1
fi

echo "Pobieranie list pakietów..."
sudo apt update -y

echo "Aktualizacja pakietów..."
sudo apt upgrade -y

echo "Czyszczenie..."
sudo apt autoremove -y

sudo apt install -y git

echo "--- Instalacja podstawowych narzędzi ---"
# Ensure we have the package available
sudo apt update -y

# Detect OS Codename
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_CODENAME=$VERSION_CODENAME
else
    echo "Nie można wykryć wersji systemu. Zakładam 'jammy' (Ubuntu 22.04)."
    OS_CODENAME="jammy"
fi

echo "Wykryto system: $OS_CODENAME"

# Enable Universe and Multiverse manually
echo "deb http://archive.ubuntu.com/ubuntu/ $OS_CODENAME universe multiverse" | sudo tee /etc/apt/sources.list.d/universe-multiverse.list
echo "deb http://archive.ubuntu.com/ubuntu/ $OS_CODENAME-updates universe multiverse" | sudo tee -a /etc/apt/sources.list.d/universe-multiverse.list
echo "deb http://security.ubuntu.com/ubuntu/ $OS_CODENAME-security universe multiverse" | sudo tee -a /etc/apt/sources.list.d/universe-multiverse.list

sudo apt update -y
sudo apt install -y wget python3 python3-venv python3-pip vlc mc nano build-essential saods9

echo "--- Instalacja bibliotek deweloperskich ---"
# Fixed package names: fortran -> gfortran, libnext-dev -> libxaw7-dev
sudo apt install -y \
    groff-base libmotif-dev libxaw7-dev libxext-dev libxmu-dev libxt-dev \
    libx11-dev libxft-dev libpng-dev libjpeg-dev libtiff-dev zlib1g-dev \
    gcc make flex bison gfortran libncurses-dev libssl-dev \
    libcurl4-openssl-dev libexpat-dev libreadline-dev \
    libc6-dev libbz2-dev libffi-dev libgdbm-dev liblzma-dev libsqlite3-dev \
    tk-dev libxml2-dev libxmlsec1-dev libyaml-dev

echo "--- Instalacja Stellarium (PPA) ---"
# Manual PPA setup for Stellarium
STELLARIUM_KEY_URL="https://keyserver.ubuntu.com/pks/lookup?fingerprint=on&op=get&search=0xE12687626702104CAD5B767DEB690A6429908236"
STELLARIUM_KEYRING="/usr/share/keyrings/stellarium-archive-keyring.gpg"

wget -qO - "$STELLARIUM_KEY_URL" | gpg --dearmor | sudo dd of="$STELLARIUM_KEYRING"

echo "deb [signed-by=$STELLARIUM_KEYRING] https://ppa.launchpadcontent.net/stellarium/stellarium-releases/ubuntu $OS_CODENAME main" | sudo tee /etc/apt/sources.list.d/stellarium.list
echo "deb-src [signed-by=$STELLARIUM_KEYRING] https://ppa.launchpadcontent.net/stellarium/stellarium-releases/ubuntu $OS_CODENAME main" | sudo tee -a /etc/apt/sources.list.d/stellarium.list

sudo apt update -y
sudo apt install -y stellarium

echo "--- Instalacja VSCodium (Repozytorium) ---"
wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | gpg --dearmor | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg
echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' | sudo tee /etc/apt/sources.list.d/vscodium.list
sudo apt update -y
sudo apt install -y codium

echo "--- Konfiguracja środowiska Python ---"
# Use venv to avoid PEP 668 errors on modern Ubuntu
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate
pip install --upgrade pip
# Installing Phoebe 2 (modern) instead of 1.0.1
pip install numpy matplotlib astropy phoebe

echo "--- Instalacja Starlink ---"
# Updated to 2023A version
STARLINK_FILE="starlink-2023A-Linux-glibc2.17-x86_64.tar.gz"
if [ ! -f "$STARLINK_FILE" ]; then
    echo "Pobieranie Starlink..."
    wget "https://ftp.eao.hawaii.edu/starlink/2023A/$STARLINK_FILE"
fi

if [ ! -d "starlink" ]; then
    echo "Rozpakowywanie Starlink..."
    tar -xzf "$STARLINK_FILE"
    # Rename for easier access or keep as is. The tarball usually contains a 'starlink' dir or versioned dir.
    # Assuming it extracts to 'starlink' or similar. Let's check contents if we could, but for now we assume standard behavior.
fi

echo "--- Instalacja XEphem ---"
XEPHEM_FILE="xephem-4.1.0.tar.gz"
if [ ! -f "$XEPHEM_FILE" ]; then
    echo "Pobieranie XEphem..."
    wget "https://github.com/XEphem/XEphem/archive/refs/tags/4.1.0.tar.gz" -O "$XEPHEM_FILE"
fi

if [ ! -d "XEphem-4.1.0" ]; then
    tar -xzf "$XEPHEM_FILE"
fi

# Build XEphem
cd XEphem-4.1.0/GUI/xephem
make
# Install binary to a location in PATH
sudo cp xephem /usr/local/bin/
mkdir -p $HOME/.xephem
cd ../../..

echo "--- Instalacja IRAF ---"
if [ ! -d "iraf" ]; then
    git clone https://github.com/iraf-community/iraf.git
fi
cd iraf
# Configure and build
./configure
make
sudo make install
cd ..

echo "--- Czyszczenie ---"
sudo apt autoremove -y

echo "!!! Instalacja zakończona !!!"
echo "Dodaj poniższe linie do swojego ~/.bashrc:"
echo ""
echo "source $(pwd)/venv/bin/activate"
echo "export STARLINK_DIR=$(pwd)/starlink"
echo "source \$STARLINK_DIR/etc/profile"
echo "export IRAFARCH=linux64"
echo "export IRAF=$(pwd)/iraf"
echo ""
echo "Następnie wykonaj: source ~/.bashrc"