# PWF Handoff — Microprocessor System (62711 Design of Digital Systems)

Session handoff. Read this fully before touching anything. The "Gotchas"
section is hard-won — re-discovering it costs hours.

---

## 1. TL;DR — current status

- **The calculator works.** `addsub_calc.asm` (plus/minus calculator) is
  verified correct in GHDL (7/7 asserts) **and** in Vivado xsim with the
  real Xilinx BRAM. It runs on the board after a fresh bitstream.
- `Ram256x16.vhd` currently has **addsub_calc** injected in `INIT_00`.
- Main repo (`team/`) is at `9021fcc` (PR #34 merged: IDC SRM/SLM fix +
  pulse demo + branch-offset fixes). Nothing important uncommitted in the
  main repo except generated dirs.
- **Report-PWF submodule has STAGED, UNCOMMITTED changes** (6 images +
  `sections/microcode-program.tex`). NOT pushed. See §7.

---

## 2. Repo layout

Root: `C:\Users\Mads2\DTU\4. Semester\Digital Systems Design\team`
(path has spaces — quote it; git-bash:
`/c/Users/Mads2/DTU/4. Semester/Digital Systems Design/team`).

Submodules:
- `PWA/` — Datapath (RegisterFile, FunctionUnit, Shifter, ALU…)
- `PWB/` — Microprogram Controller (IDC, ProgramCounter, IR, SignExtender…)
- `PWF/` — top integration: `Microprocessor.vhd`, `Ram256x16.vhd`,
  `PortReg8x8.vhd`, `MUX_MR.vhd`, `Zero_Filler_2.vhd`, `TOP_MODUL_F.vhd`,
  assembler `tools/asm/dsdasm.py`, testbenches `sources/tb/`.
- `Report/`, `Report-PWB/`, `Report-PWF/` — LaTeX (git submodules,
  **Overleaf two-way synced**). PWF report = combined PWA+PWB+PWF doc.

Submodules default to detached HEAD; `git checkout main` before pull.
Global rules: **no AI attribution in commits**, Danish commit messages,
Danish report text with real æøå.

---

## 3. GOTCHAS (critical hardware/ISA truths, reverse-engineered this session)

1. **Branches test a register, not a stored flag.** Flags V/C/N/Z are
   *combinational* — there is **no flag register** (PWA `Datapath.vhd`
   wires FunctionUnit flags straight out). During a `BRZ`/`BRN`'s own
   EX0, the FU runs with default `FS=0000` (pass A) and `AX=IR(5:3)`. So:
   - `BRZ A<reg>` branches iff `R[reg] == 0`
   - `BRN A<reg>` branches iff `R[reg]` bit7 == 1
   You **cannot** "compute then branch on result"; the branch's A-slot
   chooses the register it tests, live.

2. **Branch offset is relative to the BRANCH's own address** (PC doesn't
   increment during `INF`, `PS=00`). HW: `PC <= PC_branch + offset`. To
   skip the next instruction (`target=addr+2`) use **offset=2**, not 1.

3. **Offset = 6-bit signed split D-slot + B-slot** per
   `PWB/sources/hdl/SignExtender.vhd`:
   `Extended_8 = (IR(8)x3) & IR(7..6) & IR(2..0)` → D=sign+bits4..3,
   B=bits2..0, range −32..+31. **`BRZ`/`BRN` take 3 operands:**
   `BRZ D<offhi> A<testreg> B<offlo>`. e.g. `BRZ D0 A4 B2` =
   "if R4==0 → addr+2".

4. **`dsdasm.py` was fixed this session to match 1–3** (encoder, decoder,
   and simulator). Trust it again as source of truth.

5. **PortReg MR1 is effectively unwritable** → upper two 7-seg digits
   stuck at 00. `Zero_Filler_2.vhd` drives only `Data_In(7:0)` (high byte
   always 0) but `PortReg8x8.vhd` decodes MR1 write as `Data_In(15:8)`.
   Use **MR0 (lower 2 digits)** only. (1-line PortReg fix exists; user
   declined — design around it.)

