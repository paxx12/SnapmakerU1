import copy
import io
import json
import logging
from . import filament_protocol

NDEF_OK = 0
NDEF_ERR = -1
NDEF_PARAMETER_ERR = -2
NDEF_NOT_FOUND_ERR = -3

def xxd_dump(data, max_lines=16):
    if isinstance(data, list):
        data = bytes(data)
    if not isinstance(data, (bytes, bytearray)):
        return ""

    lines = []
    for i in range(0, min(len(data), max_lines * 16), 16):
        hex_part = ' '.join(f'{b:02x}' for b in data[i:i+16])
        ascii_part = ''.join(chr(b) if 32 <= b < 127 else '.' for b in data[i:i+16])
        lines.append(f'{i:08x}: {hex_part:<48}  {ascii_part}')

    if len(data) > max_lines * 16:
        lines.append(f'... ({len(data)} bytes total)')

    return '\n'.join(lines)

def ndef_parse(data_buf):
    if None == data_buf or isinstance(data_buf, (list, bytes, bytearray)) == False:
        return NDEF_PARAMETER_ERR, []

    try:
        data = bytes(data_buf) if isinstance(data_buf, list) else data_buf

        logging.info("NDEF RFID data:")
        logging.info("\n" + xxd_dump(data))

        data_io = io.BytesIO(data)

        start_offset = 0
        if len(data) > 12 and data[0] != 0xE1:
            for i in range(min(16, len(data) - 4)):
                if data[i] == 0xE1 and (data[i+1] == 0x10 or data[i+1] == 0x11 or data[i+1] == 0x40):
                    start_offset = i
                    break

        if start_offset > 0:
            data_io.seek(start_offset)

        cc = data_io.read(4)
        if len(cc) < 4 or cc[0] != 0xE1:
            return NDEF_PARAMETER_ERR, []

        records = []

        while True:
            base_tlv = data_io.read(2)
            if len(base_tlv) < 2:
                break

            tag = base_tlv[0]
            if tag == 0xFE:
                break

            tlv_len = base_tlv[1]
            if tlv_len == 0xFF:
                ext_len = data_io.read(2)
                if len(ext_len) < 2:
                    break
                tlv_len = (ext_len[0] << 8) | ext_len[1]

            if tag == 0x03:
                ndef_data = data_io.read(tlv_len)
                ndef_offset = 0

                while ndef_offset < len(ndef_data) - 2:
                    header = ndef_data[ndef_offset]
                    ndef_offset += 1

                    tnf = header & 0x07
                    sr_flag = (header >> 4) & 0x01
                    il_flag = (header >> 3) & 0x01

                    type_len = ndef_data[ndef_offset]
                    ndef_offset += 1

                    if sr_flag:
                        payload_len = ndef_data[ndef_offset]
                        ndef_offset += 1
                    else:
                        if ndef_offset + 4 > len(ndef_data):
                            break
                        payload_len = (ndef_data[ndef_offset] << 24) | (ndef_data[ndef_offset + 1] << 16) | (ndef_data[ndef_offset + 2] << 8) | ndef_data[ndef_offset + 3]
                        ndef_offset += 4

                    id_len = 0
                    if il_flag:
                        id_len = ndef_data[ndef_offset]
                        ndef_offset += 1

                    if ndef_offset + type_len + id_len + payload_len > len(ndef_data):
                        break

                    mime_type = ndef_data[ndef_offset:ndef_offset + type_len].decode('ascii', errors='ignore')
                    ndef_offset += type_len

                    if id_len > 0:
                        ndef_offset += id_len

                    payload = bytes(ndef_data[ndef_offset:ndef_offset + payload_len])
                    ndef_offset += payload_len

                    if tnf == 0x02:
                        records.append({'mime_type': mime_type, 'payload': payload})
                        logging.info(f"NDEF record found: mime_type='{mime_type}', payload_len={len(payload)}")
            else:
                data_io.seek(tlv_len, 1)

        if not records:
            return NDEF_NOT_FOUND_ERR, []

        return NDEF_OK, records

    except Exception as e:
        logging.exception("NDEF parsing failed: %s", str(e))
        return NDEF_ERR, []

