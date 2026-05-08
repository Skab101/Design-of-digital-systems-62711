; PWF demo program: continuously compute MR3 + MR4, drive displays.
;
;   LEDs (MR2)        <- MR3 + MR4
;   7-seg low (MR0)   <- MR3 + MR4
;   7-seg high (MR1)  <- MR3
;
; BTNR latches SW into MR3 (operand A).
; BTNL latches SW into MR4 (operand B).
;
; Memory layout (LDI immediate is 3-bit, so I/O addrs >= 0xF8 must be
; preloaded as .word constants at addresses <= 7):
;   addr 0..1: bootstrap (jmp around data table)
;   addr 2..6: .word table (I/O addresses)
;   addr 7+ : main loop

    ldi  R7, loop_start   ; 0: R7 <- address of loop_start (must be <= 7)
    jmp  R7               ; 1: jump over the data table

A_MR2:   .word 0xFA       ; 2: address of MR2 (LEDs)
A_MR0:   .word 0xF8       ; 3: address of MR0 (7-seg low byte)
A_MR1:   .word 0xF9       ; 4: address of MR1 (7-seg high byte)
A_MR3:   .word 0xFB       ; 5: address of MR3 (op A, latched on BTNR)
A_MR4:   .word 0xFC       ; 6: address of MR4 (op B, latched on BTNL)

loop_start:               ; 7: main loop entry
    ; Cache I/O addresses into registers (R3=MR3, R4=MR4, R5 reused)
    ldi  R0, 5            ; R0 <- 5 (A_MR3 ptr)
    ld   R3, R0           ; R3 <- 0xFB
    ldi  R0, 6            ; R0 <- 6 (A_MR4 ptr)
    ld   R4, R0           ; R4 <- 0xFC

    ; Read operands
    ld   R1, R3           ; R1 <- M[0xFB] = MR3 (button-latched)
    ld   R2, R4           ; R2 <- M[0xFC] = MR4 (button-latched)

    ; Compute sum
    add  R6, R1, R2       ; R6 <- R1 + R2

    ; Write sum to LEDs (MR2)
    ldi  R0, 2            ; R0 <- 2 (A_MR2 ptr)
    ld   R5, R0           ; R5 <- 0xFA
    st   R5, R6           ; M[0xFA] <- R6 -> LED <- sum

    ; Write sum to 7-seg low byte (MR0)
    ldi  R0, 3            ; R0 <- 3 (A_MR0 ptr)
    ld   R5, R0           ; R5 <- 0xF8
    st   R5, R6           ; M[0xF8] <- R6 -> 7seg-low <- sum

    ; Write MR3 to 7-seg high byte (MR1)
    ldi  R0, 4            ; R0 <- 4 (A_MR1 ptr)
    ld   R5, R0           ; R5 <- 0xF9
    st   R5, R1           ; M[0xF9] <- R1 -> 7seg-high <- MR3

    jmp  R7               ; loop back to loop_start (R7 = 7)
