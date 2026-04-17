#!/usr/bin/env python3
"""
dsdasm — streamlined assembler/disassembler/simulator for the DSD 62711 PWF microprocessor.

Targets the Nexys 4 DDR implementation:
  - 16-bit instructions, 8 general registers R0..R7
  - 3-bit immediates and 3-bit signed offsets
  - 256x16 BRAM, upper 8 addresses (0xF8-0xFF) memory-mapped I/O

Usage:
    dsdasm asm prog.asm -o prog.hex              # emit hex (one word per line)
    dsdasm asm prog.asm --vhdl Ram256x16.vhd     # inject INIT_xx into RAM module
    dsdasm asm prog.asm --bram prog.bram         # packed BRAM format (64-char lines)
    dsdasm dasm prog.hex                         # disassemble
    dsdasm run prog.asm [--trace] [--switches 0xA5] [--press BTNR]
    dsdasm test                                  # self-test vs slide 9 reference
"""

import argparse
import re
import sys
from pathlib import Path
from typing import NamedTuple

# =============================================================================
# ISA — single source of truth
# =============================================================================

class OpInfo(NamedTuple):
    opcode: int          # 7-bit opcode
    operands: tuple      # ((slot, kind), ...)
    # slot ∈ {'D','A','B'}  → IR876, IR543, IR210
    # kind ∈ {'reg','imm','off'}

ISA = {
    'MOVA': OpInfo(0b0000000, (('D','reg'), ('A','reg'))),
    'INC':  OpInfo(0b0000001, (('D','reg'), ('A','reg'))),
    'ADD':  OpInfo(0b0000010, (('D','reg'), ('A','reg'), ('B','reg'))),
    'SUB':  OpInfo(0b0000101, (('D','reg'), ('A','reg'), ('B','reg'))),
    'DEC':  OpInfo(0b0000110, (('D','reg'), ('A','reg'))),
    # AND/OR opcodes match the PWF project spec table AND our PWB
    # InstructionDecoderController (opcode 0001000 = OR, 0001001 = AND).
    # NOTE: This is the OPPOSITE of the lecture-10 slide-9 reference and what
    # the Java assembler tool produces. Slide 9 is wrong for this hardware:
    # running `and` code assembled by the Java tool would actually execute OR.
    'OR':   OpInfo(0b0001000, (('D','reg'), ('A','reg'), ('B','reg'))),
    'AND':  OpInfo(0b0001001, (('D','reg'), ('A','reg'), ('B','reg'))),
    'XOR':  OpInfo(0b0001010, (('D','reg'), ('A','reg'), ('B','reg'))),
    'NOT':  OpInfo(0b0001011, (('D','reg'), ('A','reg'))),
    'MOVB': OpInfo(0b0001100, (('D','reg'), ('B','reg'))),
    'LD':   OpInfo(0b0010000, (('D','reg'), ('A','reg'))),
    'ST':   OpInfo(0b0100000, (('A','reg'), ('B','reg'))),
    'LDI':  OpInfo(0b1001100, (('D','reg'), ('B','imm'))),
    'ADI':  OpInfo(0b1000010, (('D','reg'), ('A','reg'), ('B','imm'))),
    'BRZ':  OpInfo(0b1100000, (('A','reg'), ('B','off'))),
    'BRN':  OpInfo(0b1100001, (('A','reg'), ('B','off'))),
    'JMP':  OpInfo(0b1110000, (('A','reg'),)),
    'LRI':  OpInfo(0b0010001, (('D','reg'), ('A','reg'))),
    'SRM':  OpInfo(0b0001101, (('A','reg'),)),
    'SLM':  OpInfo(0b0001110, (('A','reg'),)),
}

SLOT_SHIFT = {'D': 6, 'A': 3, 'B': 0}
OPCODE_SHIFT = 9
OPCODE_TO_INSN = {info.opcode: (name, info) for name, info in ISA.items()}

# =============================================================================
# Lexing / parsing helpers
# =============================================================================

REG_RE = re.compile(r'^[Rr](\d+)$')
LABEL_RE = re.compile(r'^[A-Za-z_]\w*$')

class AsmError(Exception):
    def __init__(self, line_num, line_text, msg):
        self.line_num = line_num
        self.line_text = line_text.rstrip()
        self.msg = msg
        super().__init__(f"line {line_num}: {msg}\n    | {self.line_text}")

