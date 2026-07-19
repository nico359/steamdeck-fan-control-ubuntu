#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script requires root privileges. Please run with 'sudo'!"
    echo "Example: sudo $0"
    exit 1
fi

# Setup script for Pop OS/Ubuntu-based distros on the Steam Deck
set -e # Exit on error
set -u # Warn on undefined variables

echo "=== Updating package sources ==="
apt update -y

echo "=== Installing dependencies ==="
apt install wget git dkms -y

echo "=== Downloading Steam Deck DKMS driver ==="
wget https://github.com/firlin123/steamdeck-dkms/releases/download/v6.8.12-valve2/steamdeck-dkms_6.8.12-valve2_amd64.deb

echo "=== Installing DKMS driver ==="
apt install ./steamdeck-dkms_6.8.12-valve2_amd64.deb

echo "=== Cloning Fan Control repository ==="
git clone https://gitlab.com/evlaV/jupiter-fan-control.git

echo "=== Configuring Fan Control service ==="
cp ./jupiter-fan-control/usr/lib/systemd/system/jupiter-fan-control.service /usr/lib/systemd/system/
cp ./jupiter-fan-control/usr/lib/systemd/system/multi-user.target.wants/jupiter-fan-control.service /usr/lib/systemd/system/multi-user.target.wants/
cp -r ./jupiter-fan-control/usr/share/jupiter-fan-control/ /usr/share/

# Update only the main service file to use /usr/bin/python3
sed -i 's|^ExecStart=|ExecStart=/usr/bin/python3 |' /usr/lib/systemd/system/jupiter-fan-control.service
sed -i 's|^ExecStopPost=|ExecStopPost=/usr/bin/python3 |' /usr/lib/systemd/system/jupiter-fan-control.service

echo "=== Enabling Fan Control ==="
systemctl daemon-reload
systemctl enable jupiter-fan-control.service
systemctl start jupiter-fan-control.service

echo "==============================================="
printf "Please reboot your system!\nReason: Installed kernel modules require a reboot\n"
echo "==============================================="