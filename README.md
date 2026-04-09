# Design of Digital Systems (62711) -- Group 3

Course repository for 62711 at DTU -- spring 2026. Contains Vivado projects, VHDL sources, testbenches, and LaTeX reports for all three project phases.

| Phase | Topic | Status | Report |
|-------|-------|--------|--------|
| PWA | ALU / DataPath | Completed | [Download PDF](https://github.com/gigurd/Design-of-digital-systems-62711/releases/tag/latest) |
| PWB | Microprogram Controller | Completed | [Download PDF](https://github.com/gigurd/Design-of-digital-systems-62711/releases/tag/latest-pwb) |
| PWF | Final Microprocessor | Upcoming | -- |

---

## PWA -- ALU / DataPath

Design and implementation of the ALU and DataPath (Register File, Function Unit, Shifter, MUXes).

- `PWA/` -- Vivado project (Nexys 4 DDR, xc7a100tcsg324-1)
  - `PWA.srcs/sources_1/` -- 17 VHDL source files
  - `PWA.srcs/sim_1/` -- 16 testbenches
- `Report/` -- LaTeX source (Overleaf submodule, auto-compiled via GitHub Actions)
- `Submissions/Group03_PWA.zip` -- Cleaned project ready for submission

## PWB -- Microprogram Controller

Design and implementation of the Microprogram Controller (Program Counter, Instruction Register, Sign Extender, Zero Filler, Instruction Decoder/Controller).

- `PWB/` -- Vivado project
  - `sources/hdl/` -- 12 VHDL source files
  - `sources/tb/` -- 6 testbenches
- `Report-PWB/` -- LaTeX source (Overleaf submodule, auto-compiled via GitHub Actions)
- `Submissions/Group03_PWB.zip` -- Cleaned project ready for submission
- `Submissions/Group03_PWB_Report.pdf` -- Final report PDF

## PWF -- Final Microprocessor

Complete working soft microprocessor on FPGA hardware -- combining PWA DataPath, PWB Control Unit, memory, and I/O.

*Coming after Easter break.*

---

## Group Members

| Name | Student ID |
|------|-----------|
| Andreas Skanning | s241123 |
| Jonas Beck Jensen | s240324 |
| Mads Rudolph | s246132 |
| Sigurd Hestbech Christiansen | s245534 |
