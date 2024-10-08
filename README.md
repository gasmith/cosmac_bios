# COSMAC BIOS

This is some _very_ early work towards a simple BIOS for the [1802 membership
card](http://www.retrotechnology.com/memship/memship.html).

## Presumptions and Conventions

Since this is a side project targeting a particular piece of hardware, it's not
super-flexible. I've made lots of assumptions.

### Memory Layout

We presume that RAM occupies `0x0000-0x7fff` and EEPROM occupies
`0x8000-0xffff`. There are several special-purpose regions.

| Address  | Purpose |
| -------- | ------- |
| `0x0000` | Initial program counter and EEPROM loader target |
| `0x0100` | Toggled-in loader target |
| `0x7fff` | Stack (grows downward) |
| `0x8000` | EEPROM loader entrypoint |
| `0xfb00` | Start of BIOS |
| `0xff00` | BIOS virtual function table |
| `0xfffc` | BIOS version |
| `0xfffe` | BIOS XOR checksum |

### Register Conventions

We use the following register conventions (which might be expanded as the BIOS
function call ecosystem builds out). Registers `r2` through `r6` are described
in the 1802 programming guide as part of the "Standard call and return
technique" (SCRT), from which we feel no strong urge to deviate.

| Register | Purpose |
| -------- | ------- |
| `r0` | DMA |
| `r1` | ISR |
| `r2` | Stack pointer |
| `r3` | Program counter |
| `r4` | `call` trampoline program counter |
| `r5` | `retf` trampoline program counter |
| `r6` | Return address |
| `r7` | Reserved for future use |
| `r8`-`rf` | General purpose |

### UART

We presume that there is no hardware UART, and so we implement a bit-banged
half-duplex UART in software. `EF3` is used for receive, and `Q` for transmit.
Both signals are presumed to be inverted, from the 1802's point of view. For
example, `seq` brings the transmit line low, and `bn3` branches when the receive
line is high.

We presume that 1802 is clocked with a 4MHz source and uses 8 clock pulses per
machine cycle. Most instructions uses 2 machine cycles (4us), except for the
long-branch instructions that require 3. While the PLLs themselves are pretty
compact, and can easily support 9600 baud (~26 instructions) or higher, we
generally prefer 2400 baud (~104 instructions), which provides ample room for
function calls and intermediate logic.

## Building

This project uses the following toolchain:

 - [ASM/02](https://github.com/arhefner/Asm-02): Cross compiler
 - [cosmac_emu](https://github.com/gasmith/cosmac_emu): Emulator, for tests
 - [pyserial](https://github.com/pyserial/pyserial): Serial interfacing

To build `stage1.bin` and other images, ensure that `asm02` is in your path, and run `make`.

To run tests, enter the [test](./test) directory, ensure that `cosmac_emu` is in
your path, and run `make test`.

## Bootstrap procedure

The basic idea:

  1. `make`
  2. Toggle in `loader.bin` and reset.
  3. `./bootstrap.py load --image stage1.bin`
  4. Toggle in `lbr 0100h` (`0c 01 00`) and reset.
  5. `./bootstrap.py burn`

Because the BIOS is not relocatable, we make a `stage1` image that directly
includes enough functionality to run the UART and write to EEPROM. Appended to
that image are the `loader` and BIOS images that we intend to write EEPROM.

The bootstrap script loads the `stage1` image into `0x0100` in step 3, and then
uses the `minimon` interface to write the embedded `loader` and BIOS images to
EEPROM in step 5. During the burn, the front display of the membership card
should briefly show the 8-bit checksum for the loader image, followed by the
8-bit checksum for the BIOS. The latter should _always_ be `00`, since the BIOS
is stamped with its own partial checksum.
