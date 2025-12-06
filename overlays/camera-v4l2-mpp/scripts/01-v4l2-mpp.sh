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

# Clean up any existing build artifacts that may be wrong architecture
# This prevents issues when tmp directory is reused between native and cross builds
clean_wrong_arch_builds() {
  local check_file="$1"
  if [[ -f "$check_file" ]]; then
    local arch=$(file "$check_file" | grep -o 'ARM aarch64\|x86-64' || true)
    if [[ "$arch" != "ARM aarch64" ]]; then
      echo ">> Detected non-aarch64 build artifacts, cleaning..."
      rm -rf "$TARGET_DIR/deps/mpp/build"
      rm -rf "$TARGET_DIR/deps/libdatachannel/build"
      rm -rf "$TARGET_DIR/deps/live/usr-local"
      rm -rf "$OPENSSL_DIR"
      make -C "$TARGET_DIR" clean 2>/dev/null || true
    fi
  fi
}

# Check a known build artifact for architecture
clean_wrong_arch_builds "$TARGET_DIR/deps/mpp/build/mpp/libmpp.so"

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

# Cross-compile liveMedia for aarch64 (RTSP support)
LIVE_DIR="$TARGET_DIR/deps/live"
LIVE_INSTALL="$TARGET_DIR/deps/live/usr-local"
if [[ ! -f "$LIVE_INSTALL/lib/libliveMedia.a" ]] || ! file "$LIVE_INSTALL/lib/libliveMedia.a" | grep -q "aarch64"; then
  echo ">> Compiling liveMedia (RTSP) for aarch64..."

  # Download liveMedia if not present
  if [[ ! -d "$LIVE_DIR/live-src" ]]; then
    LIVE_TARBALL="$ROOT_DIR/tmp/live555-latest.tar.gz"
    # Always fetch latest to ensure we get a working version
    wget -O "$LIVE_TARBALL" "http://www.live555.com/liveMedia/public/live555-latest.tar.gz"
    rm -rf "$LIVE_DIR/live"
    tar -xzf "$LIVE_TARBALL" -C "$LIVE_DIR"
    mv "$LIVE_DIR/live" "$LIVE_DIR/live-src"
  fi

  cd "$LIVE_DIR/live-src"

  # Create aarch64 cross-compile config (note: no quotes on EOFCONFIG to allow variable expansion)
  cat > config.linux-aarch64 << EOFCONFIG
COMPILE_OPTS =		\$(INCLUDES) -I. -I$OPENSSL_DIR/include -O2 -DSOCKLEN_T=socklen_t -D_LARGEFILE_SOURCE=1 -D_FILE_OFFSET_BITS=64
C =			c
C_COMPILER =		aarch64-linux-gnu-gcc
C_FLAGS =		\$(COMPILE_OPTS)
CPP =			cpp
CPLUSPLUS_COMPILER =	aarch64-linux-gnu-g++
CPLUSPLUS_FLAGS =	\$(COMPILE_OPTS) -Wall -DBSD=1 -std=c++20
OBJ =			o
LINK =			aarch64-linux-gnu-g++ -o
LINK_OPTS =		-L. -L$OPENSSL_DIR/lib
CONSOLE_LINK_OPTS =	\$(LINK_OPTS)
LIBRARY_LINK =		aarch64-linux-gnu-ar cr 
LIBRARY_LINK_OPTS =
LIB_SUFFIX =		a
LIBS_FOR_CONSOLE_APPLICATION = -lssl -lcrypto
LIBS_FOR_GUI_APPLICATION =
EXE =
EOFCONFIG

  ./genMakefiles linux-aarch64
  make -j$(nproc)

  # Install to usr-local
  rm -rf "$LIVE_INSTALL"
  mkdir -p "$LIVE_INSTALL/lib" "$LIVE_INSTALL/include"
  cp */lib*.a "$LIVE_INSTALL/lib/"
  for dir in liveMedia groupsock BasicUsageEnvironment UsageEnvironment; do
    mkdir -p "$LIVE_INSTALL/include/$dir"
    cp $dir/include/*.hh "$LIVE_INSTALL/include/$dir/" 2>/dev/null || true
    cp $dir/include/*.h "$LIVE_INSTALL/include/$dir/" 2>/dev/null || true
  done

  cd "$TARGET_DIR"
fi

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

# Add cross-compiled OpenSSL include path for stream-rtsp (liveMedia uses OpenSSL for TLS)
export CPLUS_INCLUDE_PATH="$OPENSSL_DIR/include:$CPLUS_INCLUDE_PATH"
export C_INCLUDE_PATH="$OPENSSL_DIR/include:$C_INCLUDE_PATH"
export LIBRARY_PATH="$OPENSSL_DIR/lib:$LIBRARY_PATH"

# Copy OpenSSL libs to liveMedia install dir (stream-rtsp links from there)
cp "$OPENSSL_DIR/lib/libssl.a" "$LIVE_INSTALL/lib/"
cp "$OPENSSL_DIR/lib/libcrypto.a" "$LIVE_INSTALL/lib/"

echo ">> Compiling v4l2-mpp applications..."
make -C "$TARGET_DIR" install DESTDIR="$1"
