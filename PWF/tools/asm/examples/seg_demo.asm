; seg_demo.asm
; -----------------------------------------------------------
; Demonstrerer LEDs + 4-digit 7-segment displayet samtidig:
;   BTNR-latched SW  ->  LEDs + 7-seg low  byte (hojre 2 hex-cifre)
;   BTNL-latched SW  ->            7-seg high byte (venstre 2 hex-cifre)
;
; Brug: saet SW, tryk BTNR -> LEDs og hojre del af 7-seg viser SW.
;        Skift SW, tryk BTNL -> venstre del af 7-seg viser den nye SW.
;        Den anden halvdel beholder sin tidligere vaerdi.
;
; Memory-map (relevante adresser):
;   0xF8  MR0  7-seg low  byte (writable)
;   0xF9  MR1  7-seg high byte (writable)
;   0xFA  MR2  LEDs            (writable)
;   0xFB  MR3  BTNR-latched SW (read-only)
;   0xFC  MR4  BTNL-latched SW (read-only)
;
; Adresser bygges via SUB fra R2 = 0xFF (R4 er konstant 0 ved reset
; saa NOT R2 R4 giver 0xFF). Derefter DEC for at rulle ned gennem
; den sammenhaengende blok 0xFA..0xF8.

NOT R2 R4         ; PC=0:  R2 = ~R4 = 0xFF
                  ; --- loop start (jmp tilbage hertil) ---
LDI R4 4          ; PC=1:  R4 = 4
SUB R3 R2 R4      ; PC=2:  R3 = 0xFF - 4 = 0xFB (MR3 = BTNR latch)
LD  R6 R3         ; PC=3:  R6 = MR3 (BTNR-latched SW)

LDI R4 3          ; PC=4:  R4 = 3
SUB R3 R2 R4      ; PC=5:  R3 = 0xFF - 3 = 0xFC (MR4 = BTNL latch)
LD  R5 R3         ; PC=6:  R5 = MR4 (BTNL-latched SW)

LDI R4 5          ; PC=7:  R4 = 5
SUB R1 R2 R4      ; PC=8:  R1 = 0xFF - 5 = 0xFA (LED)
ST  R1 R6         ; PC=9:  LED      <- R6 (BTNR vaerdi)
DEC R1 R1         ; PC=10: R1 = 0xF9 (MR1 = 7-seg high)
ST  R1 R5         ; PC=11: 7-seg hi <- R5 (BTNL vaerdi)
DEC R1 R1         ; PC=12: R1 = 0xF8 (MR0 = 7-seg low)
ST  R1 R6         ; PC=13: 7-seg lo <- R6 (BTNR vaerdi)

LDI R7 1          ; PC=14: R7 = 1
JMP R7            ; PC=15: PC := 1 (loop)
