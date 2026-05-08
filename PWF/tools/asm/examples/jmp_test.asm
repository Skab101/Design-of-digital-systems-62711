; JMP test: forward-jump over en trap-instruktion.
;
;   - JMP virker korrekt -> LED = 0x03 (PASS)
;   - JMP gor ingenting (PC bare inkrementerer) -> LED = 0x07 (FAIL)
;
; Strategi: laeg PASS-vaerdien i R6 foer JMP, JMP til ST, og hav en
; trap-instruktion mellem JMP og ST som ville overskrive R6 med FAIL
; hvis vi ikke spring forbi den.

NOT R2 R4         ; PC=0: R2 = 0xFF
LDI R5 5
SUB R1 R2 R5      ; PC=2: R1 = 0xFA (LED)
LDI R6 3          ; PC=3: R6 = PASS (0x03)
LDI R7 7          ; PC=4: R7 = 7 (jump target = PC 7)
JMP R7            ; PC=5: spring til PC=7
LDI R6 7          ; PC=6: TRAP: ville saette R6=FAIL (0x07)
ST  R1 R6         ; PC=7: LED <- R6
LDI R7 7          ; PC=8: halt target
JMP R7            ; PC=9: halt-loop til PC=7
