#!/bin/bash
#
# Clone Hyprland-install.script
sudo pacman -Syyu
git clone htps://aur.archlinux.org/paru.git
cd paru
sudo makepkg -si
paru -S ml4w-hyprland
#
# poskończeniu instalacji uruchomić
# ml4w-hyprland-setup
