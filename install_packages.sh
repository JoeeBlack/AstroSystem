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

sudo apt install -y git software-properties-common wget gpg

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
sudo apt install -y python3 python3-venv python3-pip vlc mc nano build-essential saods9

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
# Use add-apt-repository for better reliability
sudo add-apt-repository -y ppa:stellarium/stellarium-releases
sudo apt update -y
sudo apt install -y stellarium

echo "--- Instalacja VSCodium (Repozytorium) ---"
wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | gpg --dearmor | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg
echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/debs vscodium main' | sudo tee /etc/apt/sources.list.d/vscodium.list
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
# Determine correct Starlink version
case "$OS_CODENAME" in
    noble|mantic)
        # Ubuntu 23.10 / 24.04
        STARLINK_FILE="starlink-2023A-Linux-Ubuntu23.tar.gz"
        ;;
    jammy|focal)
        # Ubuntu 22.04 / 20.04
        STARLINK_FILE="starlink-2023A-Linux-Ubuntu22.tar.gz"
        ;;
    *)
        echo "Ostrzeżenie: Niewykryta wersja Ubuntu. Używam wersji dla Ubuntu 22.04."
        STARLINK_FILE="starlink-2023A-Linux-Ubuntu22.tar.gz"
        ;;
esac

STARLINK_URL="https://ftp.eao.hawaii.edu/starlink/2023A/$STARLINK_FILE"

if [ ! -f "$STARLINK_FILE" ]; then
    echo "Pobieranie Starlink ($STARLINK_FILE)..."
    wget "$STARLINK_URL"
fi

if [ ! -d "star-2023A" ] && [ ! -d "starlink" ]; then
    echo "Rozpakowywanie Starlink..."
    tar -xzf "$STARLINK_FILE"
fi

# Determine Starlink directory name
if [ -d "star-2023A" ]; then
    STARLINK_DIR_NAME="star-2023A"
elif [ -d "starlink" ]; then
    STARLINK_DIR_NAME="starlink"
else
    # Fallback if extraction worked but we don't know the name?
    # Usually it's star-2023A
    STARLINK_DIR_NAME="star-2023A"
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
if [ ! -f "/usr/local/bin/xephem" ]; then
    echo "Kompilacja XEphem..."
    cd XEphem-4.1.0/GUI/xephem
    make
    # Install binary to a location in PATH
    sudo cp xephem /usr/local/bin/
    mkdir -p $HOME/.xephem
    cd ../../..
else
    echo "XEphem jest już zainstalowany."
fi

echo "--- Instalacja IRAF ---"
if [ ! -d "iraf" ]; then
    git clone https://github.com/iraf-community/iraf.git
fi

if [ ! -f "iraf/bin/cl.e" ] && [ ! -f "/usr/local/bin/cl" ]; then
    echo "Kompilacja IRAF..."
    cd iraf
    # Configure and build
    ./configure
    make
    sudo make install
    cd ..
else
     echo "IRAF jest już skompilowany/zainstalowany."
fi


echo "--- Czyszczenie ---"
sudo apt autoremove -y

echo "!!! Instalacja zakończona !!!"
echo "Dodaj poniższe linie do swojego ~/.bashrc:"
echo ""
echo "source $(pwd)/venv/bin/activate"
echo "export STARLINK_DIR=$(pwd)/$STARLINK_DIR_NAME"
echo "source \$STARLINK_DIR/etc/profile"
echo "export IRAFARCH=linux64"
echo "export IRAF=$(pwd)/iraf"
echo ""
echo "Następnie wykonaj: source ~/.bashrc"
