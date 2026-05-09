; mr0_only.asm
; -----------------------------------------------------------
; Minimal isolerings-test for MR0 (7-seg low byte / 0xF8).
; INGEN MR1 skrives. INGEN DEC-kaede. Bare en enkelt ST til MR0.
;
; Forventet 7-seg display: "0007"
;   - Hojre 2 cifre  (MR0) = 0x07
;   - Venstre 2 cifre (MR1) = 0x00 (uskreven)
;
; Hvis displayet viser "0007" -> MR0-stien virker, og bug'en sad
; et andet sted (sandsynligvis i seg_const-program-strukturen).
;
; Hvis displayet viser "0000" -> MR0-stien er broken paa hardware.
; Vi kan saa zero-in paa det.

NOT R2 R0         ; R2 = 0xFF
LDI R6 7          ; R6 = 7
LDI R4 7          ; R4 = 7
SUB R3 R2 R4      ; R3 = 0xFF - 7 = 0xF8 (MR0)
ST  R3 R6         ; MR0 = 0x07
LDI R7 1          ; halt-loop
JMP R7
