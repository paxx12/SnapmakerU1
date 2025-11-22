#!/bin/bash

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <patch-name> <file-changed-paths>"
  echo "Example: $0 02-disable-wlan-power-save /path/to/02-disable-wlan-power-save.patch"
  exit 1
fi

set -xeo pipefail

if [[ ! -d tmp/extracted/rootfs.original ]]; then
  unsquashfs -d tmp/extracted/rootfs.original tmp/extracted/rk-unpacked/rootfs.img
fi

PATCH_NAME="$1"
shift

for patch_file; do
  diff \
    --label "a/$patch_file" \
    --label "b/$patch_file" \
    -uNr tmp/extracted/{rootfs.original,rootfs}/"$patch_file"
done > "custom/patches/$PATCH_NAME.patch"
