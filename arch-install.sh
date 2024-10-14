#!/bin/bash

# Ustawienia zmiennych
ROOT_PASSWORD=""  # Hasło dla roota
USER_NAME="hubert"
USER_PASSWORD=""
EFI_PARTITION="/dev/sda3"  # Partycja EFI, ustawiona przed uruchomieniem
ROOT_PARTITION="/dev/sda4"  # Partycja root Btrfs, ustawiona przed uruchomieniem
MYHOST="arch"  # Zmienna nazwy hosta
DOTFILES_REPO="https://github.com/trebuhw/dotfiles.git"  # Repozytorium dotfiles

# Sprawdzenie, czy zmienne EFI_PARTITION i ROOT_PARTITION są ustawione
if [[ -z "$EFI_PARTITION" || -z "$ROOT_PARTITION" ]]; then
    echo "Ustaw partycje EFI i root przed uruchomieniem skryptu."
    exit 1
fi

# Formatowanie partycji EFI i ROOT
mkfs.fat -F 32 "$EFI_PARTITION"
mkfs.btrfs "$ROOT_PARTITION"

# Ustawianie flag boot i esp dla partycji EFI
parted $(dirname "$EFI_PARTITION") set $(basename "$EFI_PARTITION" | tr -dc '0-9') boot on
parted $(dirname "$EFI_PARTITION") set $(basename "$EFI_PARTITION" | tr -dc '0-9') esp on

# Tworzenie subwolumenów
mount "$ROOT_PARTITION" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@pkg
btrfs subvolume create /mnt/@snapshots

# Odmontowanie root
umount /mnt

# Tworzenie katalogów
mkdir /mnt/archinstall
mkdir /mnt/archinstall/home
mkdir /mnt/archinstall/var/log
mkdir /mnt/archinstall/var/cache/pacman/pkg
mkdir /mnt/archinstall/.snapshots

# Zamontowanie subwolumenów z kompresją Zstd i noatime
mount -o noatime,compress=zstd:5,discard=async,space_cache=v2,subvol=@ "$ROOT_PARTITION" /mnt/archinstall/archinstall
mount -o noatime,compress=zstd:5,discard=async,space_cache=v2,subvol=@home "$ROOT_PARTITION" /mnt/archinstall/home
mount -o noatime,compress=zstd:5,discard=async,space_cache=v2,subvol=@log "$ROOT_PARTITION" /mnt/archinstall/var/log
mount -o noatime,compress=zstd:5,discard=async,space_cache=v2,subvol=@pkg "$ROOT_PARTITION" /mnt/archinstall/var/cache/pacman/pkg
mount -o noatime,compress=zstd:5,discard=async,space_cache=v2,subvol=@snapshots "$ROOT_PARTITION" /mnt/archinstall/.snapshots

# Tworzenie i montowanie partycji Boot
mkdir -p /mnt/archinstall/boot/
mount "$EFI_PARTITION" /mnt/archinstall/boot/

# Instalacja podstawowych pakietów systemowych
pacstrap /mnt base linux linux-firmware linux-headers btrfs-progs

# Generowanie fstab z kompresją Zstd i noatime
genfstab -U /mnt | sed 's/subvol=[^,]*/&,compress=zstd,noatime/' >> /mnt/etc/fstab

# Chroot
arch-chroot /mnt /bin/bash <<EOF

# Ustawienie lokalizacji
echo "LANG=pl_PL.UTF-8" > /etc/locale.conf
sed -i 's/#pl_PL.UTF-8/pl_PL.UTF-8/' /etc/locale.gen
locale-gen

# Instalacja i konfiguracja consolefont
# echo "FONT=ter-v24b" >> /etc/vconsole.conf

# Nazwa hosta
echo "$MYHOST" > /etc/hostname

# Konfiguracja hosts
cat <<EOL >> /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   $MYHOST.localdomain $MYHOST
EOL

# Konfiguracja strefy czasowej i synchronizacja
ln -sf /usr/share/zoneinfo/Europe/Warsaw /etc/localtime
hwclock --systohc

# Hasło dla roota
echo "root:$ROOT_PASSWORD" | chpasswd

# Tworzenie użytkownika
useradd -m -G wheel "$USER_NAME"
echo "$USER_NAME:$USER_PASSWORD" | chpasswd

# Instalacja sudo i konfiguracja uprawnień
pacman -S --noconfirm sudo
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Instalacja GRUB i podstawowych narzędzi
pacman -S --noconfirm grub efibootmgr networkmanager network-manager-applet \
    xfce4 xfce4-goodies lightdm lightdm-gtk-greeter \
    snapper

# Instalacja bootloadera GRUB
grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Tworzenie initramfs
mkinitcpio -P

# Instalacja Snappera
pacman -S --noconfirm snapper grub-btrfs

# Konfiguracja Snappera
snapper --no-dbus -c root create-config /

# Konfiguracja uprawnień do Snappera
groupadd snapper
usermod -aG snapper $USER_NAME
chmod a+rx /.snapshots
chown :snapper /.snapshots

# Konfiguracja Grub-Btrfs dla automatycznych wpisów do GRUB
sed -i 's/#GRUB_BTRFS_ENABLE_SNAPSHOTS=1/GRUB_BTRFS_ENABLE_SNAPSHOTS=1/' /etc/default/grub-btrfs/config

# Włączanie snapper-timeline i snapper-cleanup
systemctl enable --now snapper-timeline.timer
systemctl enable --now snapper-cleanup.timer

# Dodanie migawkowego ładowania w GRUB
grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

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
systemctl enable avahi-daemon
systemctl enable cups.service
systemctl enable NetworkManager.service
systemctl enable lightdm.service

EOF

# Odmontowanie partycji
umount -R /mnt

echo "Instalacja zakończona. Możesz teraz uruchomić system."
