#!/usr/bin/env python
#
# Generate rxlong input events and expected output events.

import argparse
import random
import sys
from typing import TextIO, NamedTuple


class Config(NamedTuple):
    name: str
    data: bytes
    num_bytes: int
    header: bool
    write_expect: bool
    baud_rate: int
    pulse_width: int
    start_time: int
    pause_time: int

    @staticmethod
    def parse() -> "Config":
        ap = argparse.ArgumentParser()
        ap.add_argument("-N", "--name", default="rx16")
        ap.add_argument("-d", "--data", type=str)
        ap.add_argument("-n", "--num-bytes", type=int, default=1024)
        ap.add_argument("-r", "--baud-rate", type=int, default=2400)
        ap.add_argument("-t", "--start-time", type=int, default=int(1e6))
        ap.add_argument("-p", "--pause-time", type=int, default=0)
        ap.add_argument(
            "--no-write-expect",
            action="store_false",
            dest="write_expect",
            default=True,
        )
        ap.add_argument(
            "--no-header",
            action="store_false",
            dest="header",
            default=True,
        )
        args = ap.parse_args()
        if args.data:
            data = bytes(
                int(args.data[i : i + 2], 16) for i in range(0, len(args.data), 2)
            )
            num_bytes = len(data)
        else:
            num_bytes = args.num_bytes
            data = random.randbytes(num_bytes)
        return Config(
            name=args.name,
            data=data,
            num_bytes=num_bytes,
            header=args.header,
            write_expect=args.write_expect,
            baud_rate=args.baud_rate,
            pulse_width=int(1e9 / args.baud_rate),
            start_time=args.start_time,
            pause_time=args.pause_time,
        )


def write_input_log(writer: TextIO, config: Config):

    def write(t: int, lv: int, v: int) -> int:
        if lv != v:
            writer.write(f"{t},flag,ef3,{v}\n")
        t += config.pulse_width
        return t

    def write_bytes(t: int, bytes: bytes) -> int:
        for byte in bytes:
            t = write(t, 1, 0)
            lv = 0
            for _ in range(8):
                v = byte & 1
                t = write(t, lv, v)
                lv = v
                byte >>= 1
            t = write(t, lv, 1)
        return t

    t = config.start_time
    if config.header:
        header = bytes(
            (
                (config.num_bytes >> 8) & 0xFF,
                config.num_bytes & 0xFF,
            )
        )
        t = write_bytes(config.start_time, header)
        t += config.pause_time
    write_bytes(t, config.data)


def write_expect_log(writer: TextIO, data: bytes):
    for byte in data:
        writer.write(f"_,output,io4,0x{byte:02x}\n")


def main():
    config = Config.parse()
    with open(f"{config.name}-input.evlog", "w") as fobj:
        write_input_log(fobj, config)
    if config.write_expect:
        with open(f"{config.name}-expect.evlog", "w") as fobj:
            write_expect_log(fobj, config.data)


sys.exit(main())
