#!/bin/bash

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

localectl set-keymap uk || handle_error "Failed to set keyboard layout."
loadkeys uk || handle_error "Failed to load keyboard layout."

iwctl station wlan0 connect BTWholeHome-X5H --passphrase LVUhrgUJ9puM || handle_error "Failed to connect to the internet."

echo "Partitioning the disk..."
if mount | grep /mnt > /dev/null; then
    umount -R /mnt || handle_error "Failed to unmount existing partitions."
fi

if [ "$drive_type" == "nvme" ]; then
    echo -e "g\nn\n\n\n+512M\nt\n4\nn\n\n\n\nw" | fdisk "/dev/${drive}" || handle_error "Failed to partition the disk."
    root_partition="/dev/${drive}p2"
    efi_partition="/dev/${drive}p1"
elif [ "$drive_type" == "sda" ]; then
    echo -e "g\nn\n\n\n+512M\nt\n4\nn\n\n\n\nw" | fdisk "/dev/${drive}" || handle_error "Failed to partition the disk."
    root_partition="/dev/${drive}2"
    efi_partition="/dev/${drive}1"
else
    handle_error "Unsupported drive type. Only nvme and sda drives are supported."
fi

mkfs.ext4 "$root_partition" || handle_error "Failed to format root partition."
mkfs.fat -F32 "$efi_partition" || handle_error "Failed to format boot partition."

mount "$root_partition" /mnt || handle_error "Failed to mount root partition."
mkdir -p /mnt/boot || handle_error "Failed to create boot directory."
mount "$efi_partition" /mnt/boot || handle_error "Failed to mount boot partition."

cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

pacman -Sy reflector --noconfirm || handle_error "Failed to install reflector."

reflector --verbose -l 5 --sort rate --save /etc/pacman.d/mirrorlist || handle_error "Failed to rank mirrors."

pacstrap /mnt base linux linux-lts linux-firmware amd-ucode networkmanager nano grub efibootmgr wayland sway wl-clipboard swaybg swayidle swaylock xorg-xwayland alacritty sddm sddm-kcm thunar waybar pulseaudio pavucontrol || handle_error "Failed to install Arch Linux base system."

genfstab -U /mnt >> /mnt/etc/fstab || handle_error "Failed to generate fstab."

arch-chroot /mnt /bin/bash <<EOF
ln -sf /usr/share/zoneinfo/GB/London /etc/localtime || handle_error "Failed to set timezone."
hwclock --systohc || handle_error "Failed to sync hardware clock."

sed -i 's/#en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen || handle_error "Failed to set locale."
locale-gen || handle_error "Failed to generate locale."
echo "LANG=en_GB.UTF-8" > /etc/locale.conf
echo "KEYMAP=uk" > /etc/vconsole.conf

echo "luttus" > /etc/hostname

echo "root:asd123" | chpasswd || handle_error "Failed to set root password."

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB || handle_error "Failed to install GRUB bootloader."
grub-mkconfig -o /boot/grub/grub.cfg || handle_error "Failed to generate GRUB configuration."

systemctl enable NetworkManager || handle_error "Failed to enable NetworkManager service."

mkdir -p ~/.config/sway
cp /etc/sway/config ~/.config/sway/config

systemctl enable sddm
systemctl start sddm

echo '[General]' >> /etc/sddm.conf
echo 'Session=sway.desktop' >> /etc/sddm.conf

mkdir -p /usr/share/wayland-sessions
echo '[Desktop Entry]' >> /usr/share/wayland-sessions/sway.desktop
echo 'Name=Sway' >> /usr/share/wayland-sessions/sway.desktop
echo 'Comment=An i3-compatible Wayland compositor' >> /usr/share/wayland-sessions/sway.desktop
echo 'Exec=sway' >> /usr/share/wayland-sessions/sway.desktop
echo 'Type=Application' >> /usr/share/wayland-sessions/sway.desktop

EOF

umount -R /mnt || handle_error "Failed to unmount partitions."

echo "Installation complete. Rebooting..."
#reboot
