# Building from Source

## Prerequisites

- Linux build environment
- `make`
- `wget`
- `squashfs-tools`
- `gcc-aarch64-linux-gnu`
- `cmake`
- `pkg-config`
- `git-core`
- `bc`
- `libssl-dev`

Prefer to run builds in a dockerized environment.

## Quick Start

Build tools and download firmware:

```bash
make tools
make firmware
```

Build basic firmware:

```bash
make build PROFILE=basic OUTPUT_FILE=firmware/U1_basic.bin
```

Build extended firmware:

```bash
make build PROFILE=extended OUTPUT_FILE=firmware/U1_extended.bin
```

## Profiles

The build system supports two profiles:

- `basic` - simple modifications not changing key components of the firmware
- `extended` - extensive modifications changing key components of the firmware

## Overlays

- `basic` - SSH access, USB ethernet support
- `kernel-modules` - Required kernel modules
- `camera-native` - Extensions to camera stack (integration in `fluidd`, ~1hz)
- `camera-new` - Hardware-accelerated camera stack (MPP/VPU)
- `fluidd-upgrade` - Upgrade fluidd with timelapse plugin

## Project Structure

```
.
├── .github/            Automated release builds
├── overlays/           Profile overlay directories
│   ├── basic/          SSH, USB ethernet, udev rules
│   ├── kernel-modules/ Kernel module compilation
│   ├── camera-native/  Extensions to camera stack
│   ├── camera-new/     Hardware-accelerated camera (MPP/VPU)
│   └── fluidd-upgrade/ Fluidd upgrade
├── firmware/           Downloaded and generated firmware files
├── scripts/            Build and modification scripts
├── tmp/                Temporary build artifacts
├── tools/              Firmware manipulation tools
│   ├── rk2918_tools/   Rockchip image tools
│   └── upfile/         Firmware unpacking tool
├── Makefile            Build configuration
└── vars.mk             Firmware version and kernel configuration
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
