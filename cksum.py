#!/usr/bin/env python

import sys
import argparse
import struct
from pathlib import Path


def parse_args() -> argparse.Namespace:
    ap = argparse.ArgumentParser()
    ap.add_argument("image", type=Path)
    ap.add_argument("-n", "--size", choices=(1, 2), type=int, default=2)
    ap.add_argument("-o", "--output", type=Path)
    return ap.parse_args()


def main():
    args = parse_args()
    v = 0
    with open(args.image, "rb") as fobj:
        data = fobj.read()
    if args.size == 1:
        fmt = "!B"
    elif args.size == 2:
        fmt = "!H"
    else:
        raise NotImplementedError
    for i in range(0, len(data), args.size):
        buf = data[i : i + args.size]
        while len(buf) < args.size:
            buf += b"\0"
        v ^= struct.unpack(fmt, buf)[0]
    if args.output:
        with open(args.output, "wb") as fobj:
            fobj.write(struct.pack(fmt, v))
    elif args.size == 1:
        print(f"0x{v:02x}")
    elif args.size == 2:
        print(f"0x{v:04x}")
    else:
        raise NotImplementedError


sys.exit(main())