def parse_reg(tok):
    m = REG_RE.match(tok)
    if not m:
        raise ValueError(f"expected register (R0-R7), got '{tok}'")
    n = int(m.group(1))
    if not 0 <= n <= 7:
        raise ValueError(f"register out of range: R{n} (valid: R0-R7)")
    return n

def parse_int(tok):
    tok = tok.strip()
    if not tok:
        raise ValueError("empty integer literal")
    negative = False
    if tok.startswith('-'):
        negative = True
        tok = tok[1:]
    try:
        if tok.startswith(('0x', '0X')):
            val = int(tok, 16)
        elif tok.startswith(('0b', '0B')):
            val = int(tok, 2)
        else:
            val = int(tok, 10)
    except ValueError:
        raise ValueError(f"invalid integer literal: '{tok}'")
    return -val if negative else val

def tokenize_line(line):
    """Strip comments (; or #), replace commas with spaces, return tokens."""
    # Find earliest comment marker
    cut = len(line)
    for marker in (';', '#'):
        idx = line.find(marker)
        if idx >= 0 and idx < cut:
            cut = idx
    line = line[:cut].replace(',', ' ')
    return line.split()

# =============================================================================
# Encoder
# =============================================================================

def encode_insn(mnemonic, vals):
    info = ISA[mnemonic]
    word = info.opcode << OPCODE_SHIFT
    for (slot, kind), val in zip(info.operands, vals):
        if kind == 'reg':
            if not 0 <= val <= 7:
                raise ValueError(f"register out of range: R{val}")
        elif kind == 'imm':
            if not 0 <= val <= 7:
                raise ValueError(f"immediate out of range: {val} (valid 0..7)")
        elif kind == 'off':
            if not -4 <= val <= 3:
                raise ValueError(f"offset out of range: {val} (valid -4..+3)")
            val = val & 0b111
        word |= (val & 0b111) << SLOT_SHIFT[slot]
    return word

# =============================================================================
# Assembler — two-pass with labels + .word directive
# =============================================================================

def assemble(source, filename="<input>"):
    """
    Two-pass assembler.

    Returns (words, labels).
    Supports:
      - Labels:      ``foo:`` anywhere
      - Comments:    ``;`` or ``#``
      - Directives:  ``.word <int>`` places a raw 16-bit value
      - Immediates:  decimal, ``0x..``, ``0b..``; labels also accepted (resolved to address)
      - Branch offs: integer offset OR label (offset auto-computed)
    """
    lines = source.splitlines()
    items = []      # (line_num, raw_line, kind, payload, addr)
                    #   kind ∈ {'insn','word'}
                    #   insn payload = (mnemonic, raw_args)
                    #   word payload = raw_int_token
    labels = {}
    pc = 0

    # ---- Pass 1: tokenize, collect labels, compute addresses ----
    for line_num, raw_line in enumerate(lines, 1):
        toks = tokenize_line(raw_line)
        # Handle leading labels (possibly multiple)
        while toks and toks[0].endswith(':'):
            label = toks[0][:-1]
            if not LABEL_RE.match(label):
                raise AsmError(line_num, raw_line, f"invalid label name: '{label}'")
            if label.upper() in ISA:
                raise AsmError(line_num, raw_line,
                               f"label shadows instruction: '{label}'")
            if label in labels:
                raise AsmError(line_num, raw_line,
                               f"duplicate label: '{label}' (first at addr 0x{labels[label]:02X})")
            labels[label] = pc
            toks = toks[1:]
        if not toks:
            continue

        head = toks[0]
        if head.lower() == '.word':
            if len(toks) != 2:
                raise AsmError(line_num, raw_line,
                               ".word expects exactly one operand")
            items.append((line_num, raw_line, 'word', toks[1], pc))
            pc += 1
        else:
            mn = head.upper()
            if mn not in ISA:
                raise AsmError(line_num, raw_line, f"unknown instruction: '{head}'")
            items.append((line_num, raw_line, 'insn', (mn, toks[1:]), pc))
            pc += 1

        if pc > 256:
            raise AsmError(line_num, raw_line,
                           "program exceeds 256 words (BRAM capacity)")

    # ---- Pass 2: resolve and encode ----
    words = []
    for line_num, raw_line, kind, payload, addr in items:
        if kind == 'word':
            raw = payload
            try:
                val = labels[raw] if raw in labels else parse_int(raw)
            except ValueError as e:
                raise AsmError(line_num, raw_line, str(e))
            if not 0 <= val <= 0xFFFF:
                raise AsmError(line_num, raw_line,
                               f".word value out of range: {val} (valid 0..0xFFFF)")
            words.append(val)
            continue

        mn, raw_args = payload
        info = ISA[mn]
        if len(raw_args) != len(info.operands):
            exp = ", ".join(f"{s}:{k}" for s,k in info.operands)
            raise AsmError(line_num, raw_line,
                           f"{mn} expects {len(info.operands)} operand(s) [{exp}], "
                           f"got {len(raw_args)}: {raw_args}")
        vals = []
        for (slot, kind2), raw in zip(info.operands, raw_args):
            try:
                if kind2 == 'reg':
                    vals.append(parse_reg(raw))
                elif kind2 == 'imm':
                    if raw in labels:
                        vals.append(labels[raw])
                    else:
                        vals.append(parse_int(raw))
                elif kind2 == 'off':
                    if raw in labels:
                        vals.append(labels[raw] - (addr + 1))
                    else:
                        vals.append(parse_int(raw))
            except ValueError as e:
                raise AsmError(line_num, raw_line, str(e))
        try:
            words.append(encode_insn(mn, vals))
        except ValueError as e:
            raise AsmError(line_num, raw_line, str(e))

    return words, labels

