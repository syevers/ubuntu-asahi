#!/bin/bash
set -e

source $(dirname "$(readlink -f "$0")")/00-config.sh
source $(dirname "$(readlink -f "$0")")/00-arm64-cross-compile.sh

# Go back to starting dir on script exit
STARTING_DIR="$PWD"
trap "cd \"$STARTING_DIR\"" EXIT

# Clean up old directories
rm -rf rootfs

# Bootstrap debian rootfs
info "Bootstrapping Pop!_OS with $DEBOOTSTRAP"
mkdir -p cache
eatmydata $DEBOOTSTRAP \
		--arch=arm64 \
		--cache-dir=`pwd`/cache \
		--include initramfs-tools,apt \
		jammy \
		rootfs \
		http://ports.ubuntu.com/ubuntu-ports 2>&1| capture_and_log "bootstrap pop"

cd rootfs

perl -p -i -e 's/root:x:/root::/' etc/passwd

info "Linking systemd to init"
# Link systemd to init.
ln -s lib/systemd/systemd init