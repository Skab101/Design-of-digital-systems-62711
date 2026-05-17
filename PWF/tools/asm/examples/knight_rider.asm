; knight_rider.asm
; Klassisk "Knight Rider"-scan: én LED bevæger sig op og ned over de 8
; LED'er. Synlig bekraeftelse paa at SLM, SRM, BRZ og JMP alle virker
; korrekt paa hardware efter IDC-fixet.
;
; Visuel cyklus:
;   UP:   0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80
;   DOWN:       0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01
;   (forfra)
;
; Test-dækning:
;   - SLM (med count=1): faktisk shift af enkelt-bit op til R8 og tilbage
;   - SRM (med count=1): tilsvarende nedad
;   - DEC + BRZ: tæl 7 skridt per fase, retning-skift naar Z=1
;   - JMP via R7: ren absolut hop (testet baade for fremad-hop og restart)
;   - ST til 0xFA: I/O til LED-portregistret
;
; Registerbrug:
;   R0 - konstant 0
;   R1 - LED-bit position (0x01..0x80)
;   R2 - hjaelp (0xFF for adresse-beregning)
;   R4 - hjaelpe-konstant 5
;   R5 - skridt-taeller (7 hver fase)
;   R6 - LED port-register adresse (0xFA)
;   R7 - jump-target (PC til up_loop / down_loop)

; SETUP
LDI D1 B1           ; PC=0:  R1 = 0x01 (start-position, bit 0)
NOT D2 A0           ; PC=1:  R2 = 0xFF
LDI D4 B5           ; PC=2:  R4 = 5
SUB D6 A2 B4        ; PC=3:  R6 = 0xFA (LED-adr)

; UP-FASE setup
LDI D5 B7           ; PC=4:  R5 = 7 (vi shifter 7 gange: 0x01 -> 0x80)
LDI D7 B6           ; PC=5:  R7 = 6 (up_loop indgang)

; UP_LOOP -- bit'en bevaeger sig fra LSB mod MSB
ST A6 B1            ; PC=6:  LED = R1
SLM D1 A1 B1        ; PC=7:  R1 <<= 1
DEC D5 A5           ; PC=8:  R5--; Z=1 hvis R5 nu er 0
BRZ D0 A0 B2        ; PC=9:  Z -> spring til PC=11 (done_up).
                    ;        offset relativt til PC=9: 9+2 = PC=11.
JMP A7              ; PC=10: hop tilbage til PC=6 (up_loop)

; DONE_UP -- vis den oeverste position (0x80) og forbered down-fase
ST A6 B1            ; PC=11: LED = R1 = 0x80 (sidste up-skridt)
LDI D5 B7           ; PC=12: R5 = 7 (down-taeller)
LDI D7 B7           ; PC=13: R7 = 7
ADI D7 A7 B7        ; PC=14: R7 = 7 + 7 = 14
ADI D7 A7 B2        ; PC=15: R7 = 14 + 2 = 16 (down_loop indgang)

; DOWN_LOOP -- bit'en bevaeger sig fra MSB mod LSB
SRM D1 A1 B1        ; PC=16: R1 >>= 1
ST A6 B1            ; PC=17: LED = R1
DEC D5 A5           ; PC=18: R5--; Z=1 hvis R5 nu er 0
BRZ D0 A0 B2        ; PC=19: Z -> spring til PC=21 (done_dn).
                    ;        offset relativt til PC=19: 19+2 = PC=21.
JMP A7              ; PC=20: hop tilbage til PC=16 (down_loop)

; DONE_DN -- restart fra PC=0; LDI D1 B1 sætter R1=1 igen
JMP A0              ; PC=21: tilbage til PC=0
