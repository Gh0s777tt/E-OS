#!/usr/bin/env python3
"""Add a .sbat section to a PE32+ UEFI image, in place (V2-MS01).

SBAT gives E-OS its own revocation lane: a generation number firmware can compare, instead
of waiting for a DBX entry only Microsoft can publish (ADR-0006).

Why a hand-written PE edit rather than objcopy -- all three alternatives were measured and
all three fail here:
  * this container's binutils is aarch64-only (`objdump --info` lists pei-aarch64-little and
    no pei-x86-64), so plain objcopy answers "file format not recognized" on an x86_64 EFI;
  * llvm-objcopy accepts --add-section on PE but corrupts the result (SizeOfImage zeroed,
    the new section left at VirtualAddress 0, i.e. never mapped);
  * binutils-multiarch carries the PE vectors but DIVERTS /usr/bin/objcopy for every recipe
    cooked afterwards, including the BIOS bootloader's own objcopy step.

This touches 16 header bytes and appends one section. Everything rustc and lld emitted is
left byte-for-byte alone.

Refuses to touch an already-signed image: an Authenticode signature covers the whole binary,
so a section added afterwards silently destroys it. V2-MS01 must run BEFORE V2-N03.
"""
import struct
import sys

SEC = 40                # bytes per PE section header
CHARS = 0x40000040      # CNT_INITIALIZED_DATA | MEM_READ -- data, read-only, never executable


def up(n, a):
    return (n + a - 1) // a * a


def main(path, csv_path):
    d = bytearray(open(path, "rb").read())
    data = open(csv_path, "rb").read()

    if d[0:2] != b"MZ":
        sys.exit("not a PE image: no MZ")
    pe = struct.unpack_from("<I", d, 0x3C)[0]
    if d[pe:pe + 4] != b"PE\0\0":
        sys.exit("not a PE image: no PE signature")
    nsec = struct.unpack_from("<H", d, pe + 6)[0]
    optsz = struct.unpack_from("<H", d, pe + 20)[0]
    opt = pe + 24
    if struct.unpack_from("<H", d, opt)[0] != 0x20B:
        sys.exit("not PE32+ (magic != 0x20b)")

    salign = struct.unpack_from("<I", d, opt + 32)[0]
    falign = struct.unpack_from("<I", d, opt + 36)[0]
    sizeof_hdrs = struct.unpack_from("<I", d, opt + 60)[0]
    nrva = struct.unpack_from("<I", d, opt + 108)[0]
    if nrva < 5:
        sys.exit("no security data directory slot")
    crva, csz = struct.unpack_from("<II", d, opt + 112 + 8 * 4)
    if crva or csz:
        sys.exit("image is already signed -- add .sbat BEFORE sbsign")

    tab = opt + optsz
    names, vend, rend, first_raw = [], 0, 0, None
    for i in range(nsec):
        o = tab + SEC * i
        names.append(d[o:o + 8].rstrip(b"\0").decode("ascii", "replace"))
        vs, va, rs, rp = struct.unpack_from("<IIII", d, o + 8)
        vend = max(vend, va + vs)
        rend = max(rend, rp + rs)
        if rp:
            first_raw = rp if first_raw is None else min(first_raw, rp)
    if ".sbat" in names:
        print("already carries .sbat -- nothing to do")
        return

    # The new header must fit in the space before the first section's raw data, or it would
    # overwrite code.
    if tab + SEC * (nsec + 1) > min(x for x in (sizeof_hdrs, first_raw) if x):
        sys.exit("no room in PE headers for another section header")

    va = up(vend, salign)
    rp = up(max(rend, len(d)), falign)
    rs = up(len(data), falign)
    if rp > len(d):
        d.extend(b"\0" * (rp - len(d)))
    d.extend(data + b"\0" * (rs - len(data)))

    struct.pack_into("<8sIIIIIIHHI", d, tab + SEC * nsec,
                     b".sbat", len(data), va, rs, rp, 0, 0, 0, 0, CHARS)
    struct.pack_into("<H", d, pe + 6, nsec + 1)                        # NumberOfSections
    struct.pack_into("<I", d, opt + 56, up(va + len(data), salign))    # SizeOfImage
    struct.pack_into("<I", d, opt + 8,
                     struct.unpack_from("<I", d, opt + 8)[0] + rs)     # SizeOfInitializedData
    struct.pack_into("<I", d, opt + 64, 0)                             # CheckSum: sbsign redoes it

    open(path, "wb").write(d)
    print("added .sbat: %d bytes at RVA 0x%x, file offset 0x%x" % (len(data), va, rp))


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("usage: %s <image.efi> <sbat.csv>" % sys.argv[0])
    main(sys.argv[1], sys.argv[2])
