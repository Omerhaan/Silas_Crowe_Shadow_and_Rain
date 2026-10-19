import urllib.request
import struct
import zlib
import os

URL = "https://github.com/godotengine/godot-builds/releases/download/4.3-stable/Godot_v4.3-stable_export_templates.tpz"
TARGET_DIR = os.path.expandvars(r"%APPDATA%\Godot\export_templates\4.3.stable")

def fetch_range(start, end):
    req = urllib.request.Request(URL, headers={"Range": f"bytes={start}-{end}", "User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req) as resp:
        return resp.read()

def get_content_length():
    req = urllib.request.Request(URL, headers={"User-Agent": "Mozilla/5.0"}, method="HEAD")
    with urllib.request.urlopen(req) as resp:
        return int(resp.headers.get("Content-Length"))

def main():
    os.makedirs(TARGET_DIR, exist_ok=True)
    total_len = get_content_length()
    print(f"Total file size: {total_len} bytes (~{total_len/1024/1024:.1f} MB)")

    # 1. Fetch last 65 KB to find EOCD
    tail_len = min(65536, total_len)
    tail_bytes = fetch_range(total_len - tail_len, total_len - 1)
    
    # EOCD signature is b'PK\x05\x06'
    eocd_pos = tail_bytes.rfind(b"PK\x05\x06")
    if eocd_pos == -1:
        raise Exception("EOCD signature not found in last 65KB")

    # Read EOCD record
    eocd = tail_bytes[eocd_pos:eocd_pos+22]
    sig, disk_no, cd_disk, num_entries_disk, num_entries, cd_size, cd_offset, comment_len = struct.unpack("<4sHHHHIIH", eocd)
    print(f"Central directory: size={cd_size}, offset={cd_offset}, entries={num_entries}")

    # 2. Fetch central directory
    cd_bytes = fetch_range(cd_offset, cd_offset + cd_size - 1)
    
    # 3. Parse entries
    entries = []
    idx = 0
    while idx < len(cd_bytes):
        if cd_bytes[idx:idx+4] != b"PK\x01\x02":
            break
        header = cd_bytes[idx:idx+46]
        (_, ver_made, ver_needed, flags, comp_method, mod_time, mod_date,
         crc32, comp_size, uncomp_size, name_len, extra_len, comment_len,
         disk_start, int_attr, ext_attr, local_offset) = struct.unpack("<4sHHHHHHIIIHHHHHII", header)
        
        name_start = idx + 46
        filename = cd_bytes[name_start:name_start+name_len].decode("utf-8", errors="replace")
        
        entries.append({
            "filename": filename,
            "comp_method": comp_method,
            "comp_size": comp_size,
            "uncomp_size": uncomp_size,
            "crc32": crc32,
            "local_offset": local_offset
        })
        idx += 46 + name_len + extra_len + comment_len

    target_files = [
        "templates/android_debug.apk",
        "templates/android_release.apk",
        "templates/version.txt"
    ]

    for entry in entries:
        if entry["filename"] in target_files:
            fname = os.path.basename(entry["filename"])
            dest_path = os.path.join(TARGET_DIR, fname)
            print(f"Downloading {entry['filename']} -> {dest_path} (size={entry['comp_size']/1024/1024:.2f} MB)...")
            
            # Fetch local header (30 bytes + name_len + extra_len)
            lh_bytes = fetch_range(entry["local_offset"], entry["local_offset"] + 30 + 512)
            _, _, _, _, _, _, _, _, _, lh_name_len, lh_extra_len = struct.unpack("<4sHHHHHIIIHH", lh_bytes[:30])
            
            data_start = entry["local_offset"] + 30 + lh_name_len + lh_extra_len
            data_end = data_start + entry["comp_size"] - 1
            
            file_data = fetch_range(data_start, data_end)
            if entry["comp_method"] == 8: # Deflate
                decompressed = zlib.decompress(file_data, -15)
            elif entry["comp_method"] == 0: # Stored
                decompressed = file_data
            else:
                raise Exception(f"Unsupported compression method: {entry['comp_method']}")
            
            with open(dest_path, "wb") as f:
                f.write(decompressed)
            print(f"  Saved {dest_path} ({len(decompressed)/1024/1024:.2f} MB)")

    print("All android templates downloaded successfully!")

if __name__ == "__main__":
    main()
