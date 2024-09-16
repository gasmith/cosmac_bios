; init_stack: Set up stack registers and make the initial call to `R_RA`.
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
  ldi   retf_idle.0
  stxd
  ldi   retf_idle.1
  stxd

  ; Set PCs for call & ret helpers.
  mov   R_CALL, call
  mov   R_RETF, retf

  ; Do the initial "return" to `start`.
  sep   R_RETF

; retf_idle: An eternal idle loop.
retf_idle:
  idl

; call: Function call trampoline.
;
; Invoked with `sep R_CALL, dw <addr>`, or the `call <addr>` macro. Note the
; wraparound `br call-1` to restore `R_CALL` after each invocation.
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

; retf: Function return trampoline.
;
; Named `retf` to avoid confusion with the 1802 `ret` operation. Invoked with
; `sep R_RETF`, or the `retf` macro. Note the wraparound `br retf-1` to restore
; `R_RETF` after each invocation.
  sep   R_PC
retf:
  ; Copy R_RA to R_PC.
  mov   R_PC, R_RA

  ; Restore previous big-endian R_RA from the stack.
  sex   R_SP
  pop   R_RA

  ; Jump to new R_PC.
  br    retf-1
