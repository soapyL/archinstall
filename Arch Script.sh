#!/bin/bash

# Function to handle errors
handle_error() {
    echo "Error: $1"
    exit 1
}

# Set keyboard layout
localectl set-keymap uk || handle_error "Failed to set keyboard layout."
loadkeys gb || handle_error "Failed to load keyboard layout."

# Check firmware size
fw_size=$(cat /sys/firmware/efi/fw_platform_size)
if [ "$fw_size" -ne 64 ]; then
    handle_error "Firmware size is not 64-bit, please check your system."
fi

# Connect to internet
iwctl station wlan0 connect BTWholeHome-X5H --passphrase LVUhrgUJ9puM || handle_error "Failed to connect to the internet."

# Partitioning and mounting (automated)
echo "Partitioning the disk..."
# Check if the disk is currently mounted
if mount | grep /mnt > /dev/null; then
    umount -R /mnt || handle_error "Failed to unmount existing partitions."
fi

# Delete existing partitions and create new ones
echo -e "g\nn\n\n\n+512M\nt\n1\nn\n\n\n\nw" | fdisk /dev/nvme0n1 || handle_error "Failed to partition the disk."

# Format partitions
mkfs.ext4 /dev/nvme0n1p2 || handle_error "Failed to format root partition."
mkfs.fat -F32 /dev/nvme0n1p1 || handle_error "Failed to format boot partition."

# Mount partitions
mount /dev/nvme0n1p2 /mnt || handle_error "Failed to mount root partition."
mkdir -p /mnt/boot/efi || handle_error "Failed to create boot directory."
mount /dev/nvme0n1p1 /mnt/boot/efi || handle_error "Failed to mount boot partition."

# Install Arch Linux base system
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist || handle_error "Failed to rank mirrors."
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
echo "KEYMAP=gb" > /etc/vconsole.conf

# Set hostname
echo "luttus" > /etc/hostname

# Set root password
echo "root:asd123" | chpasswd || handle_error "Failed to set root password."

# Install GRUB bootloader
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB || handle_error "Failed to install GRUB bootloader."
grub-mkconfig -o /boot/grub/grub.cfg || handle_error "Failed to generate GRUB configuration."

# Enable NetworkManager service
systemctl enable NetworkManager || handle_error "Failed to enable NetworkManager service."
EOF

# Unmount partitions
umount -R /mnt || handle_error "Failed to unmount partitions."

# Reboot
echo "Installation completed. Rebooting..."
reboot
