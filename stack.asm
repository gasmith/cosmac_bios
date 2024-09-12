.op "PUSH","N","8$1 73 9$1 73"
.op "POP","N","60 72 B$1 F0 A$1"
.op "CALL","W","DC H1 L1"
.op "RETS","","DB"
.op "MOV","NR","8$2 A$1 9$2 B$1"
.op "MOV","NW","F8 L2 A$1 F8 H2 B$1"

#define PC        rf
#define SP        re
#define SAVE      rd
#define PC_CALL   rc
#define PC_RETS   rb
#define RET_ADDR  ra

#define STACK_PAGE 07fh

; Entrypoint
  mov   RET_ADDR, main
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
  rets

bar:
  sex   r8
  out   3
  rets

; -- init_stack
; 
; Configure stack registers and "return" to the address of the main entrypoint
; in RET_ADDR.
init_stack:
  ; Set stack pointer.
  ldi   STACK_PAGE
  phi   SP
  ldi   0ffh
  plo   SP

  ; Poison the last return address on the stack: if the main entrypoint attempts
  ; a rets, jump into an idle loop. Note that words are stored in big-endian
  ; order.
  sex   SP
  ldi   idle.0
  stxd
  ldi   idle.1
  stxd

  ; Set PCs for call & ret helpers.
  mov   PC_CALL, call
  mov   PC_RETS, ret

  ; Do the initial "return" to `start`.
  sep   PC_RETS

; -- idle
;
; An eternal idle loop.
idle:
  idl

; -- call
;
; Function call helper. Invoked with `sep PC_CALL, dw <addr>`, or the `call
; <addr>` custom assembler operation. Note the wraparound `br call-1` to restore
; `PC_CALL` after each invocation.
  sep   PC
call:
  ; Save D in temp register.
  plo   SAVE

  ; Save previous return address to the stack.
  sex   SP
  glo   RET_ADDR
  stxd
  ghi   RET_ADDR
  stxd

  ; Copy PC to RET_ADDR
  glo   PC
  plo   RET_ADDR
  ghi   PC
  phi   RET_ADDR

  ; Load the big-endian subroutine address into PC, incrementing RET_ADDR as we
  ; go.
  lda   RET_ADDR
  phi   PC
  lda   RET_ADDR
  plo   PC

  ; Recover D
  glo   SAVE
  br    call-1

; -- rets
;
; Function return helper. Named `rets` to avoid confusion with the 1802 `ret`
; operation. Invoked with `sep PC_RETS`, or the `rets` custom assembler
; operation. Note the wraparound `br rets-1` to restore `PC_RETS` after each
; invocation.
  sep   PC
rets:
  ; Save D in temp register.
  plo   SAVE

  ; Copy RET_ADDR to PC
  glo   RET_ADDR
  plo   PC
  ghi   RET_ADDR
  phi   PC

  ; Restore previous big-endian RET_ADDR from the stack.
  sex   SP
  irx
  ldxa
  phi   RET_ADDR
  ldx
  plo   RET_ADDR

  ; Restore D
  glo   SAVE
  br    rets-1

version:  db  0,1,0
checksum: db  0,0,0,0
