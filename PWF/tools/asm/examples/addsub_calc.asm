; addsub_calc.asm
; -----------------------------------------------------------
; Plus/minus-kalkulator. Resultat paa de 2 nederste 7-seg cifre.
;
; VIGTIGT om branches paa denne CPU:
;   Flagene er KOMBINATORISKE (intet flag-register). BRZ tester
;   selv registret i sit A-slot: "BRZ A<reg>" hopper hvis
;   R[reg] == 0. Man kan altsaa IKKE saette et flag med en
;   tidligere instruktion og saa branche -- branchen kigger kun
;   paa sit eget A-register. Offset (D+B slot) er relativt til
;   branchens EGEN adresse (PC taeller ikke under INF).
;
; Brug:
;   1) Saet SW = A. Tryk BTNR  -> A latches i MR3 (0xFB).
;   2) Saet SW = B. Tryk BTNL  -> B latches i MR4 (0xFC).
;   3) Vaelg operation med BTND (latches i MR5 = 0xFD):
;        - SW = 0, tryk BTND  -> MINUS  (A - B)   [ogsaa default v. reset]
;        - SW = 1, tryk BTND  -> PLUS   (A + B)   (alt != 0 = plus)
;   4) 7-seg viser resultatet som "00 RR" (hex, 8-bit; negativ
;      vises i 2's-komplement, sum > 255 wrapper).
;
; Registerbrug:
;   R0 - konstant 0
;   R1 - operand A (MR3)
;   R2 - konstant 0xFF (beregnet i PC=0)
;   R3 - scratch (adresser)
;   R4 - mode (MR5): 0 = minus, !=0 = plus  -- testes direkte af BRZ
;   R5 - operand B (MR4)
;   R6 - resultat
;   R7 - jump-target

NOT R2 R4         ; PC=0:  R2 = ~R4 = 0xFF (R4 = 0 ved reset)
                  ; --- loop start (JMP tilbage hertil) ---
LDI R4 4          ; PC=1:  R4 = 4
SUB R3 R2 R4      ; PC=2:  R3 = 0xFF - 4 = 0xFB (MR3 = BTNR-latch = A)
LD  R1 R3         ; PC=3:  R1 = A
LDI R4 3          ; PC=4:  R4 = 3
SUB R3 R2 R4      ; PC=5:  R3 = 0xFF - 3 = 0xFC (MR4 = BTNL-latch = B)
LD  R5 R3         ; PC=6:  R5 = B
LDI R4 2          ; PC=7:  R4 = 2
SUB R3 R2 R4      ; PC=8:  R3 = 0xFF - 2 = 0xFD (MR5 = BTND-latch = mode)
LD  R4 R3         ; PC=9:  R4 = mode (0 = minus, !=0 = plus)
SUB R6 R1 R5      ; PC=10: R6 = A - B   (minus beregnes altid foerst)
BRZ D0 A4 B2      ; PC=11: hvis R4==0 (minus) -> hop til PC=13 (spring
                  ;        ADD over). offset +2 relativt til PC=11.
ADD R6 R1 R5      ; PC=12: R4!=0 (plus): R6 = A + B (overskriver)
                  ; --- write result (PC=13) ---
LDI R4 7          ; PC=13: R4 = 7
SUB R3 R2 R4      ; PC=14: R3 = 0xFF - 7 = 0xF8 (MR0 = 7-seg low byte)
ST  R3 R6         ; PC=15: M[0xF8] = R6 = resultat
LDI R4 6          ; PC=16: R4 = 6
SUB R3 R2 R4      ; PC=17: R3 = 0xFF - 6 = 0xF9 (MR1 = 7-seg high byte)
ST  R3 R0         ; PC=18: M[0xF9] = 0 (ryd hoeje cifre; MR1 er reelt
                  ;        altid 0 pga. Zero_Filler_2, men ufarligt)
LDI R7 1          ; PC=19: R7 = 1
JMP R7            ; PC=20: loop tilbage til PC=1
