#!/bin/bash

USER_NAME="hubert"
DOTFILES_REPO="https://github.com/trebuhw/dotfiles.git"  # Repozytorium dotfiles

#!/bin/bash

packer="sudo pacman -S --noconfirm --needed"

# Instalacja yay
git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay
sudo makepkg -si --noconfirm
cd -
rm -rf /tmp/yay

sudo pacman -Syyu

$packer adobe-source-sans-fonts
$packer aic94xx-firmware
$packer alacritty
$packer arandr
$packer arc-gtk-theme
$packer archiso
$packer avahi
$packer awesome-terminal-fonts
$packer bash-completion
$packer bat
$packer brightnessctl
$packer btop
$packer cpuid
$packer cups
$packer curl
$packer dconf-editor
$packer downgrade
$packer duf
$packer dunst
$packer fastfetch
$packer feh
$packer file-roller
$packer firefox
$packer fish
$packer flameshot
$packer font-manager
$packer fzf
$packer galculator
$packer gcolor3
$packer geany
$packer gimp
$packer git
$packer gnome-disk-utility
$packer gparted
$packer grub-customizer
$packer gtop
$packer gvfs-smb
$packer gzip
$packer hardcode-fixer-git
$packer hardinfo-gtk3
$packer hddtemp
$packer htop
$packer hw-probe
$packer i3lock
$packer kitty
$packer libreoffice-fresh
$packer libreoffice-fresh-pl
$packer linux-firmware-qlogic
$packer lm_sensors
$packer logrotate
$packer lolcat
$packer lsd
$packer lshw
$packer man-db
$packer man-pages
$packer meld
$packer mintstick-git
$packer mkinitcpio-firmware
$packer mlocate
$packer most
$packer neovim
$packer network-manager-applet
$packer networkmanager-openvpn
$packer noto-fonts
$packer nss-mdns
$packer ntp
$packer numlockx
$packer nwg-look
$packer openresolv
$packer os-prober
$packer p7zip
$packer papirus-icon-theme
$packer parcellite
$packer pavucontrol
$packer pdfarranger
$packer picom
$packer playerctl
$packer polkit
$packer polkit-gnome
$packer ranger
$packer rclone
$packer ripgrep
$packer rofi
$packer rsync
$packer scrot
$packer sparklines-git
$packer speedtest-cli-git
$packer spotify
$packer squashfs-tools
$packer scrot
$packer starship
$packer sxhkd
$packer sxiv
$packer system-config-printer
$packer thunar
$packer thunar-volman
$packer thunderbird
$packer time
$packer tldr
$packer tlp
$packer trash-cli
$packer tree
$packer ttf-jetbrains-mono-nerd
$packer ueberzug
$packer unrar
$packer unzip
$packer upd72020x-fw
$packer vim
$packer vlc
$packer wd719x-firmware
$packer wget
$packer wttr
$packer xclip
$packer xcolor
$packer xdg-user-dirs
$packer xfce4-notifyd
$packer xorg-server
$packer xorg-xinit
$packer xorg-xkill
$packer xorg-xrandr
$packer xorg-xsetroot
$packer zathura
$packer zoxide

#yay --noconfirm archlinux-tweak-tool-git
#yay --noconfirm bibata-cursor-theme
yay --noconfirm update-grub
yay --noconfirm xwininfo
yay --noconfirm google-chrome
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
