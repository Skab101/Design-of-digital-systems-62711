; srm_led_fill.asm
; -----------------------------------------------------------
; SRM-loop demo: fill the 8 LEDs (MR2 at 0xFA) progressively
; from LSB to MSB by repeatedly shifting R2 right and writing
; NOT R2 to the LED port.
;
; Iteration pattern:
;   R2 = 0xFF, 0x7F, 0x3F, 0x1F, 0x0F, 0x07, 0x03, 0x01, 0x00
;   ~R2 = 0x00, 0x80, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC, 0xFE, 0xFF
;
; After the 9 ST writes MR2 ends at 0xFF (all LEDs on), then
; JMP A7 (R7=1) loops back to address 1, restarting the LDI/SUB
; setup and the SRM cycle.
;
; Demonstrates the new SRM 3-operand encoding (D, A, B-imm).
; R0 is used as the scratch for ~R2 (originally D8/B8 in the
; sketch — registers are only 3 bits, so D8/B8 isn't valid).

NOT D2 A4         ; R2 = ~R4 = 0xFF
LDI D4 B5         ; R4 = 5
SUB D6 A2 B4      ; R6 = 0xFF - 5 = 0xFA  (= MR2 / LEDs address)
SRM D2 A2 B1      ; R2 = R2 >> 1
NOT D0 A2         ; R0 = ~R2
ST  A6 B0         ; M[R6] = R0    -> writes to LEDs
SRM D2 A2 B1
NOT D0 A2
ST  A6 B0
SRM D2 A2 B1
NOT D0 A2
ST  A6 B0
SRM D2 A2 B1
NOT D0 A2
ST  A6 B0
SRM D2 A2 B1
NOT D0 A2
ST  A6 B0
SRM D2 A2 B1
NOT D0 A2
ST  A6 B0
SRM D2 A2 B1
NOT D0 A2
ST  A6 B0
SRM D2 A2 B1
NOT D0 A2
ST  A6 B0
LDI D7 B1         ; R7 = 1
JMP A7            ; loop back to address 1 (LDI D4 B5)
