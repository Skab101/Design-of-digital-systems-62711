; sw_to_led_sub.asm
; -----------------------------------------------------------
; Kopierer switches (SW) til LEDs - SUB-baseret variant.
; Bruger SUB i stedet for DEC, saa programmet ogsaa udoever
; Cin = FS_sig(0) paa hardware-niveau (FS=0101 -> Cin=1).
;
; Brug: saet SW, tryk BTNR -> LED viser SW. Slip -> fryser.

NOT R2 R4         ; PC=0: R2 = ~R4 = 0xFF (R4 er 0 ved reset)
                  ; --- loop start (jmp tilbage hertil) ---
LDI R4 4          ; PC=1: R4 = 4
SUB R3 R2 R4      ; PC=2: R3 = 0xFF - 4 = 0xFB (MR3 = BTNR latch)
LD  R6 R3         ; PC=3: R6 = MR3 = button-latched SW
LDI R5 5          ; PC=4: R5 = 5
SUB R1 R2 R5      ; PC=5: R1 = 0xFF - 5 = 0xFA (MR2 = LED)
ST  R1 R6         ; PC=6: LED <- R6
LDI R7 1          ; PC=7: R7 = 1
JMP R7            ; PC=8: PC := 1 (loop)
