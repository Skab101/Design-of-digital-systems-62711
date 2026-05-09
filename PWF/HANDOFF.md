# PWF Microprocessor — Handoff

**Branch:** `feature/divclk-cpu`
**Last verified working on board:** 2026-05-09
**Repo:** `C:\Users\Mads2\DTU\4. Semester\Digital Systems Design\team`

---

## TL;DR for the next session

1. **What works on the FPGA right now:** `sw_to_led.asm` (DEC-based variant, currently in BRAM). Set switches, press BTNR, LEDs mirror SW.
2. **The big open mystery:** the Cin fix was committed in `Microprocessor.vhd` (`Cin => FS_sig(0)` instead of `'0'`), but the on-board behavior shows the bitstream still acts like `Cin = '0'`. We worked around it by writing the program with DEC (which is Cin-agnostic) instead of SUB. **Top-priority next task: figure out why the Cin fix isn't landing in the synthesized bitstream.** See "The Cin investigation" section below.
3. **Sim works:** `Microprocessor_tb.vhd` runs in xsim and all assertions pass.

---

## Current state

The program in BRAM (`Ram256x16.vhd` INIT_00) is the DEC-based `sw_to_led.asm`:

```
NOT R2 R0         ; R2 = 0xFF
DEC R3 R2         ; R3 = 0xFE         <-- loop entry (PC=1)
DEC R3 R3         ; R3 = 0xFD
DEC R3 R3         ; R3 = 0xFC
DEC R3 R3         ; R3 = 0xFB (MR3 = BTNR latch)
LD  R6 R3         ; R6 = MR3
DEC R3 R3         ; R3 = 0xFA (MR2 = LED)
ST  R3 R6         ; LED <- R6
LDI R7 1
JMP R7            ; loop back to PC=1
```

This works because every operation that touches the adder either:
- Doesn't depend on Cin (DEC: FS0=0 so Cin=0 in both source variants, A + 0xFF + 0 = A - 1)
- Bypasses the adder entirely (NOT, LDI: FS3=1 routes through logic mux instead)

The "real" SUB-based version is preserved in commented-out form at the bottom of `sw_to_led.asm`. It will work *as soon as the bitstream actually contains the Cin fix* — no asm changes needed, just patch BRAM with that version and rebuild.

---

## The Cin investigation (priority debug task)

### Background

Originally `Microprocessor.vhd` had `Cin => '0'` hardcoded in the Datapath port map, which broke `SUB`/`INC`/`ADC` (all need Cin=1 since their FS encoding has FS0=1). Commit `778e271` changed it to `Cin => FS_sig(0)` — this should make all arithmetic ops work because FS is set per-instruction by the IDC.

We verified by inspection that the Cin path is intact end-to-end:

| File | Line | Connection |
|---|---|---|
| `PWF/sources/hdl/Microprocessor.vhd` | 102 | `Cin => FS_sig(0)` ✓ |
| `PWA/PWA.srcs/sources_1/new/Datapath.vhd` | 98 | `Cin => Cin` (port-through) ✓ |
| `PWA/PWA.srcs/sources_1/new/FunctionUnit.vhd` | 33 | `Cin => Cin` (port-through to ALU) ✓ |
| `PWA/PWA.srcs/sources_1/new/ALU.vhd` | 24 | `Cin => Cin` (port-through to adder) ✓ |
| `PWA/PWA.srcs/sources_1/new/full_adder_8_bit.vhd` | 30 | `carry(0) <= Cin` (final use) ✓ |

The IDC sets `FS = "0101"` for SUB (FS0=1) and `FS = "0001"` for INC (FS0=1), so with the fix `Cin = 1` for both.

dsdasm (which models the spec correctly) confirms the SUB-based program works there.

### What we observed

When we put the SUB-based `sw_to_led.asm` into BRAM and tried to run it on the board:
- LED stays dark on BTNR press
- Behavior matches what would happen with `Cin = '0'` (SUB computes A-B-1, address calculations go to the wrong I/O register)

