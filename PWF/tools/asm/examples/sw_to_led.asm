; sw_to_led.asm
; -----------------------------------------------------------
; Kopierer switches (SW) til LEDs.
; Brug: saet SW, tryk BTNR -> LED viser SW. Slip -> fryser.
;
; DEC-baseret variant: bruger NOT/DEC i stedet for SUB, saa det
; virker uanset om bitstreamen har Cin = '0' eller Cin = FS_sig(0).
; (DEC's FS-kode har FS0=0 begge veje, saa Cin er ligegyldigt.)
;
; Den "rigtige" SUB-baserede version (der antager Cin = FS_sig(0))
; staar i kommentar nederst -- den vil virke saa snart bitstreamen
; faktisk indeholder Cin-fixet (se HANDOFF.md aabne issues).

NOT R2 R0         ; PC=0: R2 = ~0 = 0xFF
                  ; --- loop start (jmp tilbage hertil) ---
DEC R3 R2         ; PC=1: R3 = R2 - 1 = 0xFE
DEC R3 R3         ; PC=2: R3 = 0xFD
DEC R3 R3         ; PC=3: R3 = 0xFC
DEC R3 R3         ; PC=4: R3 = 0xFB (MR3 = BTNR latch)
LD  R6 R3         ; PC=5: R6 = MR3 = button-latched SW
DEC R3 R3         ; PC=6: R3 = 0xFA (MR2 = LED)
ST  R3 R6         ; PC=7: LED <- R6
LDI R7 1          ; PC=8: R7 = 1
JMP R7            ; PC=9: PC := 1 (loop)

; SUB-baseret variant (kraever Cin = FS_sig(0) i bitstream):
;
;   NOT R2 R4         ; R2 = 0xFF
;   LDI R4 4
;   SUB R3 R2 R4      ; R3 = 0xFB (MR3)
;   LD  R6 R3
;   LDI R5 5
;   SUB R1 R2 R5      ; R1 = 0xFA (LED)
;   ST  R1 R6
;   LDI R7 1
;   JMP R7
