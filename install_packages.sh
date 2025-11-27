#!/bin/bash

# Stop script on error
set -e

echo "Witaj w skrypcie instalacyjnym AstroSystem v2!"

# Create main directory
mkdir -p astrosystem
cd astrosystem

echo "--- Aktualizacja systemu ---"
sudo apt update -y && sudo apt upgrade -y && sudo apt autoremove -y
sudo apt install -y git

echo "--- Instalacja podstawowych narzędzi ---"
sudo apt install -y software-properties-common
sudo add-apt-repository -y universe
sudo add-apt-repository -y multiverse
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
sudo add-apt-repository -y ppa:stellarium/stellarium-releases
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