We tried everything to force a clean rebuild — Reset Run on synth_1 + impl_1, Generate Bitstream from scratch, even checked the synth log which says it does a "full resynthesis" of `Microprocessor.vhd`. The `.bit` file has a fresh timestamp. But the on-board behavior persists as if Cin is still 0.

### What to investigate next

1. **Open the synthesized design and inspect Cin**:
   - In Vivado: after Generate Bitstream completes, click **Open Synthesized Design**
   - Schematic view: navigate `TOP_MODUL_F → CPU_inst → DP_inst → FU → U_ALU → full_adder`
   - Find the `Cin` input on the adder. Trace where it comes from.
   - If it's tied to GND (logic 0), the fix isn't in the bitstream.
   - If it traces back to `FS_sig[0]` from the MPC, the fix IS in the bitstream and the on-board failure must be something else (timing? programming issue?).

2. **Try a totally clean rebuild from scratch**:
   - Close Vivado entirely
   - Delete `PWF/PWF.runs/`, `PWF/PWF.cache/`, `PWF/PWF.hw/` if present
   - Reopen `.xpr`, Generate Bitstream
   - Sometimes Vivado caches IP/netlist data even when Reset Run looks like it's doing a clean rebuild

3. **Verify `.bit` file is fresh and being uploaded correctly**:
   - In File Explorer, check `PWF/PWF.runs/impl_1/TOP_MODUL_F.bit` modified time matches your last build
   - In Hardware Manager → Program Device dialog, verify the Bitstream file path points to the freshly built `.bit`

4. **Write a tiny INC-test program**:
   - `LDI R0 5; INC R1 R0; ST <LED>, R1` — should make LED show 0x06.
   - With Cin=1: works → fix is in bitstream
   - With Cin=0: INC is no-op, R1 stays 0, LED shows 0
   - This isolates the Cin path from any other complexity.

5. **Check for stale `.dcp` / netlist files** in `PWF/PWF.srcs/utils_1/imports/`. These are reference checkpoints used for incremental synthesis and can carry old netlist data.

### Once you confirm Cin is correct in bitstream

Replace the BRAM patch with the SUB-based variant (commented at the bottom of `sw_to_led.asm`):

```bash
# extract the SUB-based version from the comments, save it to a file, then:
python PWF/tools/asm/dsdasm.py asm <sub-version>.asm --vhdl PWF/sources/hdl/Ram256x16.vhd
```

The SUB version is shorter (9 instructions vs 10) and is the "intended" idiom.

---

## Architecture summary

```
TOP_MODUL_F.vhd              -- board-level wrapper
├── DivClk.vhd                -- CLK -> CLK_CPU = CLK/2 (50 MHz CPU clock)
├── BUFG_CPU                  -- routes CLK_CPU on global clock network
├── Microprocessor.vhd        -- CPU core
│   ├── Datapath  (PWA)       -- on CLK_CPU
│   ├── MicroprogramCtrl (PWB) -- on CLK_CPU
│   ├── PortReg8x8            -- on CLK_CPU (memory-mapped I/O at 0xF8..0xFF)
│   ├── Ram256x16             -- on CLK (full speed), FALLING edge
│   └── MUX_MR + MUX_M        -- combinational
└── SevenSegDriver            -- on CLK (full speed)
```

Two clock domains:
- **CLK** (100 MHz, board pin E3) → BRAM, SevenSegDriver
- **CLK_CPU** (50 MHz, derived from CLK via DivClk + BUFG) → Datapath, MPC, PortReg

The BRAM is clocked on the **falling edge** of CLK so its synchronous read latency lines up with the IR latch on the next CLK_CPU rising edge (the IDC asserts MM=1 and IL=1 in the same INF cycle, assuming ~0-cycle memory read).

---

## File map

