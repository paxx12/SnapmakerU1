#!/bin/bash

set -eo pipefail

ROOT_DIR="$(realpath "$(dirname "$0")/../../../..")"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <rootfs-dir>"
  exit 1
fi

echo ">> Installing latest Entware installer"

TARGET_DIR="$1/usr/local/bin"
TMP_DIR="$ROOT_DIR/tmp"
FILENAME=opkg
URL=https://bin.entware.net/aarch64-k3.10/installer/opkg
BIN_SHA256=1c59274bd25080b869f376788795f5319d0d22e91f325f74ce98a7d596f68015

mkdir -p "$TARGET_DIR"
if [[ ! -f "$TARGET_DIR/$FILENAME" ]]; then
  echo ">> Downloading $FILENAME..."
  wget -O "$TMP_DIR/$FILENAME" "$URL"
fi

echo ">> Verifying $TMP_DIR/$FILENAME checksum..."
if ! echo "$BIN_SHA256  $TMP_DIR/$FILENAME" | sha256sum --check --status; then
  echo "[!] SHA256 checksum mismatch for $FILENAME"
  exit 1
fi

mv "$TMP_DIR/$FILENAME" "$TARGET_DIR/$FILENAME"
chmod +x "$TARGET_DIR/$FILENAME"

echo ">> $FILENAME installed to $TARGET_DIR"
