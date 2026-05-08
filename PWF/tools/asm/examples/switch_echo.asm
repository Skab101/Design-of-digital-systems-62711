; PWF demo program: vis switches paa LED og 7-seg.
;
; Tryk (eller hold) BTNC for at latch'e SW ind i MR7. CPU'en loop'er
; konstant og kopierer MR7 til:
;   LEDs (MR2)        <- MR7
;   7-seg low (MR0)   <- MR7
;
; Adfaerd:
;   - Pulse BTNC: snapshot af SW vises og holdes paa display.
;   - Hold BTNC + skift SW: display foelger SW live; slipper -> fryser.
;
; Memory layout (LDI er 3-bit, saa I/O-adresser >= 0xF8 skal preloades
; som .word konstanter paa adresser <= 7):
;   addr 0..1: bootstrap (jmp om data-tabel)
;   addr 2..5: .word tabel (I/O-adresser + main_loop)
;   addr 6+ : init og hovedloop

    ldi  R7, init         ; 0: R7 <- init addr (skal vaere <= 7)
    jmp  R7               ; 1: hop over data-tabellen

A_MR2:   .word 0xFA       ; 2: adresse paa MR2 (LEDs)
A_MR0:   .word 0xF8       ; 3: adresse paa MR0 (7-seg low byte)
A_MR7:   .word 0xFF       ; 4: adresse paa MR7 (BTNC-latched SW)
A_LOOP:  .word main_loop  ; 5: adresse paa main_loop (loades i R7)

init:                     ; 6
    ; R7 skal pege paa main_loop (>7), saa vi loader den fra A_LOOP.
    ldi  R0, 5            ; 6: R0 <- 5 (ptr til A_LOOP)
    ld   R7, R0           ; 7: R7 <- main_loop addr

    ; Cache I/O-adresser i registre saa hovedloop'et er hurtigt.
    ldi  R0, 2            ; 8
    ld   R3, R0           ; 9: R3 <- 0xFA (MR2)
    ldi  R0, 3            ; 10
    ld   R4, R0           ; 11: R4 <- 0xF8 (MR0)
    ldi  R0, 4            ; 12
    ld   R5, R0           ; 13: R5 <- 0xFF (MR7)

main_loop:                ; 14
    ld   R1, R5           ; 14: R1 <- M[0xFF] = MR7 = button-latched SW
    st   R3, R1           ; 15: M[0xFA] <- R1  -> LEDs
    st   R4, R1           ; 16: M[0xF8] <- R1  -> 7-seg low byte
    jmp  R7               ; 17: tilbage til main_loop