```
PWF/
├── HANDOFF.md                              <- this file
├── Nexys_4_DDR_Master.xdc                  <- DO NOT MODIFY (pin constraints)
├── PWF.xpr                                 <- Vivado project
├── Microprocessor_tb_behav.wcfg            <- xsim wave config
├── PortReg8x8_tb_behav.wcfg
├── sources/
│   ├── hdl/
│   │   ├── DivClk.vhd                      <- CLK divider (TimeP=1 -> CLK/2)
│   │   ├── TOP_MODUL_F.vhd                 <- board wrapper, instantiates DivClk + BUFG
│   │   ├── Microprocessor.vhd              <- CPU core (Cin = FS_sig(0))
│   │   ├── Ram256x16.vhd                   <- BRAM, falling-edge, INIT holds program
│   │   ├── PortReg8x8.vhd                  <- memory-mapped I/O
│   │   ├── SevenSegDriver.vhd              <- 4-digit hex display driver
│   │   ├── MUX_MR.vhd, MUX2x1.vhd, ...     <- combinational helpers
│   │   └── flip_flop.vhd, 8bit_Register.vhd <- generic flops
│   └── tb/
│       └── Microprocessor_tb.vhd            <- top-level testbench, 5 tests
└── tools/
    └── asm/
        ├── dsdasm.py                        <- assembler/disassembler/simulator
        ├── dsdasm_gui.py
        └── examples/
            └── sw_to_led.asm                <- ONLY example program (DEC-based,
                                                SUB-version in comments)

../PWA/PWA.srcs/sources_1/new/                <- Datapath subcomponents
../PWB/sources/hdl/                           <- MPC subcomponents
```

The Datapath (PWA) and MicroprogramController (PWB) live in sibling project folders. The PWF Vivado project references them via relative paths in `PWF.xpr`.

---

## ISA cheat-sheet

8 registers `R0..R7`. 16-bit instructions. 256x16 BRAM, addresses `0xF8..0xFF` mapped to MR registers.

| MR | Addr | What |
|----|------|------|
| MR0 | 0xF8 | 7-seg low byte (writable) |
| MR1 | 0xF9 | 7-seg high byte (writable) |
| MR2 | 0xFA | LEDs (writable) |
| MR3 | 0xFB | BTNR-latched SW |
| MR4 | 0xFC | BTNL-latched SW |
| MR5 | 0xFD | BTND-latched SW |
| MR6 | 0xFE | BTNU-latched SW |
| MR7 | 0xFF | BTNC-latched SW |

Common instructions:

| Instr | Opcode | Cin-sensitive? | Notes |
|---|---|---|---|
| `MOVA Rd Ra` | 0x00 | no | Rd = Ra |
| `INC Rd Ra` | 0x02 | **yes** (FS0=1) | needs Cin fix |
| `ADD Rd Ra Rb` | 0x04 | no (FS0=0) | Rd = Ra + Rb |
| `SUB Rd Ra Rb` | 0x0A | **yes** (FS0=1) | needs Cin fix |
| `DEC Rd Ra` | 0x0C | no (FS0=0) | Rd = Ra - 1 |
| `OR/AND/XOR Rd Ra Rb` | 0x10..0x14 | no (FS3=1) | logic, adder bypassed |
| `NOT Rd Ra` | 0x16 | no (FS3=1) | Rd = ~Ra |
| `LD Rd Ra` | 0x20 | no | Rd = M[Ra] |
| `ST Ra Rb` | 0x40 | no | M[Ra] = Rb |
| `LDI Rd imm3` | 0x98 | no | Rd = imm (0..7) |
| `JMP Ra` | 0xE0 | no | PC = Ra |

**LDI immediate is 3-bit (0..7).** I/O addresses (`0xF8..0xFF`) are out of range — manufacture them by loading `0xFF` (e.g. `NOT R2 R0`) then DEC'ing or SUB'ing down.

---

## Workflow: changing the program

