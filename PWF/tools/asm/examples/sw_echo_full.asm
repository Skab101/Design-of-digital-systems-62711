; Switches -> LED + alle 4 hex-cifre paa 7-seg.
; Pulse BTNR med SW sat for at latche SW i MR3, CPU loop'er
; og kopierer MR3 til MR2 (LED), MR0 (7-seg low) og MR1 (7-seg high).
;
; Identisk i logik med teammate_fixed.asm men i dsdasm-syntaks (R0..R7).

NOT R2 R4         ; R2 = ~R4 = 0xFF (R4 starter paa 0)
LDI R4 4
SUB R3 R2 R4      ; R3 = 0xFB (MR3)
LD  R6 R3         ; R6 = MR3 = button-latched SW
LDI R5 5
SUB R1 R2 R5      ; R1 = 0xFA (MR2 = LED)
ST  R1 R6         ; LED <- R6
LDI R7 7
NOT R7 R7         ; R7 = 0xF8 (MR0 = 7-seg low)
ST  R7 R6         ; 7-seg low <- R6
INC R7 R7         ; R7 = 0xF9 (MR1 = 7-seg high)
ST  R7 R6         ; 7-seg high <- R6
LDI R7 1          ; R7 = 1 (loop til LDI R4 4, R2 beholder 0xFF)
JMP R7