# =============================================================================
# Disassembler
# =============================================================================

def decode_insn(word):
    opcode = (word >> OPCODE_SHIFT) & 0b1111111
    entry = OPCODE_TO_INSN.get(opcode)
    if entry is None:
        return None
    name, info = entry
    parts = []
    for slot, kind in info.operands:
        val = (word >> SLOT_SHIFT[slot]) & 0b111
        if kind == 'reg':
            parts.append(f"R{val}")
        elif kind == 'imm':
            parts.append(str(val))
        elif kind == 'off':
            if val & 0b100:
                val -= 8
            parts.append(f"{val:+d}")
    return name.lower(), parts

def disassemble(words):
    out = []
    for addr, w in enumerate(words):
        dec = decode_insn(w)
        if dec is None:
            out.append(f"{addr:02X}:  0x{w:04X}  .word 0x{w:04X}     ; unknown opcode")
        else:
            name, operands = dec
            op_str = ", ".join(operands)
            out.append(f"{addr:02X}:  0x{w:04X}  {name:<5}{(' ' + op_str) if op_str else ''}")
    return "\n".join(out)

# =============================================================================
# Output formatting
# =============================================================================

def hex_flat(words):
    """One 4-char hex word per line."""
    return "\n".join(f"{w:04X}" for w in words) + "\n"

def hex_bram_packed(words, line_words=16):
    """BRAM-packed: each line = line_words words, packed MSB=highest address first."""
    lines = []
    for i in range(0, len(words), line_words):
        chunk = words[i:i+line_words]
        packed = "".join(f"{w:04X}" for w in reversed(chunk))
        # Right-align to 64 chars (pad left with zeros)
        packed = packed.rjust(line_words * 4, '0')
        lines.append(packed)
    return "\n".join(lines) + "\n"

def format_init_lines(words, num_lines=16):
    """Format INIT_00..INIT_xx => X\"...\", lines for the BRAM generic map."""
    out = []
    for idx in range(num_lines):
        chunk = words[idx*16 : (idx+1)*16]
        packed = "".join(f"{w:04X}" for w in reversed(chunk))
        packed = packed.rjust(64, '0')
        out.append(f'INIT_{idx:02X} => X"{packed}"')
    return out

# =============================================================================
# VHDL patching — inject INIT_xx into Ram256x16.vhd
# =============================================================================

MARKER_BEGIN = "-- PROGRAM_INIT_BEGIN (managed by dsdasm.py -- do not edit by hand)"
MARKER_END   = "-- PROGRAM_INIT_END"

