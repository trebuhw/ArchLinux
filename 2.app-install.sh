#!/bin/bash

USER_NAME="hubert"
DOTFILES_REPO="https://github.com/trebuhw/dotfiles.git"  # Repozytorium dotfiles

# Instalacja Snappera
sudo pacman -S --noconfirm snapper grub-btrfs

# Konfiguracja Snappera
snapper --no-dbus -c root create-config /

# Konfiguracja uprawnień do Snappera
sudo groupadd snapper
sudo usermod -aG snapper $USER_NAME
sudo chmod a+rx /.snapshots
sudo chown :snapper /.snapshots

# Konfiguracja Grub-Btrfs dla automatycznych wpisów do GRUB
sudo sed -i 's/#GRUB_BTRFS_ENABLE_SNAPSHOTS=1/GRUB_BTRFS_ENABLE_SNAPSHOTS=1/' /etc/default/grub-btrfs/config

# Włączanie snapper-timeline i snapper-cleanup
sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer

# Dodanie migawkowego ładowania w GRUB
sudo grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=GRUB
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Instalacja yay
git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay
makepkg -si --noconfirm
cd -
rm -rf /tmp/yay

# Instalacja dodatkowych pakietów do Xorg, PulseAudio, drukowania i innych
pacman -S --noconfirm xorg-server xorg-xinit xorg-xrandr xorg-xsetroot xorg-xkill \
    xfce4-notifyd pulseaudio pulseaudio-alsa pavucontrol cups cups-pdf ghostscript \
    system-config-printer avahi nss-mdns gvfs-smb \
    adobe-source-sans-fonts aic94xx-firmware alacritty arandr arc-gtk-theme \
    awesome-terminal-fonts bash-completion bat brightnessctl btop cpuid curl \
    dconf-editor downgrade duf dunst fastfetch feh file-roller firefox fish \
    flameshot font-manager fzf galculator gcolor3 geany gimp git gparted gzip \
    hardcode-fixer-git hardinfo-gtk3 hddtemp htop hw-probe i3lock kitty \
    libreoffice-fresh libreoffice-fresh-pl lm_sensors lsd lshw man-db man-pages \
    meld mkinitcpio-firmware mlocate most neovim networkmanager-openvpn ntp \
    numlockx nwg-look p7zip papirus-icon-theme parcellite pdfarranger picom \
    polkit polkit-gnome ranger rclone ripgrep rofi rsync speedtest-cli-git starship \
    sxhkd sxiv system-config-printer thunar thunar-volman thunderbird time \
    tldr tlp trash-cli tree ttf-jetbrains-mono-nerd ueberzug unrar unzip vim vlc wget \
    wttr xclip xcolor xdg-user-dirs zathura zoxide

# Instalacja motywu catppuccin-gtk-theme-mocha
yay -S --noconfirm catppuccin-gtk-theme-mocha

# Instalacja czcionek FiraCode Nerd Font
yay -S --noconfirm nerd-fonts-fira-code

# Aktualizacja czcionek
fc-cache -fv

# Pobranie repozytorium dotfiles i skopiowanie do .config
git clone "$DOTFILES_REPO" /tmp/dotfiles
cp -r /tmp/dotfiles/* ~/.config/
rm -rf /tmp/dotfiles

# Włączanie usług NetworkManager, lightdm, PulseAudio i drukowania
sudo systemctl enable avahi-daemon
sudo systemctl enable cups.service
#systemctl enable NetworkManager.service
#systemctl enable lightdm.service

EOF

echo "Instalacja zakończona. Możesz teraz uruchomić system."
