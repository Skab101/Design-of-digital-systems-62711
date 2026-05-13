; srm_led_pulse.asm
; Fyld LED'erne fra top og tøm dem igen i en evig loop, vha. SRM.
; Visuel cyklus:
;   0x80 -> 0xC0 -> 0xE0 -> 0xF0 -> 0xF8 -> 0xFC -> 0xFE -> 0xFF
;        -> 0x7F -> 0x3F -> 0x1F -> 0x0F -> 0x07 -> 0x03 -> 0x01 -> 0x00
; og forfra.
;
; ----------------------------------------------------------------------
; Historik -- hvad gik galt i srm_led_fill.asm
; ----------------------------------------------------------------------
; Første version (srm_led_fill.asm) så sådan ud:
;
;   PC=0: NOT D2 A4       ; R2 = 0xFF
;   PC=1: LDI D4 B5       ; R4 = 5
;   PC=2: SUB D6 A2 B4    ; R6 = 0xFA
;   PC=3: SRM D2 A2 B1    ; R2 >>= 1
;   PC=4: NOT D3 A2       ; R3 = NOT R2
;   PC=5: ST  A6 B3       ; LED = R3
;   PC=6: LDI D7 B4       ; <-- BUG: jump-target = PC=4
;   PC=7: JMP A7
;
; Bug 1: JMP-target var PC=4 (NOT D3 A2), dvs. EFTER SRM. Loop-kroppen
; var derfor kun NOT+ST+LDI+JMP og indeholdt slet ikke SRM. R2 blev kun
; shiftet ÉN gang under setup (0xFF -> 0x7F), så LED'en stod fast på
; NOT(0x7F) = 0x80 i al evighed. Visuelt: kun den øverste LED tændt.
;
; Med en ét-tegns-rettelse (B4 -> B3) blev SRM en del af løkken. Det gav
; en korrekt fyldning: 0x80, 0xC0, ..., 0xFE, 0xFF. Men:
;
; Bug 2: Programmet havde ingen "tilbage"-fase. Når R2 nåede 0 stoppede
; SRM med at shifte (EX0/EX1 Z-check skipper løkken), R3 fryser på 0xFF
; og LED bliver stående på 0xFF. Programmet fyldte men tømte aldrig.
;
; Bug 3 (en undgået fælde i IDC'en, ikke i selve .asm): EX1 SRM/SLM
; tjekkede ikke Z, så skift-count = 0 gik ind i shift-løkken alligevel
; og lod R9 underflowe fra 0 til 0xFF -- ~256 ekstra cykler per "tom"
; SRM. Plus EX2 manglede BX=R8, så shifteren læste forkerte register.
; Begge er rettet i PWB/sources/hdl/InstructionDecoderController.vhd og
; er en forudsætning for at dette program virker.
;
; ----------------------------------------------------------------------
; Registerbrug
; ----------------------------------------------------------------------
;   R0  - konstant 0 (ALDRIG skrives)
;   R2  - "bit-spand" der shiftes højre (start 0xFF)
;   R3  - LED-mønster (NOT R2 ved fyld, R2 ved tøm)
;   R4  - hjælpe-konstant 5
;   R6  - LED port-register adresse (0xFA)
;   R7  - jump-target (PC til fill-løkke / drain-løkke)

; SETUP
NOT D2 A0           ; PC=0:  R2 = NOT 0 = 0xFF
LDI D4 B5           ; PC=1:  R4 = 5
SUB D6 A2 B4        ; PC=2:  R6 = 0xFF - 5 = 0xFA (LED-adr)

; OUTER -- start hver pulse-cyklus her (JMP A0 fra slut hopper til PC=0
; som kører setup igen; det er idempotent)
NOT D2 A0           ; PC=3:  R2 = 0xFF (nulstil før fill)
LDI D7 B5           ; PC=4:  R7 = 5 = fill-løkkens indgang

; FILL -- LED'erne tændes fra top mod bund
SRM D2 A2 B1        ; PC=5:  R2 >>= 1; Z=1 hvis R2 nu er 0
BRZ A0 B3           ; PC=6:  Z -> hop til PC=10 (efter fill)
NOT D3 A2           ; PC=7:  R3 = NOT R2 (fill-mønster)
ST A6 B3            ; PC=8:  LED = R3
JMP A7              ; PC=9:  hop tilbage til PC=5

; EFTER FILL -- vis det sidste skridt (0xFF) og forbered drain
NOT D3 A0           ; PC=10: R3 = NOT 0 = 0xFF
ST A6 B3            ; PC=11: LED = 0xFF
NOT D2 A0           ; PC=12: R2 = 0xFF (nulstil før drain)
LDI D7 B7           ; PC=13: R7 = 7
ADI D7 A7 B7        ; PC=14: R7 = 7 + 7 = 14
ADI D7 A7 B2        ; PC=15: R7 = 14 + 2 = 16 = drain-løkkens indgang

; DRAIN -- LED'erne slukkes fra top mod bund
SRM D2 A2 B1        ; PC=16: R2 >>= 1
BRZ A0 B2           ; PC=17: Z -> hop til PC=20 (efter drain)
ST A6 B2            ; PC=18: LED = R2
JMP A7              ; PC=19: hop tilbage til PC=16

; EFTER DRAIN -- vis sidste skridt (0x00) og start forfra
LDI D3 B0           ; PC=20: R3 = 0
ST A6 B3            ; PC=21: LED = 0x00
JMP A0              ; PC=22: hop til PC=0 (start forfra)
