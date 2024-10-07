#!/usr/bin/env python

import sys


def main(path: str):
    v = 0
    with open(path, "rb") as fobj:
        for byte in fobj.read():
            v ^= byte
        print(f"0x{v:02x}")


sys.exit(main(sys.argv[1]))
