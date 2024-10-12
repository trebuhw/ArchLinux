#!/bin/bash

# Zmienna dla partycji EFI i root
EFI_PART="/dev/sda1"
ROOT_PART="/dev/sda2"

# Montowanie root na /mnt
mount "$ROOT_PART" /mnt

# Tworzenie katalogów dla EFI i boot
mkdir -p /mnt/boot/efi

# Montowanie EFI
mount "$EFI_PART" /mnt/boot/efi

# Tworzenie subwolumenów Btrfs
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@pkg
btrfs subvolume create /mnt/@.snapshots

# Odmontowanie i ponowne montowanie z subwolumenami
umount /mnt
mount -o compress=zstd,noatime,subvol=@ "$ROOT_PART" /mnt
mkdir -p /mnt/{home,var/log,var/cache/pacman/pkg,.snapshots}
mount -o compress=zstd,noatime,subvol=@home "$ROOT_PART" /mnt/home
mount -o compress=zstd,noatime,subvol=@log "$ROOT_PART" /mnt/var/log
mount -o compress=zstd,noatime,subvol=@pkg "$ROOT_PART" /mnt/var/cache/pacman/pkg
mount -o compress=zstd,noatime,subvol=@.snapshots "$ROOT_PART" /mnt/.snapshots

# Instalacja podstawowych pakietów
pacstrap /mnt base linux linux-firmware linux-headers nano btrfs-progs

# Generowanie fstab
genfstab -U /mnt | sed 's/subvol=@/&,compress=zstd,noatime/' >> /mnt/etc/fstab

# Chroot do systemu
arch-chroot /mnt /bin/bash <<EOF
# Strefa czasowa
ln -sf /usr/share/zoneinfo/Europe/Warsaw /etc/localtime
hwclock --systohc

# Ustawienie lokalizacji
echo "LANG=pl_PL.UTF-8" > /etc/locale.conf
sed -i 's/#pl_PL.UTF-8/pl_PL.UTF-8/' /etc/locale.gen
locale-gen

# Nazwa hosta
echo "myhost" > /etc/hostname

# Konfiguracja hosts
cat <<EOL >> /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   myhost.localdomain myhost
EOL

# Instalacja GRUB
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Tworzenie initramfs
mkinitcpio -P

# Hasło dla root
echo "root:hw" | chpasswd

# Tworzenie użytkownika hubert
useradd -m -G wheel hubert
echo "hubert:hw" | chpasswd

# Konfiguracja sudoers
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Włączenie usług
systemctl enable NetworkManager
EOF

# Odmontowanie systemu
umount -R /mnt

echo "Instalacja zakończona. Możesz teraz zrestartować system."
