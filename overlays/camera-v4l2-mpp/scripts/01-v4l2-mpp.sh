#!/bin/bash

ROOT_DIR="$(realpath "$(dirname "$0")/../../..")"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <rootfs-dir>"
  exit 1
fi

set -eo pipefail

TARGET_DIR="$ROOT_DIR/tmp/v4l2-mpp"

if [[ ! -d "$TARGET_DIR" ]]; then
  git clone https://github.com/paxx12/v4l2-mpp.git "$TARGET_DIR" --recursive
  git -C "$TARGET_DIR" checkout bd429bf63542a56499c46c333855994002f0beda
fi

echo ">> Compiling dependencies..."
make -C "$TARGET_DIR" deps

echo ">> Compiling v4l2-mpp applications..."
make -C "$TARGET_DIR" install DESTDIR="$1"