def cbor_decode_additional_info(data, offset, additional_info):
    if additional_info < 24:
        return additional_info, offset
    elif additional_info == 24:
        value = data[offset]
        return value, offset + 1
    elif additional_info == 25:
        value = (data[offset] << 8) | data[offset + 1]
        return value, offset + 2
    elif additional_info == 26:
        value = (data[offset] << 24) | (data[offset + 1] << 16) | (data[offset + 2] << 8) | data[offset + 3]
        return value, offset + 4
    elif additional_info == 27:
        high_word = (data[offset] << 24) | (data[offset + 1] << 16) | (data[offset + 2] << 8) | data[offset + 3]
        low_word = (data[offset + 4] << 24) | (data[offset + 5] << 16) | (data[offset + 6] << 8) | data[offset + 7]
        value = (high_word << 32) | low_word
        return value, offset + 8
    elif additional_info == 31:
        return -1, offset
    else:
        raise ValueError("Invalid CBOR additional info: {}".format(additional_info))

def cbor_decode_value(data, offset):
    if offset >= len(data):
        return None, offset

    initial_byte = data[offset]
    major_type = (initial_byte >> 5) & 0x07
    additional_info = initial_byte & 0x1F
    offset += 1

    if major_type == 0:
        value, offset = cbor_decode_additional_info(data, offset, additional_info)
        return value, offset
    elif major_type == 1:
        value, offset = cbor_decode_additional_info(data, offset, additional_info)
        return -1 - value, offset
    elif major_type == 2:
        value, offset = cbor_decode_additional_info(data, offset, additional_info)
        if value == -1:
            return b'', offset
        return bytes(data[offset:offset + value]), offset + value
    elif major_type == 3:
        value, offset = cbor_decode_additional_info(data, offset, additional_info)
        if value == -1:
            return '', offset
        return data[offset:offset + value].decode('utf-8'), offset + value
    elif major_type == 4:
        value, offset = cbor_decode_additional_info(data, offset, additional_info)
        result = []
        if value == -1:
            while offset < len(data) and data[offset] != 0xFF:
                item, offset = cbor_decode_value(data, offset)
                if item is not None:
                    result.append(item)
            if offset < len(data) and data[offset] == 0xFF:
                offset += 1
        else:
            for _ in range(value):
                item, offset = cbor_decode_value(data, offset)
                if item is not None:
                    result.append(item)
        return result, offset
    elif major_type == 5:
        value, offset = cbor_decode_additional_info(data, offset, additional_info)
        result = {}
        if value == -1:
            while offset < len(data) and data[offset] != 0xFF:
                key, offset = cbor_decode_value(data, offset)
                val, offset = cbor_decode_value(data, offset)
                if key is not None and val is not None:
                    result[key] = val
            if offset < len(data) and data[offset] == 0xFF:
                offset += 1
        else:
            for _ in range(value):
                key, offset = cbor_decode_value(data, offset)
                val, offset = cbor_decode_value(data, offset)
                if key is not None and val is not None:
                    result[key] = val
        return result, offset
    elif major_type == 7:
        if additional_info == 20:
            return False, offset
        elif additional_info == 21:
            return True, offset
        elif additional_info == 22:
            return None, offset
        elif additional_info == 23:
            return None, offset
        elif additional_info == 24:
            value, offset = cbor_decode_additional_info(data, offset, additional_info)
            if value < 32:
                raise ValueError("Invalid CBOR simple value: {}".format(value))
            return value, offset
        elif additional_info == 25:
            value, offset = cbor_decode_additional_info(data, offset, additional_info)
            import struct
            sign = (value & 0x8000) >> 15
            exponent = (value & 0x7C00) >> 10
            fraction = value & 0x03FF
            if exponent == 0:
                result = ((-1) ** sign) * (2 ** -14) * (fraction / 1024.0)
            elif exponent == 0x1F:
                result = float('nan') if fraction else (float('-inf') if sign else float('inf'))
            else:
                result = ((-1) ** sign) * (2 ** (exponent - 15)) * (1 + fraction / 1024.0)
            return result, offset
        elif additional_info == 26:
            value, offset = cbor_decode_additional_info(data, offset, additional_info)
            import struct
            return struct.unpack('>f', value.to_bytes(4, 'big'))[0], offset
        elif additional_info == 27:
            value, offset = cbor_decode_additional_info(data, offset, additional_info)
            import struct
            return struct.unpack('>d', value.to_bytes(8, 'big'))[0], offset
        elif additional_info == 31:
            return None, offset
        elif additional_info < 20:
            return additional_info, offset

    raise ValueError("Unsupported CBOR major type: {}".format(major_type))

