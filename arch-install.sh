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

# Formatowanie partycji
mkfs.fat -F32 "$EFI_PARTITION"
mkfs.btrfs "$ROOT_PARTITION"

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

# Instalacja systemu
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

# Instalacja niezbędnych pakietów
pacman -S --noconfirm grub efibootmgr networkmanager xfce4 xfce4-goodies lightdm lightdm-gtk-greeter linux-headers xorg-server pulseaudio cups

# Instalacja dodatkowych programów przez pacman
pacman -S --noconfirm adobe-source-sans-fonts aic94xx-firmware alacritty arandr arc-gtk-theme awesome-terminal-fonts bash-completion bat brightnessctl btop cpuid curl dconf-editor downgrade duf dunst fastfetch feh file-roller firefox fish flameshot font-manager fzf galculator gcolor3 geany gimp git gparted gvfs-smb gzip hardinfo-gtk3 hddtemp htop hw-probe i3lock kitty libreoffice-fresh libreoffice-fresh-pl lm_sensors lsd lshw man-db man-pages meld mkinitcpio-firmware mlocate most neovim network-manager-applet networkmanager-openvpn ntp numlockx nwg-look p7zip papirus-icon-theme parcellite pavucontrol pdfarranger picom polkit polkit-gnome ranger rclone ripgrep rofi rsync speedtest-cli-git starship sxhkd sxiv system-config-printer thunar thunar-volman thunderbird time tldr tlp trash-cli tree ttf-jetbrains-mono-nerd ueberzug unrar unzip vim vlc wget wttr xclip xcolor xdg-user-dirs xfce4-notifyd xorg-xinit xorg-xkill xorg-xrandr xorg-xsetroot zathura zoxide

# Instalacja yay
cd /opt
git clone https://aur.archlinux.org/yay.git
chown -R hubert:users ./yay
cd yay
sudo -u hubert makepkg -si --noconfirm

# Instalacja pakietów z AUR przez yay
sudo -u hubert yay -S --noconfirm catppuccin-gtk-theme-mocha

# Pobranie i skopiowanie plików z repozytorium dotfiles
sudo -u hubert git clone https://github.com/trebuhw/dotfiles.git /home/hubert/dotfiles
cp -r /home/hubert/dotfiles/.config/* /home/hubert/.config/

# Konfiguracja bootloadera GRUB
grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Tworzenie initramfs
mkinitcpio -P

# Włączanie usług
systemctl enable NetworkManager
systemctl enable lightdm
systemctl enable cups

EOF

# Odmontowanie partycji
umount -R /mnt

echo "Instalacja zakończona. Możesz teraz uruchomić system."
