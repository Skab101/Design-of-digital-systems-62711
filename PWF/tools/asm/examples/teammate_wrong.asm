; Teammate's original buggy program (D/A/B notation oversat til R).
; Logikfejl: JMP R7 hopper til I/O-space (0xF9) i stedet for at loope
; tilbage til programstart. Efter ST'en til LED (PC=6) overlever maaske
; den korrekte LED-vaerdi i kort tid, men den efterfoelgende JMP til
; 0xF9 sender CPU'en ud i kaos.

NOT R2 R4
LDI R4 4
SUB R3 R2 R4
LD  R6 R3
LDI R5 5
SUB R1 R2 R5
ST  R1 R6
LDI R7 7
NOT R7 R7
INC R7 R7
JMP R7
