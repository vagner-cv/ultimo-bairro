"""Fetch only PC release templates from Godot's official archive, using HTTP ranges.

Usage: python tools/fetch_export_templates.py --destination /path/to/4.6.3.stable
The standard Godot template installer is an equally valid alternative.
"""
import argparse
import binascii
import io
from pathlib import Path
import struct
import urllib.request
import zipfile
import zlib

VERSION = "4.6.3"
ARCHIVE_SIZE = 1255918323  # Published size of the official 4.6.3 stable archive.
URL = f"https://github.com/godotengine/godot/releases/download/{VERSION}-stable/Godot_v{VERSION}-stable_export_templates.tpz"
WANTED = {"templates/windows_release_x86_64.exe", "templates/linux_release.x86_64"}


def fetch_range(url, start, end=None):
    byte_range = f"bytes={start}-{end}" if end is not None else f"bytes=-{start}"
    request = urllib.request.Request(url, headers={"Range": byte_range, "User-Agent": "UltimoBairro-Build/0.1"})
    with urllib.request.urlopen(request, timeout=90) as response:
        if response.status != 206:
            raise RuntimeError("The download server did not support range requests; install templates with Godot instead.")
        return response.read(), response.url


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--destination", required=True, type=Path)
    args = parser.parse_args()
    tail, resolved_url = fetch_range(URL, ARCHIVE_SIZE - 65536, ARCHIVE_SIZE - 1)
    index = tail.rfind(b"PK\x05\x06")
    if index < 0:
        raise RuntimeError("ZIP directory was not found")
    end = struct.unpack_from("<4s4H2IH", tail, index)
    directory_size, directory_offset = end[5], end[6]
    directory, _ = fetch_range(resolved_url, directory_offset, directory_offset + directory_size - 1)
    # ZIP metadata can be read without downloading any of the other templates.
    patched_end = struct.pack("<4s4H2IH", *end[:6], 0, end[7])
    archive = zipfile.ZipFile(io.BytesIO(directory + patched_end))
    args.destination.mkdir(parents=True, exist_ok=True)
    for info in archive.infolist():
        if info.filename not in WANTED:
            continue
        header, _ = fetch_range(resolved_url, info.header_offset, info.header_offset + 29)
        fields = struct.unpack("<4s5H3I2H", header)
        data_offset = info.header_offset + 30 + fields[-2] + fields[-1]
        compressed, _ = fetch_range(resolved_url, data_offset, data_offset + info.compress_size - 1)
        if info.compress_type == zipfile.ZIP_DEFLATED:
            data = zlib.decompress(compressed, -15)
        elif info.compress_type == zipfile.ZIP_STORED:
            data = compressed
        else:
            raise RuntimeError("Unsupported ZIP compression")
        if len(data) != info.file_size or binascii.crc32(data) != info.CRC:
            raise RuntimeError("Template CRC check failed")
        output = args.destination / Path(info.filename).name
        output.write_bytes(data)
        if output.suffix != ".exe":
            output.chmod(0o755)
        print(f"Verified {output.name}: {len(data):,} bytes", flush=True)
    if not all((args.destination / Path(name).name).is_file() for name in WANTED):
        raise RuntimeError("Required templates missing from archive")


if __name__ == "__main__":
    main()
