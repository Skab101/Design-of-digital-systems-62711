; calculator.asm
; Simpel multiplikations-kalkulator vha. gentagen addition.
;
; Brug:
;   1) Saet SW til operand A. Tryk BTNR -> A latches i MR3 (0xFB).
;   2) Saet SW til operand B. Tryk BTNL -> B latches i MR4 (0xFC).
;   3) 7-segment displayet viser AA RR (4 hex-cifre):
;        - oeverste 2 cifre = A (fra MR1)
;        - nederste 2 cifre = (A * B) mod 256 (fra MR0)
;
; Programmet kører kontinuerligt: hver gang en knap genlatcher en ny
; vaerdi, opdateres displayet automatisk paa naeste loop-runde.
;
; Bemaerk: 8-bit ALU, saa resultatet er trunkeret. For "rigtige"
; resultater hold A*B < 256 (fx A,B <= 15 garanterer det).
;
; Registerbrug:
;   R0 - konstant 0
;   R1 - operand A (laeses fra MR3)
;   R2 - scratch (initial 0xFF setup; siden flag-saetter)
;   R4 - akkumulator / 8-bit produkt
;   R5 - taeller (B fra MR4, decrement til 0) / temp-adresse
;   R6 - base-adresse 0xF8 (= MR0, 7-seg low byte)
;   R7 - jump-target

; ============================================================
; SETUP -- beregn base-adresse for I/O-segmentet
; ============================================================
NOT D2 A0           ; PC=0:  R2 = NOT 0 = 0xFF
LDI D4 B7           ; PC=1:  R4 = 7
SUB D6 A2 B4        ; PC=2:  R6 = 0xFF - 7 = 0xF8 (MR0 adresse)

; ============================================================
; OUTER LOOP -- laes A og B, multiplicer, skriv resultat
; ============================================================
ADI D5 A6 B3        ; PC=3:  R5 = 0xF8 + 3 = 0xFB (MR3 adresse, BTNR-latch)
LD D1 A5            ; PC=4:  R1 = M[0xFB] = A
ADI D5 A6 B4        ; PC=5:  R5 = 0xF8 + 4 = 0xFC (MR4 adresse, BTNL-latch)
LD D5 A5            ; PC=6:  R5 = M[0xFC] = B (overskriver adresse-temp)
LDI D4 B0           ; PC=7:  R4 = 0 (akkumulator nulstillet)
LDI D7 B7           ; PC=8:  R7 = 7
ADI D7 A7 B3        ; PC=9:  R7 = 7 + 3 = 10 (mul_check entry)

; ============================================================
; MUL LOOP -- R4 += R1 (=A) gentages indtil R5 (=B) er 0
;   BRZ ved PC=11 dobbeltfunktion: tjekker baade B=0 ved start
;   og taelleren naar den naar 0 efter en runde (flag fra DEC).
; ============================================================
MOVA D2 A5          ; PC=10: R2 = R5; saetter Z = (R5 == 0)
BRZ D0 A0 B4        ; PC=11: hvis Z, spring til write.
                    ;        offset relativt til PC=11: 11+4 = PC=15.
ADD D4 A4 B1        ; PC=12: R4 += R1
DEC D5 A5           ; PC=13: R5--; flag Z = (R5 == 0)
JMP A7              ; PC=14: tilbage til PC=10 (R7=10)

; ============================================================
; WRITE -- skriv resultat til MR0, A til MR1 (display "AA RR")
; ============================================================
ST A6 B4            ; PC=15: M[0xF8] = R4 = (A*B) mod 256 -> MR0
ADI D5 A6 B1        ; PC=16: R5 = 0xF9 (MR1 adresse, 7-seg high byte)
ST A5 B1            ; PC=17: M[0xF9] = R1 = A -> MR1
LDI D7 B3           ; PC=18: R7 = 3 (outer_loop)
JMP A7              ; PC=19: tilbage til outer_loop
