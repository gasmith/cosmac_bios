; Blinkenlights demo.
demo:
  ldi   0
  plo   r9
  phi   r9
demo_out:
  ghi   r9
  str   R_SP
  out   4
  dec   R_SP
demo_wait:
  inc   r9
  glo   r9
  sex   R_SP
  sex   R_SP
  sex   R_SP
  sex   R_SP
  bz    demo_out
  br    demo_wait
