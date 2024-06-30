#!/bin/bash

set -e

if [ -z "$1" ]; then
	echo "error: expecting build ID"
	exit 1
fi

# Fetch artifacts
if [ ! -d "build/build-$1" ]; then
	sudo -u "$SUDO_USER" ./scripts/get-livefs-build.py "$1" "build/build-$1"
fi

# Pack image
cd build
ARTIFACT_DIR="build-$1" ../scripts/livefs-to-usb.sh
 
echo "Done"
