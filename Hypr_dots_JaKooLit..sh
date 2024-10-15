#!/bin/bash
#
# Clone Hyprland-install.script
mkdir ~/Data
cd ~/Data
git clone --depth=1 https://github.com/JaKooLit/Hyprland-Dots.git
cd Hyprland-Dots
chmod +x copy.sh
./copy.sh
# Upgrade
# ./upgrade.sh # # Aby ta funkcja działała, potrzebny jest rsync