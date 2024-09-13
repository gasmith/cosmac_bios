; The call macro uses R_PC to read the address of the function to call.
.op "CALL","W","D4 H1 L1"
.op "RETF","","D5"

; Convenience macros for moving words around.
.op "MOV","NR","8$2 A$1 9$2 B$1"
.op "MOV","NW","F8 L2 A$1 F8 H2 B$1"

; The push & pop macros presume `sex R_SP`.
.op "PUSH","N","8$1 73 9$1 73"
.op "POP","N","60 72 B$1 F0 A$1"

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

; Entrypoint
  mov   R_RA, main
  br    init_stack

; A little test program to output a random byte on lines 1, 2, 3, 4, and 5, in
; that order, and then enter the idle loop.
main:
  sex   r8
  out   1
  call  foo
  sex   r8
  out   5
  idl

foo:
  sex   r8
  out   2
  call  bar
  sex   r8
  out   4
  retf

bar:
  sex   r8
  out   3
  retf

; -- init_stack
; 
; Configure stack registers and "return" to the address of the main entrypoint
; in R_RA.
init_stack:
  ; Set stack pointer.
  ldi   STACK_PAGE
  phi   R_SP
  ldi   0ffh
  plo   R_SP

  ; Poison the last return address on the stack: if the main entrypoint attempts
  ; a retf, jump into an idle loop. Note that words are stored in big-endian
  ; order.
  sex   R_SP
  ldi   idle.0
  stxd
  ldi   idle.1
  stxd

  ; Set PCs for call & ret helpers.
  mov   R_CALL, call
  mov   R_RETF, retf

  ; Do the initial "return" to `start`.
  sep   R_RETF

; -- idle
;
; An eternal idle loop.
idle:
  idl

; -- call
;
; Function call helper. Invoked with `sep R_CALL, dw <addr>`, or the `call
; <addr>` macro. Note the wraparound `br call-1` to restore `R_CALL` after each
; invocation.
  sep   R_PC
call:
  ; Save previous return address to the stack.
  sex   R_SP
  push  R_RA

  ; Copy R_PC to R_RA.
  mov   R_RA, R_PC

  ; Load the big-endian address into R_PC, and incr R_RA as we go.
  lda   R_RA
  phi   R_PC
  lda   R_RA
  plo   R_PC

  ; Jump to new R_PC.
  br    call-1

; -- retf
;
; Function return helper. Named `retf` to avoid confusion with the 1802 `ret`
; operation. Invoked with `sep R_RETF`, or the `retf` macro. Note the wraparound
; `br retf-1` to restore `R_RETF` after each invocation.
  sep   R_PC
retf:
  ; Copy R_RA to R_PC.
  mov   R_PC, R_RA

  ; Restore previous big-endian R_RA from the stack.
  sex   R_SP
  pop   R_RA

  ; Jump to new R_PC.
  br    retf-1

version:  db  0,1,0
checksum: db  0,0,0,0
