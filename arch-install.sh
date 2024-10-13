#!/bin/bash

# Ustawienia zmiennych
ROOT_PASSWORD=""  # Hasło dla roota
USER_NAME="hubert"
USER_PASSWORD=""
EFI_PARTITION="/dev/sda1"  # Partycja EFI, ustawiona przed uruchomieniem
ROOT_PARTITION="/dev/sda2"  # Partycja root Btrfs, ustawiona przed uruchomieniem

# Sprawdzenie, czy zmienne EFI_PARTITION i ROOT_PARTITION są ustawione
if [[ -z "$EFI_PARTITION" || -z "$ROOT_PARTITION" ]]; then
    echo "Ustaw partycje EFI i root przed uruchomieniem skryptu."
    exit 1
fi

# Formatowanie partycji EFI i ROOT
mkfs.fat -F32 "$EFI_PARTITION"
mkfs.btrfs "$ROOT_PARTITION"

# Ustawianie flag boot i esp dla partycji EFI
parted $(dirname "$EFI_PARTITION") set $(basename "$EFI_PARTITION" | tr -dc '0-9') boot on
parted $(dirname "$EFI_PARTITION") set $(basename "$EFI_PARTITION" | tr -dc '0-9') esp on

# Montowanie systemu
mount "$ROOT_PARTITION" /mnt

# Tworzenie subwolumenów
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@pkg
btrfs subvolume create /mnt/@.snapshots

# Odmontowanie root i ponowne zamontowanie subwolumenów z kompresją Zstd i noatime
umount /mnt
mount -o subvol=@,compress=zstd,noatime "$ROOT_PARTITION" /mnt
mkdir -p /mnt/{boot/EFI,home,var/cache/pacman/pkg,var/log,.snapshots}
mount -o subvol=@home,compress=zstd,noatime "$ROOT_PARTITION" /mnt/home
mount -o subvol=@log,compress=zstd,noatime "$ROOT_PARTITION" /mnt/var/log
mount -o subvol=@pkg,compress=zstd,noatime "$ROOT_PARTITION" /mnt/var/cache/pacman/pkg
mount -o subvol=@.snapshots,compress=zstd,noatime "$ROOT_PARTITION" /mnt/.snapshots
mount "$EFI_PARTITION" /mnt/boot/EFI

# Instalacja podstawowych pakietów systemowych
pacstrap /mnt base linux linux-firmware btrfs-progs linux-headers

# Generowanie fstab z kompresją Zstd i noatime
genfstab -U /mnt | sed 's/subvol=@/&,compress=zstd,noatime/' >> /mnt/etc/fstab

# Chroot
arch-chroot /mnt /bin/bash <<EOF

# Ustawienia lokalizacji
echo "pl_PL.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=pl_PL.UTF-8" > /etc/locale.conf
echo "myhost" > /etc/hostname

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
    linux-headers git base-devel

# Instalacja bootloadera GRUB
grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Tworzenie initramfs
mkinitcpio -P

# Włączanie usług
systemctl enable NetworkManager
systemctl enable lightdm

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

# Uruchomienie usług PulseAudio i drukowania
systemctl enable --now avahi-daemon
systemctl enable --now cups.service

# Instalacja yay z GitHub
cd /opt
git clone https://aur.archlinux.org/yay.git
chown -R $USER_NAME:$USER_NAME yay
cd yay
sudo -u $USER_NAME makepkg -si --noconfirm

# Instalacja Catppuccin Mocha GTK za pomocą yay
sudo -u $USER_NAME yay -S --noconfirm catppuccin-gtk-theme-mocha

# Pobranie i instalacja czcionki FiraCode Nerd Font
mkdir -p /usr/share/fonts/FiraCode
curl -fLo "/usr/share/fonts/FiraCode/FiraCode-Nerd-Font-Regular.ttf" \
    https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/FiraCode.zip
unzip FiraCode.zip -d /usr/share/fonts/FiraCode/

# Aktualizacja czcionek
fc-cache -fv

# Ustawienie motywu dla GTK2, GTK3 i GTK4
mkdir -p /home/$USER_NAME/.config/gtk-3.0/
echo "[Settings]" > /home/$USER_NAME/.config/gtk-3.0/settings.ini
echo "gtk-theme-name=Catppuccin-Mocha" >> /home/$USER_NAME/.config/gtk-3.0/settings.ini
echo "gtk-font-name=FiraCode Nerd Font 11" >> /home/$USER_NAME/.config/gtk-3.0/settings.ini

# Konfiguracja GTK2
echo 'gtk-theme-name="Catppuccin-Mocha"' > /home/$USER_NAME/.gtkrc-2.0
echo 'gtk-font-name="FiraCode Nerd Font 11"' >> /home/$USER_NAME/.gtkrc-2.0

# Ustawienia dla GTK4
mkdir -p /home/$USER_NAME/.config/gtk-4.0/
echo "[Settings]" > /home/$USER_NAME/.config/gtk-4.0/settings.ini
echo "gtk-theme-name=Catppuccin-Mocha" >> /home/$USER_NAME/.config/gtk-4.0/settings.ini
echo "gtk-font-name=FiraCode Nerd Font 11" >> /home/$USER_NAME/.config/gtk-4.0/settings.ini

chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.config/
chown $USER_NAME:$USER_NAME /home/$USER_NAME/.gtkrc-2.0

EOF

# Odmontowanie partycji
umount -R /mnt

echo "Instalacja zakończona. Możesz teraz uruchomić system."