```
1. Edit  PWF/tools/asm/examples/sw_to_led.asm   (or write a new .asm)
2. Run   python PWF/tools/asm/dsdasm.py asm <file>.asm --vhdl PWF/sources/hdl/Ram256x16.vhd
3. Verify in dsdasm:
        python PWF/tools/asm/dsdasm.py run <file>.asm --switches 0xA5 --press BTNR
4. In Vivado:
   - Save all (Ctrl+S)
   - Right-click synth_1 -> Reset Run
   - Right-click impl_1  -> Reset Run
   - Generate Bitstream  (~3-5 minutes)
5. Hardware Manager -> Program Device -> pick PWF.runs/impl_1/TOP_MODUL_F.bit
6. Press CPU_RESETN on the board
```

**Critical:** if you skip the `Reset Run` steps, Vivado may reuse cached synthesis output that doesn't include your BRAM INIT changes. The bitstream timestamp will look fresh but the FPGA gets the old program. We hit this multiple times during the session.

If a build looks like it didn't pick up changes, **nuke `PWF/PWF.runs/synth_1/` and `PWF/PWF.runs/impl_1/` and `PWF/PWF.cache/`** (close Vivado first), reopen, Generate Bitstream from scratch.

---

## Workflow: simulation only (no board)

```
In Vivado: Flow -> Run Simulation -> Run Behavioral Simulation
```

The TB (`Microprocessor_tb.vhd`) runs 5 tests:
1. Reset → LED = 0
2. BTNR + SW=0x42 → LED = 0x42
3. BTNR + SW=0xA5 → LED = 0xA5 (tests JMP loop)
4. BTNL + SW=0x99 → LED unchanged (program reads MR3, not MR4)
5. BTNR + SW=0xFF → LED = 0xFF
6. BTNR + SW=0x00 → LED = 0x00

Both `CLK` and `CLK_CPU` are driven from the same TB clock. Functional correctness doesn't depend on the divided-clock setup.

To re-load the wave config: `Window → Wave → Open` → pick `PWF/Microprocessor_tb_behav.wcfg`.

---

## Recent commit history (this branch)

```
abbcdab feat(PWF): working sw_to_led demo + HANDOFF document   <-- current HEAD
1aec43b feat(PWF): assembly eksempler + demo testbenches
778e271 fix(PWF): Cin = FS_sig(0) saa SUB/INC/DEC virker korrekt
f379eba feat(PWF): DivClk-baseret CPU-klok + switch_echo demo
4143909 fix(PWF): TOP_MODUL_F port hedder RESET (matcher XDC)
bfb51fa feat(PWF): RESETN active-low i top + danske tegn i kommentarer
e2e1a8e feat(PWF): tilfoej TOP_MODUL_F wiring og brug BRAM-baseret RAM
ff31b45 feat(PWF): koer hele microprocessoren - implementer SevenSeg, RAM, top-wiring og TB
```

The PR for this branch: https://github.com/Skab101/Design-of-digital-systems-62711/pull/new/feature/divclk-cpu

---

## Suggested next steps (priority order)

1. **Resolve the Cin investigation** (top of this doc) — once SUB works on the board, life becomes much easier.
2. **Switch sw_to_led.asm to the SUB-based version** (commented at the bottom of the file) — it's shorter and idiomatic.
3. **Add 7-seg writes** so the value also shows on the rightmost two hex digits (write to MR0).
4. **Write programs that use SUB/INC/ADD** — counter, accumulator, BTNR/BTNL operands summed, etc.
5. **Open a PR** for `feature/divclk-cpu` once everything works.
6. **Write report sections** (in `Report-PWF` submodule) about the dual-clock design, BRAM falling-edge trick, and the Cin fix.

---

## Conventions in this codebase

- Comments in HDL files use proper Danish characters (`æ`, `ø`, `å`) — not ASCII substitutes.
- Commit messages use ASCII substitutes (`koer`, `saa`, `taeller`) — match the existing style in `git log`.
- No AI attribution in commits (no `Co-Authored-By` lines).
- File paths in this codebase contain spaces (`"4. Semester"` etc.) — quote them in shell commands.