def patch_vhdl(vhdl_path, words):
    """Idempotently inject INIT_xx generics into the BRAM instantiation."""
    path = Path(vhdl_path)
    src = path.read_text()

    init_lines = format_init_lines(words)
    body = "\n        ".join([line + "," for line in init_lines])
    block = f"{MARKER_BEGIN}\n        {body}\n        {MARKER_END}"

    if MARKER_BEGIN in src and MARKER_END in src:
        pattern = re.compile(
            re.escape(MARKER_BEGIN) + r".*?" + re.escape(MARKER_END),
            re.DOTALL,
        )
        new_src = pattern.sub(block, src)
    else:
        # Insert just after the existing `INIT => X"...",` line (allow trailing comment)
        m = re.search(r'(INIT\s*=>\s*X"[0-9A-Fa-f]+",[^\n]*\n)', src)
        if not m:
            raise ValueError(
                f"could not find 'INIT => X\"...\",' in {vhdl_path}; add markers "
                f"{MARKER_BEGIN!r} / {MARKER_END!r} manually first"
            )
        indent_match = re.match(r'\s*', src[src.rfind('\n', 0, m.start()) + 1:])
        indent = indent_match.group(0) if indent_match else "        "
        new_src = src[:m.end()] + indent + block + "\n" + src[m.end():]

    path.write_text(new_src)

# =============================================================================
# Simulator
# =============================================================================

class CPU:
    """Cycle-simplified emulator (not cycle-accurate; single-step per instruction)."""

    MEM_SIZE = 256
    IO_BASE  = 0xF8      # MR0..MR7 live at 0xF8..0xFF

    def __init__(self, program):
        self.R  = [0]*10  # R0..R7 general; R8/R9 used by LRI/SRM/SLM
        self.PC = 0
        self.V = self.C = self.N = self.Z = 0
        self.mem = [0]*self.MEM_SIZE
        for i, w in enumerate(program):
            self.mem[i] = w & 0xFFFF
        self.MR = [0]*8
        self.sw = 0
        self.halted = False
        self.history = []  # list of (pc, ir, state_str) if trace enabled

    def set_switches(self, val): self.sw = val & 0xFF

    def press_button(self, name):
        """Latch switches into the port register mapped to this button."""
        mapping = {'BTNR': 3, 'BTNL': 4, 'BTND': 5, 'BTNU': 6, 'BTNC': 7}
        if name not in mapping:
            raise ValueError(f"unknown button: {name} (valid: {list(mapping)})")
        self.MR[mapping[name]] = self.sw

    def read_mem(self, addr):
        addr &= 0xFF
        if addr >= self.IO_BASE:
            return self.MR[addr - self.IO_BASE] & 0xFF
        return self.mem[addr] & 0xFFFF

    def write_mem(self, addr, val):
        addr &= 0xFF
        val  &= 0xFFFF
        if addr == 0xF8:   self.MR[0] = val & 0xFF     # D_Word low
        elif addr == 0xF9: self.MR[1] = val & 0xFF     # D_Word high
        elif addr == 0xFA: self.MR[2] = val & 0xFF     # LEDs
        elif addr >= self.IO_BASE:
            pass  # MR3..MR7 read-only from CPU side
        else:
            self.mem[addr] = val

    def _flags(self, result, carry=0, overflow=0):
        r8 = result & 0xFF
        self.Z = int(r8 == 0)
        self.N = int((r8 >> 7) & 1)
        self.C = carry
        self.V = overflow

    def step(self):
        if self.halted:
            return False
        pc = self.PC
        ir = self.mem[pc]
        opcode = (ir >> OPCODE_SHIFT) & 0b1111111
        DR = (ir >> SLOT_SHIFT['D']) & 0b111
        SA = (ir >> SLOT_SHIFT['A']) & 0b111
        SB = (ir >> SLOT_SHIFT['B']) & 0b111

        entry = OPCODE_TO_INSN.get(opcode)
        if entry is None:
            raise RuntimeError(
                f"unknown opcode 0b{opcode:07b} (word 0x{ir:04X}) at PC=0x{pc:02X}"
            )
        name, _ = entry
        A = self.R[SA] & 0xFF
        B = self.R[SB] & 0xFF
        off = SB - 8 if (SB & 0b100) else SB
        imm = SB  # zero-filled 3-bit immediate

        next_pc = (pc + 1) & 0xFF

        if name == 'MOVA':
            self.R[DR] = A; self._flags(A)
        elif name == 'INC':
            r = (A + 1) & 0xFF
            self.R[DR] = r; self._flags(r, carry=int(A == 0xFF))
        elif name == 'ADD':
            s = A + B
            r = s & 0xFF
            ov = int(((A ^ r) & (B ^ r) & 0x80) != 0)
            self.R[DR] = r; self._flags(r, carry=int(s > 0xFF), overflow=ov)
        elif name == 'SUB':
            r = (A - B) & 0xFF
            ov = int(((A ^ B) & (A ^ r) & 0x80) != 0)
            self.R[DR] = r; self._flags(r, carry=int(A >= B), overflow=ov)
        elif name == 'DEC':
            r = (A - 1) & 0xFF
            self.R[DR] = r; self._flags(r)
        elif name == 'OR':
            r = A | B; self.R[DR] = r; self._flags(r)
        elif name == 'AND':
            r = A & B; self.R[DR] = r; self._flags(r)
        elif name == 'XOR':
            r = A ^ B; self.R[DR] = r; self._flags(r)
        elif name == 'NOT':
            r = (~A) & 0xFF; self.R[DR] = r; self._flags(r)
        elif name == 'MOVB':
            self.R[DR] = B; self._flags(B)
        elif name == 'LD':
            v = self.read_mem(A) & 0xFF
            self.R[DR] = v; self._flags(v)
        elif name == 'ST':
            self.write_mem(A, B)
        elif name == 'LDI':
            self.R[DR] = imm; self._flags(imm)
        elif name == 'ADI':
            s = A + imm
            r = s & 0xFF
            self.R[DR] = r; self._flags(r, carry=int(s > 0xFF))
        elif name == 'BRZ':
            if self.Z: next_pc = (next_pc + off) & 0xFF
        elif name == 'BRN':
            if self.N: next_pc = (next_pc + off) & 0xFF
        elif name == 'JMP':
            target = A
            if target == pc:        # jmp-to-self ⇒ halt
                self.halted = True
                return False
            next_pc = target
        elif name == 'LRI':
            self.R[8] = self.read_mem(A) & 0xFF
            self.R[DR] = self.read_mem(self.R[8]) & 0xFF
        elif name == 'SRM':
            shift = self.R[9] & 0b111
            r = (A >> shift) & 0xFF
            self.R[SA] = r; self._flags(r)
        elif name == 'SLM':
            shift = self.R[9] & 0b111
            r = (A << shift) & 0xFF
            self.R[SA] = r; self._flags(r)
        else:
            raise RuntimeError(f"simulator missing case for {name}")

        self.PC = next_pc
        return True

    def state_str(self):
        regs = " ".join(f"R{i}={self.R[i]:3d}" for i in range(8))
        return (f"PC=0x{self.PC:02X}  {regs}  "
                f"V={self.V} C={self.C} N={self.N} Z={self.Z}")

    def run(self, max_steps=10000, trace=False):
        steps = 0
        while steps < max_steps and not self.halted:
            pc_before = self.PC
            ir = self.mem[pc_before]
            if not self.step():
                break
            if trace:
                dec = decode_insn(ir)
                mn = dec[0] if dec else "????"
                print(f"  [{steps:04d}] {pc_before:02X}: 0x{ir:04X} {mn:<5}"
                      f" -> {self.state_str()}")
            steps += 1
        return steps

