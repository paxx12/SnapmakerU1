# Mainsail Web UI

**Status: Experimental (not an official profile yet)**

The `mainsail` overlay replaces the default Fluidd web interface with [Mainsail](https://docs.mainsail.xyz/), an alternative Klipper web interface.

> **Note**: Mainsail support is currently experimental. The overlays are available but there is no official `extended-mainsail` profile yet. See [Building](#building-with-mainsail) for how to build a custom firmware with Mainsail.

## What is Mainsail?

Mainsail is a modern, responsive web interface for Klipper-based 3D printers. It provides:

- Clean, intuitive user interface
- Real-time printer status monitoring
- G-code file management and uploads
- Webcam integration with WebRTC support
- Macro management and execution
- Bed mesh visualization
- Temperature graphs and controls
- Console for direct Klipper commands

## Features

- Mainsail v2.15.0 web interface
- Full Moonraker API integration
- Hardware-accelerated camera streaming (WebRTC/MJPEG)
- Custom Klipper/Moonraker configuration includes
- SSH access for advanced users
- USB ethernet adapter support

### Camera Support

The Mainsail overlay includes the same camera stack as the extended firmware:

- Internal MIPI camera support
- USB camera support (when enabled)
- WebRTC low-latency streaming (default)
- MJPEG streaming (alternative)

## Accessing Mainsail

After flashing the firmware:

1. Connect to the same network as your printer
2. Open a web browser
3. Navigate to `http://<printer-ip>/`
4. Mainsail will load automatically

To find your printer's IP address:
- Check your router's DHCP client list
- Use the Snapmaker mobile app
- Connect via SSH and run `ip addr`

## Comparison: Mainsail vs Fluidd

| Feature | Mainsail | Fluidd |
|---------|----------|--------|
| Interface Style | Modern, grid-based | Clean, minimal |
| Webcam Support | Excellent | Excellent |
| Bed Mesh Viewer | Yes | Yes |
| Macro Management | Advanced | Good |
| Multi-printer | Yes | Limited |
| Customization | Highly customizable | Moderate |
| Mobile Support | Responsive | Responsive |

## Building with Mainsail

Since Mainsail is experimental, you need to specify overlays manually:

```bash
# Build firmware with Mainsail (instead of Fluidd)
sudo make build OUTPUT_FILE=firmware/U1_mainsail.bin \
  OVERLAYS="store-version kernel-modules enable-ssh enable-usb-eth-hotplug disable-wlan-power-save stub-fluidd-timelapse stub-mainsail-timelapse camera-v4l2-mpp mainsail enable-klipper-includes"
```

## Configuration

Mainsail uses the same Moonraker API as Fluidd, so all existing configurations work:

- Klipper config: `/home/lava/origin_printer_data/config/printer.cfg`
- Moonraker config: `/home/lava/origin_printer_data/config/moonraker.conf`
- Custom includes: See [Klipper Includes](klipper_includes.md)

### Camera Configuration

Camera configuration is stored in `moonraker/webcam.cfg`. The default uses WebRTC for low latency.

To change the camera streaming mode, see [Camera Support - Configuring Camera Streaming](camera_support.md#configuring-camera-streaming).

## Troubleshooting

### Mainsail won't load

1. Verify nginx is running: `systemctl status nginx`
2. Check nginx config: `nginx -t`
3. Verify Mainsail files exist: `ls -la /home/lava/mainsail/`

### Can't connect to printer

1. Verify Moonraker is running: `systemctl status moonraker`
2. Check Moonraker logs: `journalctl -u moonraker`
3. Verify API is accessible: `curl http://localhost:7125/printer/info`

### Camera not showing

1. Check camera service: `/etc/init.d/S99v4l2-mpp-mipi status`
2. Verify camera device: `ls -l /dev/video*`
3. Check camera config in Moonraker
4. Test camera backend directly: `wget -q -O /dev/null http://127.0.0.1:8080/snapshot.jpg && echo "OK"`
5. If backend works but Mainsail shows error, verify CORS headers in nginx config

### Camera shows "Error while connecting"

This usually indicates a browser CORS issue. The firmware includes CORS headers by default. If you still see this error:

1. Clear your browser cache and reload
2. Try a different browser
3. Verify nginx is serving the webcam: `wget -q -O /dev/null http://127.0.0.1/webcam/snapshot.jpg`
4. Check nginx error logs: `tail -f /var/log/nginx/error.log`

## Version Information

- **Mainsail Version**: v2.15.0
- **Release Date**: November 2024
- **Source**: https://github.com/mainsail-crew/mainsail

## Related Documentation

- [Mainsail Official Docs](https://docs.mainsail.xyz/)
- [Camera Support](camera_support.md)
- [Klipper Includes](klipper_includes.md)
- [SSH Access](ssh_access.md)
