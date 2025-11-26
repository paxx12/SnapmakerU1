# Camera Support

**Available in: Extended firmware only**

The extended firmware includes hardware-accelerated camera support.

## Features

- Hardware-accelerated camera stack (Rockchip MPP/VPU)
- v4l2-mpp: MIPI CSI and USB camera support
- WebRTC low-latency streaming
- Hot-plug detection for USB cameras

## Accessing Cameras

### Internal Camera

Access the native camera at:
```
http://<printer-ip>/webcam/
```

### USB Camera

Access USB camera at:
```
http://<printer-ip>/webcam2/
```

## Disabling Native Camera

The native camera is enabled by default in extended firmware.
To disable it, create:

```bash
touch /oem/.camera-native
```

## Timelapse Support

Fluidd timelapse plugin is included (no settings support).

Note: Time-lapses are not available via mobile app in cloud mode.
