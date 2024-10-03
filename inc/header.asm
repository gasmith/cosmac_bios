#ifndef _COMMON_ASM_
#define _COMMON_ASM_

; The call macro uses R_PC to read the address of the function to call.
.op "CALL","W","d4 H1 L1"
.op "RETF","","d5"

; Convenience macros for moving words around.
.op "MOV","NR","8$2 a$1 9$2 b$1"
.op "MOV","NW","f8 L2 a$1 f8 H2 b$1"

; The push & pop macros presume `X=R_SP`, and big-endian word layout.
.op "PUSH","R","8$1 73 9$1 73"
.op "POP","R","60 72 b$1 f0 a$1"

; 16-bit arithmetic. Note that the 2-register variants use `M(X)` as
; temporary storage.
.op "ADD16","RR","8$2 52 $81 f4 a$1 9$2 52 9$1 74 b$1"
.op "ADD16","RW","8$1 fc L2 a$1 9$1 7c H2 b$1"
.op "SUB16","RR","8$2 52 8$1 f7 a$1 9$2 52 9$1 77 b$1"
.op "SUB16","RW","8$1 ff L2 a$1 9$1 7f H2 b$1"
.op "SHL16","R","8$1 fe a$1 9$1 7e b$1"

; Reserved registers, from the 1802 programming guide, which recommends the use
; of registers 2-6 as part of the "Standard call and return technique" (SCRT).
; The chip is hard-coded to use r0 for DMA, and r1 for the interrupt service
; routine.
#define R_DMA     r0
#define R_ISR     r1
#define R_SP      r2
#define R_PC      r3
#define R_CALL    r4
#define R_RETF    r5
#define R_RA      r6

; RAM code page where stack is located.
#define STACK_PAGE  07fh

; EEPROM constants
#define EEPROM_BASE       08000h
#define EEPROM_PAGE_SIZE  64
#define EEPROM_PAGE_MASK  63

#endif
