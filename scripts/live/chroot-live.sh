#!/bin/bash
set -e

source /00-config.sh
rm -f /00-config.sh

info "Fixing DNS"
rm -f /etc/resolv.conf
echo "nameserver 1.1.1.1" > /etc/resolv.conf

apt-get --yes update 2>&1| capture_and_log "apt update"
if [ ${#LIVE_PKGS[@]} -ne 0 ]; then
    apt-get --yes install ${LIVE_PKGS[@]} 2>&1| capture_and_log "install live utilities"
fi

info "Setting up pool"
mkdir -p /iso/pool/main
if [ ${#MAIN_POOL[@]} -ne 0 ]; then
    pushd "/iso/pool/main"
        apt-get --yes download ${MAIN_POOL[@]} 2>&1| capture_and_log "download main pool"
    popd
fi

apt-get --yes install /*.deb
rm -f /*.deb

info "Copying new initrd to /iso"
ACTUAL_INITRD="/boot/$(readlink /boot/initrd.img)"
cp -f "$ACTUAL_INITRD" /iso/initrd.img

info "Setting up casper scripts"
rm -f /usr/share/initramfs-tools/scripts/casper-bottom/01integrity_check
sed -i \
		"s|touch /root/home/\$USERNAME/.config/gnome-initial-setup-done|echo -n \"${GNOME_INITIAL_SETUP_STAMP}\" > /root/home/\$USERNAME/.config/gnome-initial-setup-done|" \
		/usr/share/initramfs-tools/scripts/casper-bottom/52gnome_initial_setup

info "Creating live filesystem manifest"
dpkg-query -W --showformat='${Package}\t${Version}\n' > /manifest

# Clean up any left-behind crap, such as tempfiles and machine-id.
info "Cleaning up data..."
rm -rf /tmp/*
rm -f /var/lib/dbus/machine-id