def openprinttag_decode_main_region(payload):
    meta, meta_end = cbor_decode_value(payload, 0)
    if not isinstance(meta, dict):
        raise ValueError('Invalid CBOR data: expected dict')

    main_region_offset = meta.get(0, meta_end)
    aux_region_offset = meta.get(2, len(payload))
    main_region_size = meta.get(1, aux_region_offset - main_region_offset)
    #aux_region_size = meta.get(3, len(payload) - aux_region_offset)

    main_payload = payload[main_region_offset:main_region_offset + main_region_size]
    main_data, _ = cbor_decode_value(main_payload, 0)
    return main_data

OPENPRINTTAG_MATERIAL_TYPE_MAPPING = {
    0: 'PLA',
    1: 'PETG',
    2: 'TPU',
    3: 'ABS',
    4: 'ASA',
    5: 'PC',
    6: 'PCTG',
    7: 'PP',
    8: 'PA6',
    9: 'PA11',
    10: 'PA12',
    11: 'PA66',
    12: 'CPE',
    13: 'TPE',
    14: 'HIPS',
    15: 'PHA',
    16: 'PET',
    17: 'PEI',
    18: 'PBT',
    19: 'PVB',
    20: 'PVA',
    21: 'PEKK',
    22: 'PEEK',
    23: 'BVOH',
    24: 'TPC',
    25: 'PPS',
    26: 'PPSU',
    27: 'PVC',
    28: 'PEBA',
    29: 'PVDF',
    30: 'PPA',
    31: 'PCL',
    32: 'PES',
    33: 'PMMA',
    34: 'POM',
    35: 'PPE',
    36: 'PS',
    37: 'PSU',
    38: 'TPI',
    39: 'SBS',
    40: 'OBC',
}

def openprinttag_parse_payload(payload):
    if None == payload or not isinstance(payload, (bytes, bytearray)):
        logging.error("OpenPrintTag payload parsing failed: Invalid payload parameter")
        return filament_protocol.FILAMENT_PROTO_PARAMETER_ERR, None

    try:
        main_data = openprinttag_decode_main_region(payload)
        if not isinstance(main_data, dict):
            logging.error(f"OpenPrintTag payload parsing failed: Main data is not a dict, got {type(main_data)}")
            return filament_protocol.FILAMENT_PROTO_ERR, None

        logging.info(f"OpenPrintTag main data: {main_data}")

        info = copy.copy(filament_protocol.FILAMENT_INFO_STRUCT)
        info['VERSION'] = 1
        info['VENDOR'] = main_data.get(11, 'NONE')
        info['MANUFACTURER'] = main_data.get(11, 'NONE')

        material_type_id = main_data.get(9)
        if material_type_id is not None:
            info['MAIN_TYPE'] = OPENPRINTTAG_MATERIAL_TYPE_MAPPING.get(material_type_id, 'Reserved')
        else:
            info['MAIN_TYPE'] = 'Reserved'

        info['SUB_TYPE'] = 'Basic'
        tags = main_data.get(28, [])
        if isinstance(tags, list):
            if 16 in tags:
                info['SUB_TYPE'] = 'Matte'
        info['TRAY'] = 0

        colors = []
        for color_key in [19, 20, 21, 22]:
            color_data = main_data.get(color_key)
            if color_data and len(color_data) >= 3:
                rgb = (color_data[0] << 16) | (color_data[1] << 8) | color_data[2]
                alpha = color_data[3] if len(color_data) >= 4 else 0xFF
                colors.append((rgb, alpha))

        if not colors:
            colors.append((0xFFFFFF, 0xFF))

        info['COLOR_NUMS'] = len(colors)
        info['ALPHA'] = colors[0][1]
        info['RGB_1'] = colors[0][0] if len(colors) > 0 else 0
        info['RGB_2'] = colors[1][0] if len(colors) > 1 else 0
        info['RGB_3'] = colors[2][0] if len(colors) > 2 else 0
        info['RGB_4'] = colors[3][0] if len(colors) > 3 else 0
        info['RGB_5'] = 0
        info['ARGB_COLOR'] = info['ALPHA'] << 24 | info['RGB_1']

        diameter = main_data.get(16, 0)
        info['DIAMETER'] = int(diameter * 100) if diameter else 0

        weight = main_data.get(18, 0)
        info['WEIGHT'] = int(weight) if weight else 0

        info['LENGTH'] = 0
        info['DRYING_TEMP'] = 0
        info['DRYING_TIME'] = 0

        nozzle_temp = main_data.get(34, 0)
        if nozzle_temp:
            info['HOTEND_MIN_TEMP'] = int(nozzle_temp)
            info['HOTEND_MAX_TEMP'] = int(nozzle_temp)
        else:
            info['HOTEND_MIN_TEMP'] = 0
            info['HOTEND_MAX_TEMP'] = 0

        bed_temp = main_data.get(35, 0)
        info['BED_TEMP'] = int(bed_temp) if bed_temp else 0
        info['BED_TYPE'] = 0
        info['FIRST_LAYER_TEMP'] = info['HOTEND_MIN_TEMP']
        info['OTHER_LAYER_TEMP'] = info['HOTEND_MIN_TEMP']

        gtin = main_data.get(4, 0)
        info['SKU'] = int(gtin) if gtin else 0

        manufactured_date = main_data.get(14)
        if manufactured_date:
            import datetime
            try:
                dt = datetime.datetime.fromtimestamp(manufactured_date, tz=datetime.timezone.utc)
                info['MF_DATE'] = dt.strftime('%Y%m%d')
            except (ValueError, OSError):
                info['MF_DATE'] = '19700101'
        else:
            info['MF_DATE'] = '19700101'
        info['RSA_KEY_VERSION'] = 0
        info['OFFICIAL'] = True
        info['CARD_UID'] = []

        return filament_protocol.FILAMENT_PROTO_OK, info

    except Exception as e:
        logging.exception("OpenPrintTag payload parsing failed: %s", str(e))
        return filament_protocol.FILAMENT_PROTO_ERR, None

