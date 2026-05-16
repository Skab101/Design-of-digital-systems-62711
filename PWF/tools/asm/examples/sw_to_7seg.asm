; sw_to_7seg.asm
; -----------------------------------------------------------
; Viser SW-vaerdien paa 7-segment displayet i hex.
; SUB-baseret (FS=0101 -> Cin=1), samme stil som sw_to_led_sub.
;
; Brug: saet SW, tryk BTNR -> 7-seg viser SW som 2 hex-cifre
;       (de to nederste cifre). Slip -> vaerdien fryser.
;
; 7-seg D_word = MR1:MR0. Vi skriver SW til MR0 (lave byte) og
; 0 til MR1 (hoeje byte), saa displayet viser "00 SW".

NOT R2 R4         ; PC=0:  R2 = ~R4 = 0xFF (R4 = 0 ved reset)
                  ; --- loop start (JMP tilbage hertil) ---
LDI R4 4          ; PC=1:  R4 = 4
SUB R3 R2 R4      ; PC=2:  R3 = 0xFF - 4 = 0xFB (MR3 = BTNR-latch)
LD  R6 R3         ; PC=3:  R6 = M[0xFB] = button-latched SW
LDI R5 7          ; PC=4:  R5 = 7
SUB R1 R2 R5      ; PC=5:  R1 = 0xFF - 7 = 0xF8 (MR0 = 7-seg low byte)
ST  R1 R6         ; PC=6:  M[0xF8] = R6 -> 7-seg low byte = SW
LDI R5 6          ; PC=7:  R5 = 6
SUB R1 R2 R5      ; PC=8:  R1 = 0xFF - 6 = 0xF9 (MR1 = 7-seg high byte)
ST  R1 R0         ; PC=9:  M[0xF9] = R0 = 0 -> 7-seg high byte = 0
LDI R7 1          ; PC=10: R7 = 1
JMP R7            ; PC=11: PC := 1 (loop)
