#!/usr/bin/env python3
"""Checks that the 64-bit native libraries (.so) in an APK / AAB are ready for
devices with 16 KB memory pages (a Google Play requirement for apps that
target Android 15+).

For every lib/arm64-v8a and lib/x86_64 library it checks:
  * ELF: every PT_LOAD segment has p_align >= 16384
  * APK only: the library is stored uncompressed and starts at a 16 KB boundary
    inside the zip (AAB files are re-aligned by Google Play, so not checked)

usage: check_16kb.py app-release.apk [app-release.aab ...]
exit code 1 when a problem is found.
"""
import struct
import sys
import zipfile

PAGE = 16 * 1024
ABIS = ("arm64-v8a", "x86_64")


def elf64_load_alignments(data: bytes):
    """p_align of each PT_LOAD segment, or None if `data` is not a 64-bit ELF."""
    if len(data) < 0x40 or data[:4] != b"\x7fELF" or data[4] != 2:
        return None
    e = "<" if data[5] == 1 else ">"
    phoff = struct.unpack_from(e + "Q", data, 0x20)[0]
    phentsize, phnum = struct.unpack_from(e + "HH", data, 0x36)
    aligns = []
    for i in range(phnum):
        off = phoff + i * phentsize
        if struct.unpack_from(e + "I", data, off)[0] == 1:  # PT_LOAD
            aligns.append(struct.unpack_from(e + "Q", data, off + 0x30)[0])
    return aligns


def zip_data_offset(path: str, info: zipfile.ZipInfo) -> int:
    with open(path, "rb") as f:
        f.seek(info.header_offset)
        header = f.read(30)
    name_len, extra_len = struct.unpack_from("<HH", header, 26)
    return info.header_offset + 30 + name_len + extra_len


def check(path: str) -> int:
    is_apk = path.lower().endswith(".apk")
    problems = 0
    checked = 0
    with zipfile.ZipFile(path) as z:
        for info in z.infolist():
            name = info.filename
            if not name.endswith(".so"):
                continue
            parts = name.split("/")
            if not any(abi in parts for abi in ABIS):
                continue
            checked += 1
            reasons = []
            aligns = elf64_load_alignments(z.read(name))
            if aligns is None:
                reasons.append("not a 64-bit ELF")
            elif any(a < PAGE for a in aligns):
                reasons.append("ELF segment alignment " + "/".join(hex(a) for a in aligns) + " < 0x4000")
            if is_apk:
                if info.compress_type != 0:
                    reasons.append("compressed inside the APK")
                elif zip_data_offset(path, info) % PAGE:
                    reasons.append("not 16 KB aligned inside the APK")
            if reasons:
                problems += 1
                print(f"  FAIL  {name}: {'; '.join(reasons)}")
            else:
                print(f"  ok    {name}")
    print(f"{path}: {checked} native libraries checked, {problems} problem(s)")
    return problems


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    total = 0
    for p in sys.argv[1:]:
        print(f"== {p}")
        total += check(p)
    if total:
        print("\nSome libraries are not 16 KB ready: Google Play may reject the upload.")
        print("Usual fix: update the plugin that ships the library (here: mobile_scanner).")
        sys.exit(1)
    print("\nAll 64-bit native libraries are 16 KB ready.")
