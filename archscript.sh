#!/bin/bash

# Function to handle errors
handle_error() {
    echo "Error: $1"
    exit 1
}

lsblk
echo "Please enter which drive to use: "
read drive

if [ ! -b "/dev/${drive}" ]; then
    handle_error "Drive does not exist"
fi

if [[ "$drive" == nvme* ]]; then
    drive_type="nvme"
elif [[ "$drive" == sd* ]]; then
    drive_type="sda"
else
    handle_error "Unsupported drive tpye"
fi

# Set keyboard layout
localectl set-keymap uk || handle_error "Failed to set keyboard layout."
loadkeys uk || handle_error "Failed to load keyboard layout."

# Connect to internet
iwctl station wlan0 connect BTWholeHome-X5H --passphrase LVUhrgUJ9puM || handle_error "Failed to connect to the internet."

# Partitioning and mounting (automated)
echo "Partitioning the disk..."
# Check if the disk is currently mounted
if mount | grep /mnt > /dev/null; then
    umount -R /mnt || handle_error "Failed to unmount existing partitions."
fi

if [ "$drive_type" == "nvme" ]; then
    echo -e "g\nn\n\n\n+512M\nt\n1\nn\n\n\n\nw" | fdisk "/dev/${drive}" || handle_error "Failed to partition the disk."
    root_partition="/dev/${drive}p2"
    efi_partition="/dev/${drive}p1"
elif [ "$drive_type" == "sda" ]; then
    echo -e "g\nn\n\n\n+512M\nt\n1\nn\n\n\n\nw" | fdisk "/dev/${drive}" || handle_error "Failed to partition the disk."
    root_partition="/dev/${drive}2"
    efi_partition="/dev/${drive}1"
else
    handle_error "Unsupported drive type. Only nvme and sda drives are supported."
fi

# Format partitions
mkfs.ext4 "$root_partition" || handle_error "Failed to format root partition."
mkfs.fat -F32 "$efi_partition" || handle_error "Failed to format boot partition."

# Mount partitions
mount "$root_partition" /mnt || handle_error "Failed to mount root partition."
mkdir -p /mnt/boot || handle_error "Failed to create boot directory."
mount "$efi_partition" /mnt/boot || handle_error "Failed to mount boot partition."

# Install Arch Linux base system
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

# Install reflector package which includes rankmirrors
pacman -Sy reflector --noconfirm || handle_error "Failed to install reflector."

# Use reflector to rank mirrors
reflector --verbose -l 5 --sort rate --save /etc/pacman.d/mirrorlist || handle_error "Failed to rank mirrors."

# Install packages
pacstrap /mnt base linux linux-lts linux-firmware amd-ucode networkmanager nano grub efibootmgr || handle_error "Failed to install Arch Linux base system."

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab || handle_error "Failed to generate fstab."

# Chroot into the installed system
arch-chroot /mnt /bin/bash <<EOF
# Set timezone
ln -sf /usr/share/zoneinfo/GB/London /etc/localtime || handle_error "Failed to set timezone."
hwclock --systohc || handle_error "Failed to sync hardware clock."

# Locale settings
sed -i 's/#en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen || handle_error "Failed to set locale."
locale-gen || handle_error "Failed to generate locale."
echo "LANG=en_GB.UTF-8" > /etc/locale.conf
echo "KEYMAP=uk" > /etc/vconsole.conf

# Set hostname
echo "luttus" > /etc/hostname

# Set root password
echo "root:asd123" | chpasswd || handle_error "Failed to set root password."

# Install GRUB bootloader
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB || handle_error "Failed to install GRUB bootloader."
grub-mkconfig -o /boot/grub/grub.cfg || handle_error "Failed to generate GRUB configuration."

# Enable NetworkManager service
systemctl enable NetworkManager || handle_error "Failed to enable NetworkManager service."
EOF

# Unmount partitions
umount -R /mnt || handle_error "Failed to unmount partitions."

# Reboot
echo "Installation completed. Rebooting..."
reboot
