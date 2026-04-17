; countdown.asm — count R1 from 7 down to 0, then halt.
;
; Halt convention: `jmp R_self` where the register holds the address of the
; jmp instruction itself. The simulator detects this pattern and stops.
;
; Pre-loads:
;   R0 = address of `loop`   (for the back-edge JMP)
;   R7 = address of `halt`   (for the self-jmp halt)
;   R1 = 7                   (counter)

    ldi  R0, loop       ; 0: R0 <- loop address (3)
    ldi  R7, halt       ; 1: R7 <- halt address (6)
    ldi  R1, 7          ; 2: counter = 7

loop:
    dec  R1, R1         ; 3: R1--
    brz  R1, halt       ; 4: if R1 == 0, branch forward to halt
    jmp  R0             ; 5: otherwise back to loop

halt:
    jmp  R7             ; 6: jmp to self → halt
