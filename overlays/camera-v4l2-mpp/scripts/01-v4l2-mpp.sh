#!/bin/bash

ROOT_DIR="$(realpath "$(dirname "$0")/../../..")"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <rootfs-dir>"
  exit 1
fi

set -eo pipefail

TARGET_DIR="$ROOT_DIR/tmp/v4l2-mpp"
OPENSSL_DIR="$ROOT_DIR/tmp/openssl-aarch64"

if [[ ! -d "$TARGET_DIR" ]]; then
  git clone https://github.com/paxx12/v4l2-mpp.git "$TARGET_DIR" --recursive
  git -C "$TARGET_DIR" checkout bd429bf63542a56499c46c333855994002f0beda
fi

# Build OpenSSL for aarch64 if not already built
if [[ ! -f "$OPENSSL_DIR/lib/libssl.a" ]]; then
  echo ">> Building OpenSSL for aarch64..."
  OPENSSL_VERSION="3.0.15"
  OPENSSL_TARBALL="$ROOT_DIR/tmp/openssl-${OPENSSL_VERSION}.tar.gz"

  if [[ ! -f "$OPENSSL_TARBALL" ]]; then
    wget -O "$OPENSSL_TARBALL" "https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VERSION}/openssl-${OPENSSL_VERSION}.tar.gz"
  fi

  rm -rf "$ROOT_DIR/tmp/openssl-${OPENSSL_VERSION}"
  tar -xzf "$OPENSSL_TARBALL" -C "$ROOT_DIR/tmp"

  cd "$ROOT_DIR/tmp/openssl-${OPENSSL_VERSION}"
  ./Configure linux-aarch64 \
    --cross-compile-prefix=aarch64-linux-gnu- \
    --prefix="$OPENSSL_DIR" \
    no-shared \
    no-tests
  make -j$(nproc)
  make install_sw
  cd "$ROOT_DIR"
fi

# Cross-compile for aarch64 (ARM64) - set after OpenSSL build to avoid prefix doubling
export CC=aarch64-linux-gnu-gcc
export CXX=aarch64-linux-gnu-g++
export CROSS_COMPILE=aarch64-linux-gnu-

# Create cmake toolchain file for cross-compilation
TOOLCHAIN_FILE="$TARGET_DIR/aarch64-toolchain.cmake"
cat > "$TOOLCHAIN_FILE" << EOF
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)

# OpenSSL paths for aarch64 (built from source)
set(OPENSSL_ROOT_DIR "$OPENSSL_DIR")
set(OPENSSL_INCLUDE_DIR "$OPENSSL_DIR/include")
set(OPENSSL_CRYPTO_LIBRARY "$OPENSSL_DIR/lib/libcrypto.a")
set(OPENSSL_SSL_LIBRARY "$OPENSSL_DIR/lib/libssl.a")
set(OPENSSL_USE_STATIC_LIBS TRUE)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
EOF

cd "$TARGET_DIR"

echo ">> Compiling MPP dependency (hardware acceleration)..."
./deps/compile_mpp.sh

echo ">> Compiling libdatachannel (WebRTC)..."
cd "$TARGET_DIR/deps/libdatachannel"
cmake -S . -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE" \
  -DNO_WEBSOCKET=ON \
  -DNO_EXAMPLES=ON \
  -DNO_TESTS=ON \
  -DUSE_NICE=OFF \
  -DBUILD_SHARED_LIBS=OFF
make -C build -j$(nproc)

# Create symlinks for static libraries (v4l2-mpp expects specific names)
if [ -f build/libdatachannel.a ] && [ ! -f build/libdatachannel-static.a ]; then
  ln -sf libdatachannel.a build/libdatachannel-static.a
fi
if [ -f build/deps/libjuice/libjuice.a ] && [ ! -f build/deps/libjuice/libjuice-static.a ]; then
  ln -sf libjuice.a build/deps/libjuice/libjuice-static.a
fi

# Copy OpenSSL libraries to libdatachannel build dir (linker expects them there)
cp "$OPENSSL_DIR/lib/libcrypto.a" build/
cp "$OPENSSL_DIR/lib/libssl.a" build/

cd "$TARGET_DIR"

# Fix link order in stream-webrtc Makefile (libssl must come before libcrypto)
sed -i 's/-lcrypto -lssl/-lssl -lcrypto -ldl/g' apps/stream-webrtc/Makefile

echo ">> Compiling v4l2-mpp applications..."
make -C "$TARGET_DIR" install DESTDIR="$1"
