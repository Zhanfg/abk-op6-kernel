#!/usr/bin/env python3
"""Fail closed if an experimental OnePlus 6 kernel drifts from the BOOTED ROM DTBs.

This validates the three appended FDTs in a compiled Image.gz-dtb against
the exact, ROM-ordered hashes extracted from the user's previously booted
uwuAOSP Android 17 v0.2 boot image. It never writes to any device.
The hash list is NOT proof that the new kernel is bootable.
"""
import argparse
import hashlib
import struct
import sys
import zlib
from pathlib import Path

KNOWN_GOOD = (
    "341e34eb0dae79a33a4b2a5cb89cb1f2fb2209d9d17d98f2d04d2551f46c9b11",
    "da668c914c0db8d8a52917070bfa370dd3208846f731aead4d72b3324b846298",
    "86638511847918077c2647a125991c03d46e2ecac66f65605c4ddb449774013c",
)


def dtb_hashes(blob: bytes) -> tuple[str, ...]:
    if not blob.startswith(b"\x1f\x8b\x08"):
        raise ValueError("not a gzip ARM64 Image.gz-dtb")
    stream = zlib.decompressobj(31)
    stream.decompress(blob)
    stream.flush()
    if not stream.eof:
        raise ValueError("truncated gzip kernel")
    tail = stream.unused_data
    if not tail:
        raise ValueError("appended FDT payload missing")
    off = 0
    digests = []
    while off < len(tail):
        if off + 40 > len(tail):
            raise ValueError("truncated FDT header")
        magic, size = struct.unpack_from(">II", tail, off)
        if magic != 0xD00DFEED or size < 64 or off + size > len(tail):
            raise ValueError("invalid FDT magic/size")
        digests.append(hashlib.sha256(tail[off:off + size]).hexdigest())
        off += size
    return tuple(digests)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("image", type=Path)
    args = parser.parse_args()
    try:
        digests = dtb_hashes(args.image.read_bytes())
    except (OSError, ValueError) as exc:
        print(f"[ERROR] cannot verify appended DTBs: {exc}", file=sys.stderr)
        return 2
    for i, digest in enumerate(digests):
        print(f"compiled.dtb[{i}]={digest}")
    for i, digest in enumerate(KNOWN_GOOD):
        print(f"rom_booted.dtb[{i}]={digest}")
    if digests != KNOWN_GOOD:
        print(
            "[ERROR] FDT baseline differs from user-booted Android 17 ROM. "
            "Failing closed: do NOT publish or flash this experimental AK3. "
            "Build from the verified kernel tree/config or perform a controlled "
            "fastboot-boot-only diagnostic first.",
            file=sys.stderr,
        )
        return 1
    print("[PASS] all 3 DTBs byte-match the booted Android 17 ROM in exact order")
    print("[NOTE] this is necessary ROM-baseline evidence, not a boot-success claim")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
