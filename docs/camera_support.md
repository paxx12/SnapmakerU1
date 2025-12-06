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

You need to add USB camera in Fluidd. Use the following
settings for the best performance:

<img src="images/usb_cam.png" alt="Fluidd USB camera" width="300"/>

## Configuring Camera Streaming

The internal camera defaults to WebRTC streaming for low latency. You can switch between streaming modes via SSH.

### Switch to MJPEG Adaptive (better compatibility)

```bash
cat > /home/lava/printer_data/config/moonraker/webcam.cfg << 'EOF'
[webcam case]
service: mjpegstreamer-adaptive
stream_url: /webcam/stream.mjpg
snapshot_url: /webcam/snapshot.jpg
aspect_ratio: 16:9
EOF
/etc/init.d/S61moonraker restart
```

### Switch to WebRTC (low latency)

```bash
cat > /home/lava/printer_data/config/moonraker/webcam.cfg << 'EOF'
[webcam case]
service: webrtc-camerastreamer
stream_url: /webcam/webrtc
snapshot_url: /webcam/snapshot.jpg
aspect_ratio: 16:9
EOF
/etc/init.d/S61moonraker restart
```

### Available Services

| Service | Description |
|---------|-------------|
| `webrtc-camerastreamer` | Low-latency WebRTC (recommended) |
| `mjpegstreamer-adaptive` | MJPEG with adaptive framerate |
| `mjpegstreamer` | Basic MJPEG streaming |
| `ipstream` | Direct stream embedding |

## Enable Snapmaker's Camera Stack

Only one Camera Stack can be operational at the given moment.
Thus Snapmaker's Camera Stack is disabled by default in extended firmware.
To enable it, create:

```bash
touch /oem/.camera-native
```

## Timelapse Support

**Available in: Extended firmware**

Timelapse functionality uses Snapmaker's OrcaSlicer integration. The firmware includes stub components to prevent UI errors in Fluidd/Mainsail.
