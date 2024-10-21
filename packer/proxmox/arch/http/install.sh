#!/usr/bin/env bash

# Stop on ERROR
set -eu

USERNAME="root"
PASSWORD=$1
HOSTNAME=arch

SWAP_SIZE=$2

COUNTRY=$3
TIMEZONE=$4
LANGUAGE=$5
OPTIONAL_PACKAGES=$6

echo ">>>> CHECKING INTERNET CONNECTION..."
ping -q -c 1 archlinux.org >/dev/null || { echo "No Internet Connection!; "exit 1; }

echo ">>>> SETTING TIMEZONE TO ${TIMEZONE}"
timedatectl set-timezone $TIMEZONE

echo ">>>> SETTING TEMPORARY PACMAN MIRRORS TO ${COUNTRY}..."
curl -s "https://archlinux.org/mirrorlist/?${COUNTRY}&protocol=https&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' > /etc/pacman.d/mirrorlist

echo ">>>> FORMATTING DRIVE..."
sgdisk -g /dev/sda
/usr/bin/sgdisk --new=1:0:+400M --typecode=1:ef00 --new=2:0:0 --typecode=2:8e00 /dev/sda
mkfs.fat -F 32 /dev/sda1
pvcreate /dev/sda2
vgcreate vg0 /dev/sda2
lvcreate -L 2G -n lv-swap vg0
lvcreate -l 100%FREE -n lv-root vg0
mkswap /dev/vg0/lv-swap
mkfs.ext4 /dev/vg0/lv-root

echo ">>>> MOUNTING PARTITIONS..."
mount /dev/vg0/lv-root /mnt
mount --mkdir /dev/sda1 /mnt/boot
swapon /dev/vg0/lv-swap

echo ">>>> INSTALLING ARCH..."
pacstrap -K /mnt base linux linux-firmware

echo "#### INSTALLING ADDITIONAL PACKAGES..."
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5\nILoveCandy/g' /mnt/etc/pacman.conf
sed -i 's/#Color/Color/g' /mnt/etc/pacman.conf
/usr/bin/arch-chroot /mnt pacman -S --noconfirm git base-devel lvm2 cloud-guest-utils cloud-init openssh networkmanager qemu-guest-agent gptfdisk syslinux pacman-contrib $OPTIONAL_PACKAGES

echo ">>>> UPDATING MIRRORLIST"
curl -s "https://archlinux.org/mirrorlist/?${COUNTRY}&protocol=https&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | /usr/bin/arch-chroot /mnt rankmirrors -n 5 - > /mnt/etc/pacman.d/mirrorlist

echo ">>>> SETTING LOCALE..."
/usr/bin/arch-chroot /mnt locale-gen
/usr/bin/arch-chroot /mnt echo "LANG=${LANGUAGE}" > /etc/locale.conf
echo $HOSTNAME > /mnt/etc/hostname

echo ">>>> MODYFING MKINITCPIO..." 
/usr/bin/arch-chroot /mnt sed -i '/^HOOKS/s/\(block \)\(.*filesystems\)/\1encrypt lvm2 \2/' /etc/mkinitcpio.conf
/usr/bin/arch-chroot /mnt mkinitcpio -p linux

echo ">>>> ENABLING SERVICES..."
/usr/bin/arch-chroot /mnt systemctl enable NetworkManager
/usr/bin/arch-chroot /mnt systemctl enable sshd

echo ">>>> ALLOWING TEMPORARY ROOT LOGIN..."
/usr/bin/arch-chroot /mnt sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
echo "root:$PASSWORD" | chpasswd --root /mnt

echo ">>>> INSTALLING BOOTLOADER..."
/usr/bin/arch-chroot /mnt bootctl install
genfstab -U /mnt >> /mnt/etc/fstab
echo "default arch.conf" > /mnt/boot/loader/loader.conf
FILE="/mnt/boot/loader/entries/arch.conf"
UUID=$(blkid | grep root | cut -d '"' -f 2)
echo "title   Arch Linux" >> "$FILE"
echo "linux   /vmlinuz-linux" >> "$FILE"
echo "initrd  /initramfs-linux.img" >> "$FILE"
echo "options root=/dev/vg0/lv-root rw" >> "$FILE"

echo ">>>> INSTALLATION COMPLETE, REBOOTING..."
sleep 3
/sbin/reboot