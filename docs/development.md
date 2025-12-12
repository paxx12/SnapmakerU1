# Building from Source

## Prerequisites

- Linux build environment (Ubuntu/Debian recommended, WSL2 supported)
- `build-essential` (includes `make`, `gcc`)
- `wget`
- `unzip`
- `squashfs-tools`
- `gcc-aarch64-linux-gnu` (C cross-compiler for ARM64)
- `g++-aarch64-linux-gnu` (C++ cross-compiler for ARM64)
- `cmake`
- `pkg-config`
- `git-core`
- `bc`
- `libssl-dev`
- `flex`
- `bison`

### Install all dependencies (Ubuntu/Debian)

```bash
sudo apt update
sudo apt install -y build-essential cmake gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
    squashfs-tools git-core bc libssl-dev pkg-config wget unzip flex bison
```

Prefer to run builds in a dockerized environment.

**Note:** OpenSSL for aarch64 is automatically built from source during the build process for WebRTC support.

## Quick Start

Build tools and download firmware:

```bash
make tools
make firmware
```

Build basic firmware:

```bash
sudo make build PROFILE=basic OUTPUT_FILE=firmware/U1_basic.bin
```

Build extended firmware:

```bash
sudo make build PROFILE=extended OUTPUT_FILE=firmware/U1_extended.bin
```

**Note:** The build process requires root privileges due to squashfs root filesystem operations.

## Profiles

The build system supports two profiles:

- `basic` - simple modifications not changing key components of the firmware
- `extended` - extensive modifications with Fluidd web UI (includes timelapse)

For experimental Mainsail support, see [Mainsail Web UI](mainsail.md).

## Overlays

### Core Overlays

- `store-version` - Store firmware version information
- `kernel-modules` - Compile and install required kernel modules

### Feature Overlays

- `enable-ssh` - Enable SSH access
- `enable-usb-eth-hotplug` - USB ethernet adapter hot-plug support
- `disable-wlan-power-save` - Disable WLAN power saving
- `enable-native-camera-fluidd` - Native camera integration in Fluidd (~1Hz)
- `camera-v4l2-mpp` - Hardware-accelerated camera stack (MPP/VPU)
- `stub-fluidd-timelapse` - Moonraker-timelapse component for Fluidd/Mainsail
- `fluidd-upgrade` - Upgrade Fluidd to v1.35.0 with timelapse plugin
- `mainsail` - Install Mainsail web UI v2.15.0 (replaces Fluidd)
- `enable-klipper-includes` - Custom Klipper and Moonraker configuration includes

## Project Structure

```
.
├── .github/                     Automated release builds
├── overlays/                    Profile overlay directories
│   ├── store-version/           Store firmware version
│   ├── kernel-modules/          Kernel module compilation
│   ├── enable-ssh/              SSH access configuration
│   ├── enable-usb-eth-hotplug/  USB ethernet hot-plug
│   ├── disable-wlan-power-save/ Disable WLAN power saving
│   ├── enable-native-camera-fluidd/ Native camera for Fluidd
│   ├── camera-v4l2-mpp/         Hardware-accelerated camera (MPP/VPU)
│   ├── stub-fluidd-timelapse/   Moonraker-timelapse component
│   ├── fluidd-upgrade/          Fluidd upgrade
│   ├── mainsail/                Mainsail web UI
│   └── enable-klipper-includes/ Custom config includes
├── firmware/                    Downloaded and generated firmware files
├── scripts/                     Build and modification scripts
├── tmp/                         Temporary build artifacts
├── tools/                       Firmware manipulation tools
│   ├── rk2918_tools/            Rockchip image tools
│   └── upfile/                  Firmware unpacking tool
├── Makefile                     Build configuration
└── vars.mk                      Firmware version and kernel configuration
```

## Configuration

Edit `vars.mk` to configure base firmware and kernel.

## Extract Firmware

To extract and examine the base firmware:

```bash
make extract
```

Output: `tmp/extracted/`

## Release Process

The project uses GitHub Actions for automated releases:

1. Changes pushed to `main` trigger a pre-release build
2. Both basic and extended firmwares are built
3. Version is auto-incremented using `scripts/next_version.sh`
4. Release artifacts are published to GitHub Releases

## Tools

### rk2918_tools

- `afptool` - Android firmware package tool
- `img_maker` - Create Rockchip images
- `img_unpack` - Unpack Rockchip images
- `mkkrnlimg` - Create kernel images

### upfile

Firmware unpacking utility for Snapmaker update files.
