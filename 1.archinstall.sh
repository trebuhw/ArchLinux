#!/bin/bash

# Ustawienia zmiennych
EFI_PARTITION="/dev/sda3"  # Partycja EFI, ustawiona przed uruchomieniem
ROOT_PARTITION="/dev/sda4"  # Partycja root Btrfs, ustawiona przed uruchomieniem

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

archinstall