def openspool_parse_payload(payload):
    if None == payload or not isinstance(payload, (bytes, bytearray)):
        logging.error("OpenSpool payload parsing failed: Invalid payload parameter")
        return filament_protocol.FILAMENT_PROTO_PARAMETER_ERR, None

    try:
        payload_str = payload.decode('utf-8')
        logging.info(f"OpenSpool JSON payload: {payload_str}")

        data = json.loads(payload_str)

        if not isinstance(data, dict):
            logging.error(f"OpenSpool payload parsing failed: JSON data is not a dict, got {type(data)}")
            return filament_protocol.FILAMENT_PROTO_ERR, None

        if data.get('protocol') != 'openspool':
            logging.error(f"OpenSpool payload parsing failed: Invalid protocol '{data.get('protocol')}', expected 'openspool'")
            return filament_protocol.FILAMENT_PROTO_ERR, None

        info = copy.copy(filament_protocol.FILAMENT_INFO_STRUCT)
        info['VERSION'] = 1
        info['VENDOR'] = data.get('brand', 'Generic')
        info['MANUFACTURER'] = data.get('brand', 'Generic')

        material_type = data.get('type', '').upper()
        if material_type in filament_protocol.FILAMENT_PROTO_MAIN_TYPE_MAPPING:
            info['MAIN_TYPE'] = material_type
        else:
            info['MAIN_TYPE'] = 'Reserved'

        info['SUB_TYPE'] = 'Reserved'
        info['TRAY'] = 0

        color_hex = data.get('color_hex', 'FFFFFF')
        if color_hex.startswith('#'):
            color_hex = color_hex[1:]
        try:
            rgb_value = int(color_hex, 16)
            info['RGB_1'] = rgb_value
            info['ALPHA'] = 0xFF
        except ValueError:
            info['RGB_1'] = 0xFFFFFF
            info['ALPHA'] = 0xFF

        info['COLOR_NUMS'] = 1
        info['RGB_2'] = 0
        info['RGB_3'] = 0
        info['RGB_4'] = 0
        info['RGB_5'] = 0
        info['ARGB_COLOR'] = info['ALPHA'] << 24 | info['RGB_1']

        info['DIAMETER'] = 175
        info['WEIGHT'] = 0
        info['LENGTH'] = 0
        info['DRYING_TEMP'] = 0
        info['DRYING_TIME'] = 0

        try:
            min_temp = int(data.get('min_temp', 0))
            max_temp = int(data.get('max_temp', 0))
            info['HOTEND_MIN_TEMP'] = min_temp
            info['HOTEND_MAX_TEMP'] = max_temp
        except (ValueError, TypeError):
            info['HOTEND_MIN_TEMP'] = 0
            info['HOTEND_MAX_TEMP'] = 0

        try:
            bed_min_temp = int(data.get('bed_min_temp', 0))
            bed_max_temp = int(data.get('bed_max_temp', 0))
            info['BED_TEMP'] = bed_min_temp if bed_min_temp > 0 else bed_max_temp
        except (ValueError, TypeError):
            info['BED_TEMP'] = 0

        info['BED_TYPE'] = 0
        info['FIRST_LAYER_TEMP'] = info['HOTEND_MIN_TEMP']
        info['OTHER_LAYER_TEMP'] = info['HOTEND_MIN_TEMP']

        info['SKU'] = 0
        info['MF_DATE'] = '19700101'
        info['RSA_KEY_VERSION'] = 0
        info['OFFICIAL'] = True
        info['CARD_UID'] = []

        return filament_protocol.FILAMENT_PROTO_OK, info

    except json.JSONDecodeError as e:
        logging.exception("OpenSpool payload parsing failed: Invalid JSON: %s", str(e))
        return filament_protocol.FILAMENT_PROTO_ERR, None
    except Exception as e:
        logging.exception("OpenSpool payload parsing failed: %s", str(e))
        return filament_protocol.FILAMENT_PROTO_ERR, None

