# archlinux install btrfs

Przed uruchomieniem skryptu arch-install.sh 

1. Utwórz partycje wielkości partycji w zależności od potrzeby.

cfdisk

/dev/sdX1 - /boot/efi - 500MB

/dev/sdX2 - /         - 150GB

2. ustaw zmienne w skrypcie arch-install.sh

ROOT_PASSWORD=""  # Hasło dla roota

USER_NAME=""      # Nazwa użytkownika

USER_PASSWORD=""  # Hasło użytkownika

EFI_PARTITION="/dev/sdX1"  # Partycja EFI, utworzona przed uruchomieniem skryptu

ROOT_PARTITION="/dev/sdX2"  # Partycja root Btrfs, utworzona przed uruchomieniem skryptu
 
