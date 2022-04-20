#!/bin/bash
set -e

source /00-config.sh
rm -f /00-config.sh

if [ ! -f /run/systemd/resolve/stub-resolv.conf ]
then
	info "Fixing DNS"
    mkdir -p /run/systemd/resolve
    echo "nameserver 1.1.1.1" > /run/systemd/resolve/stub-resolv.conf
fi

#info "Filling in /etc/fstab"
#ROOTFS_UUID=$(cat /rootfs.uuid)
#EFI_UUID=$(cat /efi.uuid)
#sed -i "s/POP_UUID/${ROOTFS_UUID}/" /etc/fstab
#sed -i "s/EFI_UUID/${EFI_UUID}/" /etc/fstab
#rm -f /rootfs.uuid /efi.uuid

apt-get --yes update 2>&1| capture_and_log "apt update"
apt-mark hold snapd pop-desktop-raspi linux-raspi rpi-eeprom u-boot-rpi 2>&1| capture_and_log "hold packages"

apt-get --yes install pop-desktop 2>&1| capture_and_log "install pop-desktop"
apt-get --yes dist-upgrade --allow-downgrades 2>&1| capture_and_log "apt upgrade"

info "Cleaning up old boot files"
rm -rf /boot/efi/EFI/{Pop_OS,Ubuntu}-

apt-get --yes autoremove --purge 2>&1| capture_and_log "apt autoremove"
apt-get --yes autoclean 2>&1| capture_and_log "apt autoclean"
apt-get --yes clean 2>&1| capture_and_log "apt clean"

info "Installing systemd-boot"
bootctl install --no-variables --esp-path=/boot/efi 2>&1| capture_and_log "bootctl install"

info "Installing kernelstub"
apt-get --yes install kernelstub 2>&1| capture_and_log "install kernelstub"

info "Creating systemd-boot entry"
cat <<EOF >> /boot/efi/loader/entries/Pop_OS-current.conf
title   Pop!_OS
linux   /vmlinuz
initrd  /initrd.img
options root=UUID=${ROOTFS_UUID} rw quiet splash
EOF

info "Copying kernel and initrd to EFI"
ACTUAL_VMLINUZ="/boot/$(readlink /boot/vmlinuz)"
ACTUAL_INITRD="/boot/$(readlink /boot/initrd.img)"
cp "$ACTUAL_VMLINUZ" /tmp/vmlinuz.gz
gzip -d /tmp/vmlinuz.gz
sudo cp -f /tmp/vmlinuz /boot/efi/vmlinuz
sudo rm -f /tmp/vmlinuz
cp "$ACTUAL_INITRD" /boot/efi/initrd.img

info "Enabling first-boot service"
systemctl enable first-boot 2>&1| capture_and_log "systemctl enable first-boot"

info "Creating missing NetworkManager config"
touch /etc/NetworkManager/conf.d/10-globally-managed-devices.conf

info "Updating AppStream cache"
/usr/bin/appstreamcli refresh-cache --force 2>&1 | capture_and_log "update appstream cache"

touch "Cleaning up data..."
rm -rf /tmp/*
rm -f /var/lib/dbus/machine-id