def ndef_proto_data_parse(data_buf):
    error, records = ndef_parse(data_buf)

    if error != NDEF_OK:
        logging.error(f"NDEF parse failed: NDEF parsing error (code: {error})")
        return filament_protocol.FILAMENT_PROTO_ERR, None

    if not records:
        logging.error("NDEF parse failed: No records found")
        return filament_protocol.FILAMENT_PROTO_ERR, None

    for record in records:
        mime_type = record['mime_type']
        payload = record['payload']

        if mime_type == 'application/vnd.openprinttag':
            logging.info(f"Detected OpenPrintTag format, parsing payload ({len(payload)} bytes)")
            error_code, info = openprinttag_parse_payload(payload)
            if error_code != filament_protocol.FILAMENT_PROTO_OK:
                logging.error(f"OpenPrintTag parse failed: Payload parsing error (code: {error_code})")
                continue
            else:
                logging.info(f"OpenPrintTag parse success: vendor={info.get('VENDOR')}, type={info.get('MAIN_TYPE')}")
                return error_code, info

        elif mime_type == 'application/json':
            logging.info(f"Detected OpenSpool format, parsing payload ({len(payload)} bytes)")
            error_code, info = openspool_parse_payload(payload)
            if error_code != filament_protocol.FILAMENT_PROTO_OK:
                logging.error(f"OpenSpool parse failed: Payload parsing error (code: {error_code})")
                continue
            else:
                logging.info(f"OpenSpool parse success: vendor={info.get('VENDOR')}, type={info.get('MAIN_TYPE')}")
                return error_code, info

        else:
            logging.warning(f"Skipping unsupported MIME type '{mime_type}'")

    logging.error("NDEF parse failed: No supported records found (expected 'application/vnd.openprinttag' or 'application/json')")
    return filament_protocol.FILAMENT_PROTO_SIGN_CHECK_ERR, None

if __name__ == '__main__':
    import sys
    import argparse

    logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')

    parser = argparse.ArgumentParser(description='Parse NDEF data from file')
    parser.add_argument('file', help='File containing NDEF data')
    args = parser.parse_args()

    try:
        with open(args.file, 'rb') as f:
            data = f.read()

        error_code, info = ndef_proto_data_parse(data)

        if error_code == filament_protocol.FILAMENT_PROTO_OK:
            print(info)
        else:
            print(f"Error: {error_code}")
            sys.exit(1)

    except FileNotFoundError:
        print(f"Error: File '{args.file}' not found")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
