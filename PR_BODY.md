## Summary

Your RFID filament detection implementation is excellent - thank you for the solid NDEF/OpenSpool support!

This PR extends it with optional Spoolman integration by:
- Extracting the `spool_id` field from OpenSpool JSON payloads
- Calling an optional `ON_NFC_SPOOL_READ` macro when `spool_id` is present

This allows users with [Spoolman](https://github.com/Donkie/Spoolman) to get automatic spool tracking when loading filament.

## Changes

- **filament_protocol_ndef.py**: Extract optional `spool_id` field from OpenSpool JSON into `info['SPOOL_ID']`
- **02-add-ndef-protocol.patch**: Call `ON_NFC_SPOOL_READ CHANNEL=<n> SPOOL_ID=<id>` macro when spool_id is present
- **docs/rfid_support.md**: Add Spoolman Integration section with field reference and example macro
- **examples/nfc_spoolman.cfg**: Ready-to-use macro file users can copy to their config

## Tag Format

Users add `spool_id` to their existing OpenSpool tags:

```json
{
  "protocol": "openspool",
  "version": "1.0",
  "brand": "Elegoo",
  "type": "PLA",
  "color_hex": "#FF5733",
  "spool_id": 42
}
```

## Backward Compatibility

- Tags without `spool_id` work exactly as before
- The macro call only fires when `spool_id` is present
- No configuration required unless user wants Spoolman integration

## Example Macro

Users create `extended/klipper/nfc_spoolman.cfg`:

```cfg
[gcode_macro ON_NFC_SPOOL_READ]
gcode:
    {% set channel = params.CHANNEL|int %}
    {% set spool_id = params.SPOOL_ID|int %}
    {% set tool = "T" ~ channel %}
    SET_GCODE_VARIABLE MACRO={tool} VARIABLE=spool_id VALUE={spool_id}
    RESPOND PREFIX="NFC" MSG="Spool {spool_id} assigned to {tool}"
```

## Testing

- Tested with NTAG215 tags containing OpenSpool JSON with spool_id field
- Verified backward compatibility with tags without spool_id
- Verified macro is called with correct channel and spool_id parameters