# =============================================================================
# CLI
# =============================================================================

def cmd_asm(args):
    src = Path(args.source).read_text()
    words, labels = assemble(src, args.source)

    did_something = False
    if args.output:
        Path(args.output).write_text(hex_flat(words))
        print(f"wrote {len(words)} words -> {args.output}", file=sys.stderr)
        did_something = True
    if args.bram:
        Path(args.bram).write_text(hex_bram_packed(words))
        print(f"wrote BRAM-packed hex -> {args.bram}", file=sys.stderr)
        did_something = True
    if args.vhdl:
        patch_vhdl(args.vhdl, words)
        print(f"patched INIT_xx generics -> {args.vhdl}", file=sys.stderr)
        did_something = True
    if not did_something:
        sys.stdout.write(hex_flat(words))

    if args.labels:
        print("\nLabels:", file=sys.stderr)
        for name, addr in sorted(labels.items(), key=lambda kv: kv[1]):
            print(f"  {name} = 0x{addr:02X}", file=sys.stderr)
    return 0

def cmd_dasm(args):
    src = Path(args.source).read_text()
    words = [int(m.group(), 16) for m in re.finditer(r'[0-9A-Fa-f]{4}', src)]
    if not words:
        print("no 4-char hex words found", file=sys.stderr)
        return 1
    print(disassemble(words))
    return 0

