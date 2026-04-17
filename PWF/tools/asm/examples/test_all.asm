; test_all.asm — every ISA instruction once.
; Encoding matches the PWF project spec table (which is what our PWB
; InstructionDecoderController decodes). Slide 9 in the lecture deck has
; AND and OR swapped vs this — slide 9 is wrong for our hardware.
; `dsdasm test` validates this binary-exactly against the PWF spec.

mova R0 R1          ; 0x0008
inc  R0 R1          ; 0x0208
add  R0 R1 R2       ; 0x040A
sub  R0 R1 R2       ; 0x0A0A
dec  R0 R1          ; 0x0C08
or   R0 R1 R2       ; 0x100A   (opcode 0001000 per PWF spec)
and  R0 R1 R2       ; 0x120A   (opcode 0001001 per PWF spec)
xor  R0 R1 R2       ; 0x140A
not  R0 R1          ; 0x1608
movb R0 R1          ; 0x1801
ld   R0 R1          ; 0x2008
st   R0 R1          ; 0x4001
ldi  R0, 0          ; 0x9800
adi  R0 R1, 0       ; 0x8408
brz  R0, 0          ; 0xC000
brn  R0, 0          ; 0xC200
jmp  R0             ; 0xE000
lri  R0 R0          ; 0x2200
srm  R0             ; 0x1A00
slm  R0             ; 0x1C00
