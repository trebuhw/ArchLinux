#!/bin/bash
#
# Clone Hyprland-install.script
mkdir ~/Data
cd ~/Data
git clone --depth=1 https://github.com/JaKooLit/Arch-Hyprland.git ~/Arch-Hyprland
cd ~/Arch-Hyprland
chmod +x install.sh
./install.sh
#
chsh -s $(which zsh)
zsh
source ~/.zshrc