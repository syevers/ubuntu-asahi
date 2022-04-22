#!/bin/bash
set -e

UBUNTU_VERSION=22.04
UBUNTU_CODE=jammy

DISTRO_PKGS=(ubuntu-minimal ubuntu-standard pop-desktop)
#LIVE_PKGS=(casper distinst expect gparted pop-installer pop-installer-casper)
LIVE_PKGS=(casper expect gparted)
HOLD_PKGS=(snapd pop-desktop-raspi linux-raspi rpi-eeprom u-boot-rpi)
RM_PKGS=(bus-mozc imagemagick-6.q16 irqbalance mozc-utils-gui pop-installer-session snapd ubuntu-session ubuntu-wallpapers unattended-upgrades xul-ext-ubufox yaru-theme-gnome-shell)
MAIN_POOL=(at dfu-programmer efibootmgr ethtool kernelstub libfl2 lm-sensors pm-utils postfix powermgmt-base python3-debian python3-distro python3-evdev python3-systemd system76-wallpapers xbacklight)

SCRIPTS_DIR="$(dirname "$(readlink -f "$0")")"
BUILD_DIR="${SCRIPTS_DIR}/../build"
CACHE_DIR="${BUILD_DIR}/cache"

ROOTFS_BASE_DIR="${BUILD_DIR}/rootfs.base"
ROOTFS_LIVE_DIR="${BUILD_DIR}/rootfs.live"

ROOTFS_IMG="${BUILD_DIR}/rootfs.img"
EFI_IMG="${BUILD_DIR}/efi.img"
ROOTFS_SQUASHED="${BUILD_DIR}/rootfs.squashfs"

_RED=$(tput setaf 1 || "")
_GREEN=$(tput setaf 2 || "")
_YELLOW=$(tput setaf 3 || "")
_RESET=$(tput sgr0 || "")
_BOLD=$(tput bold || "")
_DIM=$(tput dim || "")

function bold {
	echo "${_BOLD}$@${_RESET}"
}

function info {
	echo "[${_GREEN}${_BOLD}info${_RESET}] $@"
}

function error {
	echo "[${_RED}${_BOLD}error${_RESET}] $@"
}

function warn {
	echo "[${_YELLOW}${_BOLD}warning${_RESET}] $@"
}

function capture_and_log {
	PREFIX="[${_GREEN}${_BOLD}$1${_RESET}] ${_DIM}"
	SUFFIX="${_RESET}"
	while read IN
	do
		echo "${PREFIX}${IN}${SUFFIX}"
	done
}

if [[ "${EUID:-$(id -u)}" != 0 ]]; then
	error "This script must be run as root."
	exit 1
fi

# Source: https://stackoverflow.com/a/17841619
function join_by { local IFS="$1"; shift; echo "$*"; }

if [[ "$(uname -p)" -ne "aarch64" ]]; then
	update-binfmts --enable
fi