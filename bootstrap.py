#!/usr/bin/env python

import argparse
import struct
import sys
from pathlib import Path
from serial import Serial
from minimon import Command


def parse_args() -> argparse.Namespace:
    ap = argparse.ArgumentParser()
    ap.add_argument("command", choices=("load", "burn"))
    ap.add_argument("--dev", type=Path, default="/dev/cu.usbserial-AB6ZMD8O")
    ap.add_argument("--image", type=Path, default="stage1.bin")
    ap.add_argument("--image-offset", type=lambda x: int(x, 0), default=0x100)
    ap.add_argument("-b", "--baud", type=int, default=2400)
    ap.add_argument("--burn-loader", action="store_true")
    ap.add_argument("--no-burn-loader", dest="burn_loader", action="store_false")
    ap.add_argument("--burn-bios", action="store_true")
    ap.add_argument("--no-burn-bios", dest="burn_bios", action="store_false")
    return ap.parse_args()


def load(serial: Serial, image: Path, image_offset: int):
    with open(image, "rb") as fobj:
        fobj.seek(image_offset)
        serial.write(fobj.read())


def check_magic(serial: Serial, addr: int, expect: bytes):
    n = len(expect)
    serial.write(struct.pack("!BHB", Command.PEEK, addr, n))
    magic = serial.read(n)
    if magic != expect:
        hex = "".join((f"{b:02x}" for b in magic))
        raise RuntimeError(f"invalid magic at 0x{addr:04x}: {hex}")


def burn(serial: Serial, burn_loader: bool, burn_bios: bool):
    check_magic(serial, 0x1FA, "stage1".encode("ascii"))

    if burn_loader:
        sys.stdout.write("Burning loader...")
        sys.stdout.flush()
        serial.write(struct.pack("!BH", Command.EXEC, 0x1D0))
        sys.stdout.write(" done!\n")

    if burn_bios:
        sys.stdout.write("Burning bios...")
        sys.stdout.flush()
        serial.write(struct.pack("!BH", Command.EXEC, 0x1B0))
        sys.stdout.write(" done!\n")


def main():
    args = parse_args()
    with Serial(str(args.dev), args.baud) as serial:
        if args.command == "load":
            load(serial, args.image, args.image_offset)
        elif args.command == "burn":
            burn(serial, args.burn_loader, args.burn_bios)


sys.exit(main())