def cmd_run(args):
    src = Path(args.source).read_text()
    words, _ = assemble(src, args.source)
    cpu = CPU(words)
    if args.switches is not None:
        cpu.set_switches(parse_int(args.switches))
    for btn in (args.press or []):
        cpu.press_button(btn.upper())

    steps = cpu.run(max_steps=args.max_steps, trace=args.trace)
    print("-" * 60)
    print(f"halted={cpu.halted}  steps={steps}")
    print(cpu.state_str())
    mr_str = "  ".join(f"MR{i}=0x{v:02X}" for i, v in enumerate(cpu.MR))
    print(mr_str)
    print(f"LEDs (MR2)  : 0x{cpu.MR[2]:02X} = 0b{cpu.MR[2]:08b}")
    print(f"7-seg D_Word: 0x{(cpu.MR[1] << 8) | cpu.MR[0]:04X}")
    return 0

# Reference encoding per the PWF project spec table (authoritative for this
# hardware / our PWB InstructionDecoderController). Note that slide-9 in the
# lecture-10 deck has AND and OR swapped vs this table.
PWF_REFERENCE = [
    ("mova R0 R1",      0x0008),
    ("inc  R0 R1",      0x0208),
    ("add  R0 R1 R2",   0x040A),
    ("sub  R0 R1 R2",   0x0A0A),
    ("dec  R0 R1",      0x0C08),
    ("or   R0 R1 R2",   0x100A),   # opcode 0001000 per PWF spec
    ("and  R0 R1 R2",   0x120A),   # opcode 0001001 per PWF spec
    ("xor  R0 R1 R2",   0x140A),
    ("not  R0 R1",      0x1608),
    ("movb R0 R1",      0x1801),
    ("ld   R0 R1",      0x2008),
    ("st   R0 R1",      0x4001),
    ("ldi  R0, 0",      0x9800),
    ("adi  R0 R1, 0",   0x8408),
    ("brz  R0, 0",      0xC000),
    ("brn  R0, 0",      0xC200),
    ("jmp  R0",         0xE000),
    ("lri  R0 R0",      0x2200),
    ("srm  R0",         0x1A00),
    ("slm  R0",         0x1C00),
]

def cmd_test(args):
    src = "\n".join(line for line, _ in PWF_REFERENCE)
    expected = [w for _, w in PWF_REFERENCE]
    try:
        words, _ = assemble(src)
    except AsmError as e:
        print(f"FAIL (assemble error): {e}", file=sys.stderr)
        return 1

    fails = 0
    for i, (line, want) in enumerate(PWF_REFERENCE):
        got = words[i] if i < len(words) else None
        mark = "OK " if got == want else "!! "
        if got != want: fails += 1
        print(f"  {mark}[{i:02d}] 0x{(got or 0):04X} (want 0x{want:04X})  {line}")
    print()
    if fails == 0:
        print(f"PASS: all {len(expected)} instructions match PWF spec.")
        return 0
    print(f"FAIL: {fails}/{len(expected)} mismatches.")
    return 1

def main():
    p = argparse.ArgumentParser(
        prog="dsdasm",
        description="Streamlined assembler for DSD 62711 PWF microprocessor.",
    )
    sub = p.add_subparsers(dest="cmd", required=True)

    a = sub.add_parser("asm", help="assemble .asm → hex / BRAM / VHDL")
    a.add_argument("source")
    a.add_argument("-o", "--output", help="write flat hex (one word per line)")
    a.add_argument("--bram", help="write BRAM-packed 64-char hex lines")
    a.add_argument("--vhdl", help="inject INIT_xx generics into Ram256x16.vhd")
    a.add_argument("--labels", action="store_true", help="print symbol table")
    a.set_defaults(func=cmd_asm)

    d = sub.add_parser("dasm", help="disassemble hex → asm")
    d.add_argument("source")
    d.set_defaults(func=cmd_dasm)

    r = sub.add_parser("run", help="simulate the program")
    r.add_argument("source")
    r.add_argument("--trace", action="store_true", help="print state after each step")
    r.add_argument("--switches", help="initial SW value, e.g. 0xA5")
    r.add_argument("--press", action="append",
                   help="simulate a button press (BTNR/BTNL/BTND/BTNU/BTNC); repeatable")
    r.add_argument("--max-steps", type=int, default=10000)
    r.set_defaults(func=cmd_run)

    t = sub.add_parser("test", help="self-test vs slide-9 reference")
    t.set_defaults(func=cmd_test)

    args = p.parse_args()
    try:
        rc = args.func(args)
        sys.exit(rc or 0)
    except AsmError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except (ValueError, RuntimeError, FileNotFoundError) as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
