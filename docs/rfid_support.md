---
title: RFID Filament Tag Support
---

# RFID Filament Tag Support

**Available in: All firmware (extended adds OpenSpool support)**

The Snapmaker U1 automatically detects filament properties by reading RFID tags on spools.

**Firmware Support:**
- **Original & Basic:** Mifare Classic 1K with Snapmaker proprietary format
- **Extended:** Adds NTAG215/216 support with OpenSpool format

## Supported Formats

| Feature | OpenSpool 🏆 | OpenPrintTag | OpenTag3D | Snapmaker |
|---------|--------------|--------------|-----------|-----------|
| **Tag Type** | NTAG215 (540 bytes) / NTAG216 (888 bytes) | ISO15693/SLIX2 | NTAG215/216 or ISO15693/SLIX2 | Mifare Classic 1K |
| **Encoding** | JSON (NDEF) | CBOR (NDEF) | Binary | Proprietary + RSA signature |
| **Data Format** | Human-readable JSON | Compact CBOR binary | Binary | Encrypted proprietary |
| **Specification** | [openspool.io](https://openspool.io/rfid.html) | [specs.openprinttag.org](https://specs.openprinttag.org/#/) | [OpenTag3D](https://github.com/prusa3d/OpenTag3D) | Proprietary (closed) |
| **GitHub Repository** | [spuder/OpenSpool](https://github.com/spuder/OpenSpool) | [prusa3d/OpenPrintTag](https://github.com/prusa3d/OpenPrintTag) | [queengooborg/OpenTag3D](https://github.com/queengooborg/OpenTag3D) | N/A |
| **Popularity** | ⭐⭐⭐ (623 stars) | ⭐⭐ (213 stars) | ⭐ (17 stars) | N/A |
| **Programming Tools** | Any NDEF-capable NFC app | Prusa app only | [opentag3d.info/make](https://opentag3d.info/make) | Snapmaker official only |
| **U1 Compatible** | ✅ Yes (extended firmware) | ❌ No (ISO15693 not supported) | ⚠️ Not implemented yet | ✅ Yes (all firmware) |
| **Ease of Programming** | Easy (any NFC app) | Medium (requires Prusa app) | Medium (web-based tool) | Hard (official tags only) |
| **Data Portability** | High (simple JSON) | High (open CBOR spec) | Medium (binary format) | None (proprietary) |

🏆 = Recommended for U1 (NTAG215 is the sweet spot for capacity and compatibility)

## How It Works

Tags are automatically read when filament is loaded into the feeder. Tag data clears when filament is removed.

**Manual Commands:**
- Read tag: `FILAMENT_DT_UPDATE CHANNEL=<n>`
- Clear tag data: `FILAMENT_DT_CLEAR CHANNEL=<n>`
- Check current tag: `FILAMENT_DT_QUERY CHANNEL=<n>`

## Programming Filament Tags

### OpenSpool (Recommended for Extended Firmware)

**Quick Setup:**
1. Get NTAG215 or NTAG216 tags
2. Open Chrome on Android phone
3. Visit [printtag-web.pages.dev](https://printtag-web.pages.dev)
4. Enter filament information
5. Tap tag to phone to write

**Alternative:** Use any NFC app that supports NDEF with JSON (MIME type: `application/json`)

Example payload:
```json
{
  "protocol": "openspool",
  "version": "1.0",
  "brand": "Generic",
  "type": "PLA",
  "color_hex": "#FF0000",
  "min_temp": 190,
  "max_temp": 220,
  "bed_min_temp": 50,
  "bed_max_temp": 60
}
```

Using the non-standard OpenSpool `subtype` field it is possible to specify a material subtype:

```json
{
  "protocol": "openspool",
  "version": "1.0",
  "type": "PETG",
  "subtype": "Rapid",
  "color_hex": "AFAFAF",
  "additional_color_hexes": ["EEFFEE","FF00FF"],
  "alpha": "FF",
  "brand": "Elegoo",
  "min_temp": "230",
  "max_temp": "260"
}
```

### OpenSpool Field Reference

**Required Fields:**
- `protocol` - Must be "openspool"
- `version` - Specification version (e.g., "1.0")
- `type` - Material type (PLA, PETG, ABS, TPU, etc.)
- `color_hex` - Color in hex format (#RRGGBB)

**Optional Standard Fields:**
- `brand` - Manufacturer name
- `min_temp` / `max_temp` - Nozzle temperature range in °C

**Optional Extended Fields (U1-specific):**
- `bed_min_temp` / `bed_max_temp` - Bed temperature range in °C
- `subtype` - Material variant (Basic, Rapid, HF, Silk, etc.)
- `alpha` - Color transparency (00-FF hex, default: FF)
- `additional_color_hexes` - Additional colors for multicolor spools (up to 4)
- `weight` - Spool weight in grams
- `diameter` - Filament diameter in mm (e.g., 1.75)
- `spool_id` - Spoolman spool ID for automatic spool tracking (see [Spoolman Integration](#spoolman-integration))

### Snapmaker Orca Naming Convention

Snapmaker Orca requires filaments to follow this naming pattern: `<brand> <type> <subtype>`

Examples: `Generic PLA Basic`, `Elegoo PETG Rapid`

## Reading Existing Tags

Use the **NFC Tools** app (iOS/Android) to inspect tags:

1. Download NFC Tools from App Store or Google Play
2. Tap "Read" and hold tag to phone
3. Check tag type and NDEF records

**Compatible tag types:** NTAG213/215/216, Mifare Classic 1K
**Note:** ISO15693 tags (OpenPrintTag) are not supported

## Troubleshooting

**Tag not detected:**
- Ensure tag is NTAG213/215/216 or Mifare Classic 1K
- Position tag within 1-3cm of reader antenna
- Manually read tag: `FILAMENT_DT_UPDATE CHANNEL=<n>` then `FILAMENT_DT_QUERY CHANNEL=<n>`
- Check `klipper.log` for detection messages

**OpenPrintTag tags don't work:**
- Expected - OpenPrintTag uses ISO15693 which is not supported by U1 hardware
- Use NTAG tags with OpenSpool format instead

**NTAG tags only work on extended firmware:**
- Basic and original firmware only support Mifare Classic 1K with Snapmaker proprietary format
- Extended firmware adds NTAG215/216 support

## Spoolman Integration

[Spoolman](https://github.com/Donkie/Spoolman) is a self-hosted filament inventory management system. When combined with NFC tags, you can automatically track which spool is loaded in each extruder.

### How It Works

1. Include `spool_id` in your OpenSpool NFC tag payload
2. When the tag is read, the firmware calls the `ON_NFC_SPOOL_READ` macro
3. Your macro updates Spoolman with the active spool

### Tag Format

Add the `spool_id` field to your OpenSpool payload:

```json
{
  "protocol": "openspool",
  "version": "1.0",
  "brand": "Elegoo",
  "type": "PLA",
  "color_hex": "#FF5733",
  "min_temp": 200,
  "max_temp": 220,
  "spool_id": 42
}
```

The `spool_id` should match the spool ID in your Spoolman database.

### Example Macro

Create `extended/klipper/nfc_spoolman.cfg`:

```cfg
# NFC Tag → Spoolman Integration
# Automatically called when an NFC tag with spool_id is read
# Parameters: CHANNEL (0-3 = T0-T3), SPOOL_ID (integer)

[gcode_macro ON_NFC_SPOOL_READ]
description: Called when NFC tag with spool_id is read
gcode:
    {% set channel = params.CHANNEL|int %}
    {% set spool_id = params.SPOOL_ID|int %}
    {% set tool = "T" ~ channel %}

    # Update tool's spool assignment
    SET_GCODE_VARIABLE MACRO={tool} VARIABLE=spool_id VALUE={spool_id}

    # Optional: Trigger deferred spool save
    UPDATE_DELAYED_GCODE ID=SAVE_SELECTED_SPOOLS DURATION=1

    RESPOND PREFIX="NFC" MSG="Spool {spool_id} assigned to {tool}"
```

### Generating Tags from Spoolman

If you have Spoolman running, you can generate the tag payload directly:

```bash
SPOOL_ID=42  # Your spool ID
curl -s "http://spoolman:7912/api/v1/spool/$SPOOL_ID" | jq '{
  protocol: "openspool",
  version: "1.0",
  type: .filament.material,
  brand: .filament.vendor.name,
  color_hex: ("#" + .filament.color_hex),
  spool_id: .id
}'
```

Write this JSON to an NTAG215 tag using any NFC app that supports NDEF with MIME type `application/json`.
