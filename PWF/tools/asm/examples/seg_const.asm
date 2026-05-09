; seg_const.asm
; -----------------------------------------------------------
; Diagnostisk testprogram: skriver konstante vaerdier direkte
; til MR0 og MR1 -- INGEN knap-tryk noedvendige.
;
; Forventet 7-seg display efter rebuild + program: "0507"
;   - Hojre 2 cifre  (MR0) = 0x07
;   - Venstre 2 cifre (MR1) = 0x05
; LEDs er IKKE skrevet -> forbliver 0x00.
;
; Adresse-walk: vi starter ved 0xF9 (MR1) og DEC ned til 0xF8 (MR0).
; (En tidligere version startede ved 0xF8 og DEC'ede ned til 0xF7,
; som ikke er en MR-adresse -- bug.)

NOT R2 R0         ; PC=0: R2 = ~R0 = 0xFF (R0 er 0 ved reset)
                  ; --- loop start (jmp tilbage hertil) ---
LDI R6 7          ; PC=1: R6 = 7   (target value for MR0)
LDI R5 5          ; PC=2: R5 = 5   (target value for MR1)
LDI R4 6          ; PC=3: R4 = 6
SUB R1 R2 R4      ; PC=4: R1 = 0xFF - 6 = 0xF9 (MR1)
ST  R1 R5         ; PC=5: MR1 = 0x05  (7-seg high byte)
DEC R1 R1         ; PC=6: R1 = 0xF8 (MR0)
ST  R1 R6         ; PC=7: MR0 = 0x07  (7-seg low byte)
LDI R7 1          ; PC=8: R7 = 1
JMP R7            ; PC=9: PC := 1 (loop)
