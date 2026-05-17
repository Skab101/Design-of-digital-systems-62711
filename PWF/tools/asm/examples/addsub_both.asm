; addsub_both.asm
; -----------------------------------------------------------
; Viser BAADE A+B og A-B samtidigt paa 7-segment displayet.
; Ingen operations-knap noedvendig -- bruger kun BTNR og BTNL.
;
; Brug:
;   1) Saet SW = A. Tryk BTNR  -> A latches i MR3 (0xFB).
;   2) Saet SW = B. Tryk BTNL  -> B latches i MR4 (0xFC).
;   3) 7-seg viser  "SS DD"  (4 hex-cifre):
;        - oeverste 2 cifre (MR1) = (A + B) mod 256
;        - nederste 2 cifre (MR0) = (A - B) mod 256
;
; Eks: A=8, B=3  -> display 0B05  (sum=0x0B=11, diff=0x05=5).
; Negativ differens vises i 2's-komplement (A=3,B=8 -> diff=0xFB).
;
; Helt uden branches -> ingen branch-offset-faldgruber.
;
; Registerbrug:
;   R0 - konstant 0
;   R1 - operand A (MR3)
;   R2 - konstant 0xFF (beregnet i PC=0)
;   R3 - scratch (adresser)
;   R4 - A - B (differens)
;   R5 - operand B (MR4)
;   R6 - A + B (sum)
;   R7 - jump-target

NOT R2 R4         ; PC=0:  R2 = ~R4 = 0xFF (R4 = 0 ved reset)
                  ; --- loop start (JMP tilbage hertil) ---
LDI R4 4          ; PC=1:  R4 = 4
SUB R3 R2 R4      ; PC=2:  R3 = 0xFF - 4 = 0xFB (MR3 = BTNR-latch = A)
LD  R1 R3         ; PC=3:  R1 = A
LDI R4 3          ; PC=4:  R4 = 3
SUB R3 R2 R4      ; PC=5:  R3 = 0xFF - 3 = 0xFC (MR4 = BTNL-latch = B)
LD  R5 R3         ; PC=6:  R5 = B
ADD R6 R1 R5      ; PC=7:  R6 = A + B  (sum)
SUB R4 R1 R5      ; PC=8:  R4 = A - B  (differens)
LDI R3 7          ; PC=9:  R3 = 7
SUB R3 R2 R3      ; PC=10: R3 = 0xFF - 7 = 0xF8 (MR0 = 7-seg low byte)
ST  R3 R4         ; PC=11: M[0xF8] = R4 = (A-B)  -> nederste 2 cifre
LDI R3 6          ; PC=12: R3 = 6
SUB R3 R2 R3      ; PC=13: R3 = 0xFF - 6 = 0xF9 (MR1 = 7-seg high byte)
ST  R3 R6         ; PC=14: M[0xF9] = R6 = (A+B)  -> oeverste 2 cifre
LDI R7 1          ; PC=15: R7 = 1
JMP R7            ; PC=16: loop tilbage til PC=1
