#!/usr/bin/env bash

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <rootfs> <cmd> [args...]"
  exit 1
fi

ROOTFS="$(realpath "$1")"
shift

cd "$ROOTFS"

[[ -e ./etc/resolv.conf ]] && mv ./etc/resolv.conf{,.bak}
echo "nameserver 1.1.1.1" > ./etc/resolv.conf

cleanup() {
  rm -f ./etc/resolv.conf
  [[ -e ./etc/resolv.conf.bak ]] && mv ./etc/resolv.conf{.bak,}
  umount -l ./proc
  umount -l ./sys
  umount -l ./dev
}

trap cleanup EXIT

mount -t proc /proc ./proc
mount --bind /sys ./sys
mount --bind /dev ./dev

chroot "$ROOTFS" "$@"
