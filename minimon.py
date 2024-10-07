#!/usr/bin/env python

import atexit
import argparse
import readline
import os
import shlex
import sys
import struct
from pathlib import Path
from serial import Serial
from typing import Generator


class Reload(BaseException): ...


def setup_readline(histfile: Path):
    try:
        readline.read_history_file(histfile)
    except FileNotFoundError:
        ...
    readline.set_history_length(1000)
    atexit.register(readline.write_history_file, histfile)
    readline.parse_and_bind("")


def peek(serial: Serial, argv: list[str]):
    ap = argparse.ArgumentParser("peek")
    ap.add_argument(
        "addr",
        type=lambda v: int(v, 0),
        help="address",
    )
    ap.add_argument(
        "-n",
        "--size",
        type=lambda v: int(v, 0),
        default=16,
        help="length",
    )
    try:
        args = ap.parse_args(argv[1:])
    except BaseException:
        return
    serial.write(struct.pack("!BHB", 1, args.addr, args.size))
    serial.flush()
    data = serial.read(args.size)
    for ii, byte in enumerate(data):
        if ii and ii % 8 == 0:
            sys.stdout.write("\n")
        sys.stdout.write(f"{byte:02x} ")
    sys.stdout.write("\n")


def chunked(data: bytes, n: int) -> Generator[bytes, None, None]:
    if n < 1:
        raise ValueError("n must be at least one")
    for i in range(0, len(data), n):
        yield data[i : i + n]


def poke(serial: Serial, argv: list[str]):
    ap = argparse.ArgumentParser("poke")
    ap.add_argument(
        "addr",
        type=lambda v: int(v, 0),
        help="address",
    )
    ap.add_argument(
        "-d",
        "--data",
        type=lambda data: bytes(
            int(data[i : i + 2], 16) for i in range(0, len(data), 2)
        ),
        help="data in hex format",
    )
    ap.add_argument(
        "-f",
        "--file",
        type=Path,
        help="file",
    )
    ap.add_argument(
        "-o",
        "--file-offset",
        type=lambda v: int(v, 0),
        default=0,
        help="offset",
    )
    ap.add_argument(
        "-n",
        "--size",
        type=lambda v: int(v, 0),
        help="length",
    )
    try:
        args = ap.parse_args(argv[1:])
    except BaseException:
        return
    try:
        assert not args.data or not args.file
        assert args.data or args.file
    except AssertionError:
        print("exactly one of --file or --value is required")
        return
    if args.data:
        serial.write(struct.pack("!BHB", 2, args.addr, len(args.data)))
        serial.write(args.data)
    elif args.file:
        with open(args.file, "rb") as fobj:
            data = fobj.read()[args.file_offset :]
        if args.size != 0:
            data = data[: args.size]
        addr = args.addr
        for chunk in chunked(data, 255):
            serial.write(struct.pack("!BHB", 2, addr, len(chunk)))
            serial.write(chunk)
            addr += len(chunk)


def exec(serial: Serial, argv: list[str]):
    ap = argparse.ArgumentParser("exec")
    ap.add_argument(
        "addr",
        type=lambda v: int(v, 0),
        help="address",
    )
    try:
        args = ap.parse_args(argv[1:])
    except BaseException:
        return
    serial.write(struct.pack("!BH", 3, args.addr))


def repl(serial: Serial):
    while True:
        try:
            line = input(">> ")
        except KeyboardInterrupt:
            print()
            continue
        except EOFError:
            print()
            return

        try:
            argv = shlex.split(line)
        except Exception as ex:
            print(ex)
            continue
        if not argv:
            continue

        try:
            if argv[0] in ("q", "quit"):
                return
            elif argv[0] == "reload":
                raise Reload()
            elif argv[0] in ("peek", "poke", "exec"):
                globals()[argv[0]](serial, argv)
            elif argv[0] in ("?", "h", "help"):
                print(
                    "\n".join(
                        (
                            "peek ADDR [-n SIZE]: read data",
                            "poke ADDR (-f FILE | -d DATA): write data",
                            "exec ADDR: call a subroutine",
                            "reload: reload the cli",
                            "?, h, help: this help text",
                            "q, quit: quit",
                        )
                    )
                )
            else:
                print(f"unknown command: {argv[0]}")
        except KeyboardInterrupt:
            print("^C")
            continue


def default_histfile() -> Path:
    return Path(__file__).parent / ".minimon_history"


def parse_args() -> argparse.Namespace:
    ap = argparse.ArgumentParser()
    ap.add_argument("--histfile", type=Path, default=default_histfile())
    ap.add_argument("--dev", type=Path, default="/dev/cu.usbserial-AB6ZMD8O")
    ap.add_argument("-b", "--baud", type=int, default=2400)
    return ap.parse_args()


def main():
    args = parse_args()
    setup_readline(args.histfile)
    try:
        with Serial(str(args.dev), args.baud) as serial:
            repl(serial)
    except Reload:
        atexit._run_exitfuncs()
        os.execvp("python", ["python"] + sys.argv)


sys.exit(main())