6. **SRM/SLM**: Shifter is 1-bit; IDC loops EX2/EX3 `count` times
   (count = B immediate 0..7). The EX1 Z-check and `EX2 BX<="1000"` fixes
   are **already merged** (PR #34) and required.

7. **Stale-RAM trap.** Editing `.asm` does nothing until re-injected:
   `python PWF/tools/asm/dsdasm.py asm <f>.asm --vhdl PWF/sources/hdl/Ram256x16.vhd`
   Then Vivado needs **`relaunch_sim`** (recompile), not just `restart`;
   board needs full non-incremental re-synth + bitstream.

8. **Testbenches must self-terminate** or `run all` hangs forever.
   Pattern: `signal sim_done : boolean`; clock `while not sim_done loop`;
   stim sets `sim_done<=true` at end. Applied to `Microprocessor_tb`,
   `Ram256x16_tb`.

9. **Wave logging**: deep signals (e.g. `.../RF/sR1`) only record if
   added before the run → after `source wave_*.tcl` you must `restart`
   then `run all`, else those rows are blank. Top-level/DUT ports
   (`D_Word`) log by default.

10. **Orphaned `xsimk` locks `simulate.log`** → relaunch fails
    (boost::filesystem::remove). Kill stray `xsimk` PID, then
    `close_sim -force; launch_simulation`. Avoid by letting `run all`
    finish instead of Ctrl-C.

11. **LaTeX path rule**: filenames with spaces break `\includegraphics`
    here. Report images → `images/<topic>/` with ASCII, no-space names.

---

## 4. Toolchain

### dsdasm.py (`PWF/tools/asm/dsdasm.py`)
- `python dsdasm.py asm prog.asm --vhdl PWF/sources/hdl/Ram256x16.vhd`
- `python dsdasm.py asm prog.asm --bram out.bram` ; `dsdasm.py dasm out.bram`
- `python dsdasm.py run prog.asm [--trace] [--switches 0xNN] [--press BTNR]`
  (CLI shares one `--switches` across all `--press`; for distinct
  A/B/mode use the API): `import dsdasm; w,_=dsdasm.assemble(open(f).read());
  cpu=dsdasm.CPU(w); cpu.set_switches(a); cpu.press_button('BTNR'); …;
  cpu.step()`. Read results at `cpu.MR[0]`=MR0(0xF8, D_word low),
  `cpu.MR[1]`=MR1, `cpu.MR[2]`=LED; RAM at `cpu.mem`.

### GHDL flow (fast verify; no Xilinx BRAM)
GHDL: `/c/Users/Mads2/AppData/Local/Programs/GHDL/bin/ghdl`. Uses
behavioral `PWF/sources/tb/Ram256x16_sim.vhd` (its hand-coded `mem` init
must mirror the injected program — currently addsub_calc). Compile ONE
copy of duplicate entities: `flip_flop`,`MUX2x1`,`8bit_Register`,
`full_adder` (identical) and **PWA's** `full_adder_8_bit` (superset).
Exclude `16bitDFlipFlop.vhd`(dead/illegal name), `TOP_MODUL*`,
`SevenSegDriver`, `DivClk`, real `Ram256x16.vhd`. Analyze leaf→top
(ProgramCounter needs full_adder_8_bit first), then
`ghdl -a/-e/-r --std=08 -fsynopsys --workdir=/tmp/ghdlwork`. TB self-
terminates → expect `7 PASS, 0 FAIL`.

### Vivado xsim (board-accurate; real BRAM)
Tcl (paths in `{ }`):
```
relaunch_sim
source {.../PWF/sources/tb/wave_addsub.tcl}
restart
run all
```
RAM TB: `set_property top Ram256x16_tb [get_filesets sim_1]` →
`relaunch_sim` → `source {.../wave_ram.tcl}` → `restart` → `run all`.
Back: `set_property top Microprocessor_tb …`. Desktop (Danish):
`C:\Users\Mads2\OneDrive\Skrivebord`.

---

## 5. Testbenches & wave scripts (`PWF/sources/tb/`)

- `Microprocessor_tb.vhd` — addsub_calc, 7 asserts, colored, self-term.
- `Ram256x16_tb.vhd` — read+write+readback, 4 asserts, self-term.
- `Ram256x16_sim.vhd` — GHDL-only behavioral RAM (keep OUT of synth set).
- `PortReg8x8_tb.vhd` — existing.
- `wave_addsub.tcl` — trimmed/colored/hex layout (Input/Registre/Resultat).
- `wave_ram.tcl` — colored RAM timing-diagram layout.

---

## 6. Programs (`PWF/tools/asm/examples/`)

| File | What | State |
|---|---|---|
| `addsub_calc.asm` | calc: BTNR=A, BTNL=B, BTND=mode(0=−/1=+) | ✅ verified, injected |
| `sw_to_7seg.asm` | SW→7-seg hex via BTNR | ✅ board |
| `sw_to_led_sub.asm` | SW→LED (SUB) | ✅ board |
| `addsub_both.asm` | A+B & A−B at once | sim-only (blocked by gotcha 5) |
| `knight_rider.asm` | LED bounce SLM/SRM | sim-verified, offsets fixed |
| `srm_led_pulse.asm` | LED fill+drain | sim-verified, offsets fixed |
| `srm_led_fill.asm`,`calculator.asm` | older demos | offsets fixed |

All BRZ use the 3-operand `D A B` form (gotcha 3).

---

## 7. Report-PWF (UNCOMMITTED — decision pending)

Pulled to `8f55903`. **Staged, not committed/pushed:**
- `images/system/`: `asm_tb_part1/2/3.png` (test-prog sim 3 parts),
  `addsub_calc_sim.png` (calc sim), `board_addsub_5.jpg`,
  `board_addsub_6.jpg` (calc on HW, 7-seg 0005/0006).
- 5 messy space-named root PNGs removed (Overleaf clutter).
- `sections/microcode-program.tex`: §Simulering = test-prog 3 figs +
  "Regneprogram" para + calc sim fig; §Hardware-afvikling = 2 board
  photos. Labels `fig:asm-tb-1/2/3`,`fig:addsub-sim`,
  `fig:board-addsub-5/6`. **Builds clean: 58 pages, no errors.**

⚠️ Overleaf two-way synced. **Ask user before pushing** (push → Overleaf
pulls; or leave staged for user to sync from Overleaf). User has NOT
chosen yet.

### Remaining report gaps (agreed plan)
- `syntese.tex`: 4 empty subsections (RAM/PortReg/Microprocessor sim,
  Syntese Resultater).
- `ram.tex`: broken `\includegraphics{RAM instruktioner.png}` → needs
  RAM timing fig (from `wave_ram.tcl`).
- Still-needed images: RAM read/write waveform, Vivado
  utilization+timing screenshots, optional test-program board photo.
- `tab:pwf-modulansvar` / `tab:pwf-tidsforbrug` in `main.tex` = TBD/0.

---

## 8. Next steps

1. Ask user: commit+push Report-PWF now vs leave for Overleaf sync.
2. On new images: copy → `images/{ram,syntese,system}/` (ASCII), fix
   `ram.tex` path, fill `syntese.tex` subsections (fig + 2–4 lines DA),
   `pdflatex` x2.
3. Fill modulansvar/tidsforbrug tables when user provides data.
4. Board: non-incremental re-synth → impl → bitstream → program; verify
   addsub_calc.

---

## 9. Quick reference

Inject: `python PWF/tools/asm/dsdasm.py asm PWF/tools/asm/examples/addsub_calc.asm --vhdl PWF/sources/hdl/Ram256x16.vhd`

GHDL: `ghdl -r --std=08 -fsynopsys --workdir=/tmp/ghdlwork Microprocessor_tb` → `7 PASS, 0 FAIL`

Report build: `cd Report-PWF && pdflatex -interaction=nonstopmode -halt-on-error -file-line-error main.tex` (twice)

Kill stray sim: PowerShell `Get-Process xsimk | Stop-Process -Force`

addsub_calc expected D_Word low byte: 8−3=05, 8+3=0B, 10+4=0E,
10−4=06, 3−8=FB(−5), 200+100=2C(wrap). Workflow: SW=A→BTNR, SW=B→BTNL,
SW=0/1→BTND (minus default), result on lower 2 7-seg digits.
