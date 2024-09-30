#!/usr/bin/env python
#
# Generate rxlong input events and expected output events.

import argparse
import random
import sys
from typing import TextIO, NamedTuple


class Config(NamedTuple):
    num_bytes: int
    baud_rate: int
    pulse_width: int
    start_time: int
    pause_time: int

    @staticmethod
    def parse() -> "Config":
        ap = argparse.ArgumentParser()
        ap.add_argument("-n", "--num-bytes", type=int, default=1024)
        ap.add_argument("-r", "--baud-rate", type=int, default=2400)
        ap.add_argument("-t", "--start-time", type=int, default=int(1e6))
        ap.add_argument("-p", "--pause-time", type=int, default=0)
        args = ap.parse_args()
        return Config(
            num_bytes=args.num_bytes,
            baud_rate=args.baud_rate,
            pulse_width=int(1e9 / args.baud_rate),
            start_time=args.start_time,
            pause_time=args.pause_time,
        )


def write_input_log(writer: TextIO, config: Config, data: bytes):

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
    header = bytes(
        (
            (config.num_bytes >> 8) & 0xFF,
            config.num_bytes & 0xFF,
        )
    )
    t = write_bytes(config.start_time, header)
    t += config.pause_time
    write_bytes(t, data)


def write_expect_log(writer: TextIO, data: bytes):
    for byte in data:
        writer.write(f"_,output,io4,0x{byte:02x}\n")


def main():
    config = Config.parse()
    data = random.randbytes(config.num_bytes)
    with open("rxlong-input.evlog", "w") as fobj:
        write_input_log(fobj, config, data)
    with open("rxlong-expect.evlog", "w") as fobj:
        write_expect_log(fobj, data)


sys.exit(main())
