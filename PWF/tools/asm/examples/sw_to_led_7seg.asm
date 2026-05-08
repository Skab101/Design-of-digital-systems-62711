; Switches -> LED + 7-seg low byte.
; Brug: saet SW, pulse BTNR -> MR3 latches SW. CPU loop'er og kopierer
; MR3 til MR2 (LED) og MR0 (7-seg low). Slip BTNR -> display fryser.
;
; ISA-begraensninger der dikterer designet:
;   - LDI har 3-bit immediate, dvs. kun vaerdier 0..7 kan loades direkte
;   - I/O-adresser er 0xF8..0xFF (>= 248) -- kan IKKE loades med LDI
;   - Vi udregner derfor I/O-adresser ved at NOT'e 0 til 0xFF og SUB'e
;     en 3-bit konstant ned

; ============================================================
; INIT (kun foerste iteration -- vi loop'er tilbage til PC=1
; bagefter, saa NOT'en koeres aldrig igen)
; ============================================================
NOT R2 R4         ; PC=0: R2 = ~R4 = ~0x00 = 0xFF
                  ;       (R4 starter paa 0 efter reset, saa NOT giver 0xFF.
                  ;        R2 holder 0xFF gennem hele loop'et som "base".)

; ============================================================
; HOVED-LOOP (jmp tilbage hertil for hver iteration)
; ============================================================
LDI R4 4          ; PC=1: R4 = 4
SUB R3 R2 R4      ; PC=2: R3 = R2 - R4 = 0xFF - 4 = 0xFB  (MR3 adresse)
LD  R6 R3         ; PC=3: R6 = M[0xFB] = MR3 = button-latched SW

; --- skriv R6 til LED (MR2 = 0xFA) ---
LDI R5 5          ; PC=4: R5 = 5
SUB R1 R2 R5      ; PC=5: R1 = 0xFF - 5 = 0xFA  (LED adresse)
ST  R1 R6         ; PC=6: M[0xFA] = R6 -> LED <- SW

; --- skriv R6 til 7-seg low byte (MR0 = 0xF8) ---
LDI R5 7          ; PC=7: R5 = 7
SUB R1 R2 R5      ; PC=8: R1 = 0xFF - 7 = 0xF8  (MR0 adresse)
ST  R1 R6         ; PC=9: M[0xF8] = R6 -> 7-seg low <- SW

; --- loop tilbage ---
LDI R7 1          ; PC=10: R7 = 1  (springer til PC=1, ikke 0,
                  ;        saa vi IKKE koerer NOT R2 R4 igen.
                  ;        R4 er nu 7, saa NOT ville give 0xF8 og oedelaegge R2)
JMP R7            ; PC=11: PC := R7 = 1  (backward jump til hoved-loop)
