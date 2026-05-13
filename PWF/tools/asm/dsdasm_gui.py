#!/usr/bin/env python3
"""
dsdasm GUI -- Tkinter frontend for the PWF assembler/simulator.

A single-window IDE for the DSD 62711 PWF microprocessor: edit .asm, assemble,
step through a simulator, watch a visual Nexys 4 DDR board light up, and patch
the result straight into Ram256x16.vhd.

Run:
    python dsdasm_gui.py [optional.asm]

Dependencies: Python 3.8+ standard library only (tkinter).
"""

import re
import sys
import tkinter as tk
from pathlib import Path
from tkinter import filedialog, messagebox

_HERE = Path(__file__).parent
if str(_HERE) not in sys.path:
    sys.path.insert(0, str(_HERE))
import dsdasm  # noqa: E402

# ----------------------------------------------------------------------------
# Colors & fonts
# ----------------------------------------------------------------------------

FONT_MONO       = ("Consolas", 11)
FONT_MONO_SMALL = ("Consolas", 9)
FONT_UI         = ("Segoe UI", 10)
FONT_UI_BOLD    = ("Segoe UI", 10, "bold")

COLOR_BG            = "#1e1e1e"
COLOR_EDITOR_BG     = "#252526"
COLOR_FG            = "#d4d4d4"
COLOR_LINENO_BG     = "#1e1e1e"
COLOR_LINENO_FG     = "#858585"
COLOR_PC_HIGHLIGHT  = "#3a3a1a"
COLOR_ERROR_BG      = "#481818"
COLOR_MNEMONIC      = "#569cd6"
COLOR_REGISTER      = "#9cdcfe"
COLOR_IMMEDIATE     = "#b5cea8"
COLOR_LABEL         = "#dcdcaa"
COLOR_COMMENT       = "#6a9955"
COLOR_LED_ON        = "#00ff55"
COLOR_LED_OFF       = "#153018"
COLOR_7SEG_ON       = "#ff4040"
COLOR_7SEG_OFF      = "#2a1010"
COLOR_SW_ON         = "#4488ff"
COLOR_SW_OFF        = "#333333"
COLOR_BTN           = "#888888"
COLOR_BTN_PRESSED   = "#ff4444"

# 7-seg pattern per hex nibble: bit a(6) b(5) c(4) d(3) e(2) f(1) g(0)
HEX_7SEG = {
    0x0: 0b1111110, 0x1: 0b0110000, 0x2: 0b1101101, 0x3: 0b1111001,
    0x4: 0b0110011, 0x5: 0b1011011, 0x6: 0b1011111, 0x7: 0b1110000,
    0x8: 0b1111111, 0x9: 0b1111011, 0xA: 0b1110111, 0xB: 0b0011111,
    0xC: 0b1001110, 0xD: 0b0111101, 0xE: 0b1001111, 0xF: 0b1000111,
}

MNEMONICS    = set(dsdasm.ISA.keys())
MNEMONIC_RE  = re.compile(r'\b(' + '|'.join(MNEMONICS) + r')\b', re.IGNORECASE)
REG_RE       = re.compile(r'\b[RrDdAaBb]\d+\b')
IMM_RE       = re.compile(r'\b(0x[0-9A-Fa-f]+|0b[01]+|-?\d+)\b')
LABEL_RE     = re.compile(r'^[ \t]*([A-Za-z_]\w*):', re.MULTILINE)
DIRECTIVE_RE = re.compile(r'\.\w+', re.IGNORECASE)

# ----------------------------------------------------------------------------
# Nexys board canvas
# ----------------------------------------------------------------------------

class BoardCanvas(tk.Canvas):
    W, H = 920, 180

    def __init__(self, parent, on_sw_toggle, on_btn_press):
        super().__init__(parent, width=self.W, height=self.H,
                         bg=COLOR_BG, highlightthickness=0)
        self.on_sw_toggle = on_sw_toggle
        self.on_btn_press = on_btn_press
        self._seg_ids = [[None]*7 for _ in range(4)]
        self._led_ids = [None]*8
        self._sw_ids  = [None]*8
        self._sw_states = [False]*8
        self._btn_ids = {}
        self._draw()

    def _draw(self):
        # --- 4-digit 7-seg on the left ---
        x0, y0, dw, dh, gap = 20, 30, 42, 75, 12
        self.create_text(x0, y0 - 14, text="7-seg (D_Word)",
                         fill=COLOR_FG, font=FONT_UI_BOLD, anchor="w")
        for d in range(4):
            self._draw_digit(d, x0 + d * (dw + gap), y0, dw, dh)

        # --- LEDs ---
        led_x0, led_y, led_r = 280, 35, 10
        self.create_text(led_x0 - 15, led_y - 18, text="LEDs (MR2)",
                         fill=COLOR_FG, font=FONT_UI_BOLD, anchor="w")
        for i in range(8):
            x = led_x0 + (7 - i) * (2 * led_r + 10)
            self._led_ids[i] = self.create_oval(
                x - led_r, led_y - led_r, x + led_r, led_y + led_r,
                fill=COLOR_LED_OFF, outline="#666")
            self.create_text(x, led_y + led_r + 10, text=str(i),
                             fill=COLOR_LINENO_FG, font=FONT_MONO_SMALL)

        # --- Switches ---
        sw_x0, sw_y, sw_w, sw_h = 280, 90, 16, 30
        self.create_text(sw_x0 - 15, sw_y + sw_h / 2, text="SW",
                         fill=COLOR_FG, font=FONT_UI_BOLD, anchor="w")
        for i in range(8):
            x = sw_x0 + (7 - i) * (2 * led_r + 10)
            rid = self.create_rectangle(
                x - sw_w/2, sw_y, x + sw_w/2, sw_y + sw_h,
                fill=COLOR_SW_OFF, outline="#666")
            self._sw_ids[i] = rid
            self.tag_bind(rid, "<Button-1>",
                          lambda e, idx=i: self._on_sw_click(idx))
            self.create_text(x, sw_y + sw_h + 10, text=str(i),
                             fill=COLOR_LINENO_FG, font=FONT_MONO_SMALL)

        # --- Buttons in cross layout ---
        cx, cy, br = 780, 85, 18
        self.create_text(cx, 10, text="Buttons",
                         fill=COLOR_FG, font=FONT_UI_BOLD)
        positions = {
            'BTNU': (cx,              cy - 2*br - 6),
            'BTNL': (cx - 2*br - 6,   cy),
            'BTNC': (cx,              cy),
            'BTNR': (cx + 2*br + 6,   cy),
            'BTND': (cx,              cy + 2*br + 6),
        }
        for name, (x, y) in positions.items():
            oid = self.create_oval(x - br, y - br, x + br, y + br,
                                   fill=COLOR_BTN, outline="#ccc")
            self.create_text(x, y, text=name[3],
                             fill="white", font=FONT_UI_BOLD)
            self._btn_ids[name] = oid
            self.tag_bind(oid, "<ButtonPress-1>",
                          lambda e, n=name: self._on_btn_click(n))
            self.tag_bind(oid, "<ButtonRelease-1>",
                          lambda e, n=name: self._on_btn_release(n))

    def _draw_digit(self, d, x, y, w, h):
        t = 5                      # segment thickness
        # Segment order: a b c d e f g
        # a (top horizontal)
        self._seg_ids[d][0] = self.create_polygon(
            x+t, y, x+w-t, y, x+w-2*t, y+t, x+2*t, y+t,
            fill=COLOR_7SEG_OFF, outline="")
        # b (upper right)
        self._seg_ids[d][1] = self.create_polygon(
            x+w, y+t, x+w, y+h/2-t/2, x+w-t, y+h/2-t, x+w-t, y+2*t,
            fill=COLOR_7SEG_OFF, outline="")
        # c (lower right)
        self._seg_ids[d][2] = self.create_polygon(
            x+w, y+h/2+t/2, x+w, y+h-t, x+w-t, y+h-2*t, x+w-t, y+h/2+t,
            fill=COLOR_7SEG_OFF, outline="")
        # d (bottom)
        self._seg_ids[d][3] = self.create_polygon(
            x+2*t, y+h-t, x+w-2*t, y+h-t, x+w-t, y+h, x+t, y+h,
            fill=COLOR_7SEG_OFF, outline="")
        # e (lower left)
        self._seg_ids[d][4] = self.create_polygon(
            x, y+h/2+t/2, x+t, y+h/2+t, x+t, y+h-2*t, x, y+h-t,
            fill=COLOR_7SEG_OFF, outline="")
        # f (upper left)
        self._seg_ids[d][5] = self.create_polygon(
            x, y+t, x+t, y+2*t, x+t, y+h/2-t, x, y+h/2-t/2,
            fill=COLOR_7SEG_OFF, outline="")
        # g (middle)
        self._seg_ids[d][6] = self.create_polygon(
            x+2*t, y+h/2-t/2, x+w-2*t, y+h/2-t/2,
            x+w-t, y+h/2,     x+w-2*t, y+h/2+t/2,
            x+2*t, y+h/2+t/2, x+t,     y+h/2,
            fill=COLOR_7SEG_OFF, outline="")

    def update_7seg(self, d_word):
        for d in range(4):
            # D_Word: MR1 is high byte (left digits), MR0 is low byte (right digits)
            nibble = (d_word >> (4 * (3 - d))) & 0xF
            pattern = HEX_7SEG.get(nibble, 0)
            # pattern bits: a(6) b(5) c(4) d(3) e(2) f(1) g(0)
            for i, bit in enumerate([6, 5, 4, 3, 2, 1, 0]):
                on = bool((pattern >> bit) & 1)
                self.itemconfig(self._seg_ids[d][i],
                                fill=COLOR_7SEG_ON if on else COLOR_7SEG_OFF)

    def update_leds(self, value):
        for i in range(8):
            on = bool((value >> i) & 1)
            self.itemconfig(self._led_ids[i],
                            fill=COLOR_LED_ON if on else COLOR_LED_OFF)

    def get_sw(self):
        return sum((1 << i) for i, s in enumerate(self._sw_states) if s)

    def _on_sw_click(self, idx):
        self._sw_states[idx] = not self._sw_states[idx]
        self.itemconfig(self._sw_ids[idx],
                        fill=COLOR_SW_ON if self._sw_states[idx] else COLOR_SW_OFF)
        self.on_sw_toggle()

    def _on_btn_click(self, name):
        self.itemconfig(self._btn_ids[name], fill=COLOR_BTN_PRESSED)
        self.on_btn_press(name)

    def _on_btn_release(self, name):
        self.itemconfig(self._btn_ids[name], fill=COLOR_BTN)


# ----------------------------------------------------------------------------
# Main GUI
# ----------------------------------------------------------------------------

class DsdasmGUI:
    SIM_TICK_MS = 1      # between sim batches
    SIM_BATCH   = 200    # instructions per tick in Run mode

    def __init__(self, root):
        self.root = root
        root.title("dsdasm -- PWF Assembler & Simulator")
        root.geometry("1340x880")
        root.configure(bg=COLOR_BG)

        # State
        self.cpu = None
        self.words = []
        self.labels = {}
        self.source_path = None
        self.dirty = False
        self.running = False

        self._build_menu()
        self._build_toolbar()
        self._build_body()
        self._build_console()
        self._bind_shortcuts()

        self._refresh_state()
        self._log("Ready. File -> Open to load .asm, or start typing.", "info")

    # ---------------- UI construction ----------------

    def _build_menu(self):
        mb = tk.Menu(self.root)
        self.root.config(menu=mb)

        fm = tk.Menu(mb, tearoff=False)
        fm.add_command(label="New", accelerator="Ctrl+N", command=self.cmd_new)
        fm.add_command(label="Open...", accelerator="Ctrl+O", command=self.cmd_open)
        fm.add_command(label="Save", accelerator="Ctrl+S", command=self.cmd_save)
        fm.add_command(label="Save As...", command=self.cmd_save_as)
        fm.add_separator()
        fm.add_command(label="Quit", accelerator="Ctrl+Q", command=self.root.quit)
        mb.add_cascade(label="File", menu=fm)

        bm = tk.Menu(mb, tearoff=False)
        bm.add_command(label="Assemble", accelerator="F5",
                       command=self.cmd_assemble)
        bm.add_command(label="Patch VHDL...", command=self.cmd_patch_vhdl)
        mb.add_cascade(label="Build", menu=bm)

        rm = tk.Menu(mb, tearoff=False)
        rm.add_command(label="Reset", accelerator="Ctrl+R", command=self.cmd_reset)
        rm.add_command(label="Step", accelerator="F10", command=self.cmd_step)
        rm.add_command(label="Run / Pause", accelerator="F9",
                       command=self.cmd_run_toggle)
        mb.add_cascade(label="Run", menu=rm)

        hm = tk.Menu(mb, tearoff=False)
        hm.add_command(label="About", command=self.cmd_about)
        mb.add_cascade(label="Help", menu=hm)

    def _build_toolbar(self):
        tb = tk.Frame(self.root, bg=COLOR_BG)
        tb.pack(side="top", fill="x", padx=4, pady=3)

        def btn(text, cmd):
            b = tk.Button(tb, text=text, command=cmd, font=FONT_UI,
                          bg="#333", fg=COLOR_FG, activebackground="#444",
                          activeforeground=COLOR_FG, relief="flat",
                          padx=8, pady=3, borderwidth=0)
            b.pack(side="left", padx=2)
            return b

        def sep():
            tk.Frame(tb, bg="#444", width=1).pack(side="left", fill="y",
                                                  padx=6, pady=3)

        btn("Open", self.cmd_open)
        btn("Save", self.cmd_save)
        sep()
        btn("Assemble (F5)", self.cmd_assemble)
        btn("Patch VHDL", self.cmd_patch_vhdl)
        sep()
        btn("Reset", self.cmd_reset)
        btn("Step (F10)", self.cmd_step)
        self.btn_run = btn("Run (F9)", self.cmd_run_toggle)

        self.status_var = tk.StringVar(value="idle")
        tk.Label(tb, textvariable=self.status_var, bg=COLOR_BG, fg="#888",
                 font=FONT_UI_BOLD).pack(side="right", padx=8)

    def _build_body(self):
        body = tk.Frame(self.root, bg=COLOR_BG)
        body.pack(side="top", fill="both", expand=True)

        left = tk.Frame(body, bg=COLOR_BG)
        left.pack(side="left", fill="both", expand=True)
        self._build_editor(left)

        right = tk.Frame(body, bg=COLOR_BG, width=340)
        right.pack(side="left", fill="y")
        right.pack_propagate(False)
        self._build_state(right)

        self._build_board()

    def _build_editor(self, parent):
        frame = tk.Frame(parent, bg=COLOR_EDITOR_BG)
        frame.pack(fill="both", expand=True, padx=4, pady=2)

        self.lineno = tk.Text(frame, width=5, padx=4, takefocus=0, border=0,
                              background=COLOR_LINENO_BG, foreground=COLOR_LINENO_FG,
                              font=FONT_MONO, state="disabled", wrap="none")
        self.lineno.pack(side="left", fill="y")

        self.editor = tk.Text(frame, wrap="none", undo=True,
                              background=COLOR_EDITOR_BG, foreground=COLOR_FG,
                              insertbackground=COLOR_FG, font=FONT_MONO,
                              border=0, padx=6, pady=4, tabs=("1c",))
        self.editor.pack(side="left", fill="both", expand=True)

        vs = tk.Scrollbar(frame, command=self._yview_both)
        vs.pack(side="right", fill="y")
        self.editor.config(yscrollcommand=lambda f, l: self._on_editor_scroll(vs, f, l))

        self.editor.tag_configure("mnemonic", foreground=COLOR_MNEMONIC)
        self.editor.tag_configure("register", foreground=COLOR_REGISTER)
        self.editor.tag_configure("immediate", foreground=COLOR_IMMEDIATE)
        self.editor.tag_configure("label", foreground=COLOR_LABEL,
                                  font=(FONT_MONO[0], FONT_MONO[1], "bold"))
        self.editor.tag_configure("comment", foreground=COLOR_COMMENT,
                                  font=(FONT_MONO[0], FONT_MONO[1], "italic"))
        self.editor.tag_configure("directive", foreground=COLOR_LABEL)
        self.editor.tag_configure("error_line", background=COLOR_ERROR_BG)
        self.editor.tag_configure("pc_line", background=COLOR_PC_HIGHLIGHT)

        self.editor.bind("<<Modified>>", self._on_text_modified)
        self.editor.bind("<KeyRelease>", lambda e: self._rehighlight())

    def _yview_both(self, *args):
        self.editor.yview(*args)
        self.lineno.yview(*args)

    def _on_editor_scroll(self, scrollbar, first, last):
        scrollbar.set(first, last)
        self.lineno.yview_moveto(first)

    def _build_state(self, parent):
        rf = tk.LabelFrame(parent, text="Registers", bg=COLOR_BG, fg=COLOR_FG,
                           font=FONT_UI_BOLD, padx=6, pady=4)
        rf.pack(side="top", fill="x", padx=4, pady=(4, 2))

        self.reg_vars = [tk.StringVar(value="0x00") for _ in range(8)]
        self.pc_var   = tk.StringVar(value="0x00")
        self.flag_var = tk.StringVar(value="V=0 C=0 N=0 Z=0")

        for i in range(8):
            row, col = divmod(i, 2)
            tk.Label(rf, text=f"R{i}", bg=COLOR_BG, fg=COLOR_REGISTER,
                     font=FONT_MONO).grid(row=row, column=col*2,
                                          padx=(4, 2), sticky="w")
            tk.Label(rf, textvariable=self.reg_vars[i], bg=COLOR_BG,
                     fg=COLOR_FG, font=FONT_MONO, width=7,
                     anchor="w").grid(row=row, column=col*2+1, padx=(0, 10))

        tk.Label(rf, text="PC", bg=COLOR_BG, fg=COLOR_REGISTER,
                 font=FONT_MONO).grid(row=4, column=0, padx=(4, 2),
                                      pady=(6, 0), sticky="w")
        tk.Label(rf, textvariable=self.pc_var, bg=COLOR_BG, fg=COLOR_FG,
                 font=FONT_MONO, width=7,
                 anchor="w").grid(row=4, column=1, pady=(6, 0))
        tk.Label(rf, textvariable=self.flag_var, bg=COLOR_BG, fg="#ce9178",
                 font=FONT_MONO).grid(row=4, column=2, columnspan=2,
                                      padx=(4, 0), pady=(6, 0), sticky="w")

        mf = tk.LabelFrame(parent, text="Memory  (highlight = PC)", bg=COLOR_BG,
                           fg=COLOR_FG, font=FONT_UI_BOLD, padx=2, pady=2)
        mf.pack(side="top", fill="both", expand=True, padx=4, pady=2)
        self.memview = tk.Text(mf, font=FONT_MONO_SMALL,
                               bg=COLOR_EDITOR_BG, fg=COLOR_FG,
                               border=0, state="disabled", wrap="none")
        vs = tk.Scrollbar(mf, command=self.memview.yview)
        vs.pack(side="right", fill="y")
        self.memview.config(yscrollcommand=vs.set)
        self.memview.pack(side="left", fill="both", expand=True)
        self.memview.tag_configure("pc_row", background=COLOR_PC_HIGHLIGHT)
        self.memview.tag_configure("io_row", foreground="#ce9178")

    def _build_board(self):
        bf = tk.LabelFrame(self.root, text="Nexys 4 DDR", bg=COLOR_BG,
                           fg=COLOR_FG, font=FONT_UI_BOLD, padx=4, pady=2)
        bf.pack(side="top", fill="x", padx=4, pady=(2, 2))
        self.board = BoardCanvas(bf, on_sw_toggle=self._on_sw_toggle,
                                 on_btn_press=self._on_btn_press)
        self.board.pack(fill="x")

    def _build_console(self):
        cf = tk.LabelFrame(self.root, text="Console", bg=COLOR_BG,
                           fg=COLOR_FG, font=FONT_UI_BOLD, padx=2, pady=2)
        cf.pack(side="bottom", fill="x", padx=4, pady=(2, 4))
        self.console = tk.Text(cf, height=6, font=FONT_MONO_SMALL,
                               bg=COLOR_EDITOR_BG, fg=COLOR_FG,
                               border=0, state="disabled", wrap="word")
        self.console.pack(fill="x")
        self.console.tag_configure("error", foreground="#f14c4c")
        self.console.tag_configure("info",  foreground="#569cd6")
        self.console.tag_configure("link",  foreground="#dcdcaa", underline=True)
        self.console.tag_bind("link", "<Button-1>", self._on_console_link)
        self.console.tag_bind("link", "<Enter>",
                              lambda e: self.console.configure(cursor="hand2"))
        self.console.tag_bind("link", "<Leave>",
                              lambda e: self.console.configure(cursor=""))

    def _bind_shortcuts(self):
        r = self.root
        r.bind("<Control-n>", lambda e: self.cmd_new())
        r.bind("<Control-o>", lambda e: self.cmd_open())
        r.bind("<Control-s>", lambda e: self.cmd_save())
        r.bind("<Control-q>", lambda e: r.quit())
        r.bind("<Control-r>", lambda e: self.cmd_reset())
        r.bind("<F5>",  lambda e: self.cmd_assemble())
        r.bind("<F9>",  lambda e: self.cmd_run_toggle())
        r.bind("<F10>", lambda e: self.cmd_step())

    # ---------------- Editor helpers ----------------

    def _get_source(self):
        return self.editor.get("1.0", "end-1c")

    def _set_source(self, text):
        self.editor.delete("1.0", "end")
        self.editor.insert("1.0", text)
        self.editor.edit_reset()
        self.editor.edit_modified(False)
        self.dirty = False
        self._update_title()
        self._refresh_lineno()
        self._rehighlight()

    def _on_text_modified(self, event=None):
        if self.editor.edit_modified():
            self.dirty = True
            self._update_title()
            self.editor.edit_modified(False)
        self._refresh_lineno()
        # Invalidate compiled program
        self.editor.tag_remove("error_line", "1.0", "end")

    def _refresh_lineno(self):
        n = int(self.editor.index("end-1c").split(".")[0])
        text = "\n".join(f"{i:>4}" for i in range(1, n + 1))
        self.lineno.config(state="normal")
        self.lineno.delete("1.0", "end")
        self.lineno.insert("1.0", text)
        self.lineno.config(state="disabled")

    def _rehighlight(self):
        for tag in ("mnemonic", "register", "immediate", "label",
                    "comment", "directive"):
            self.editor.tag_remove(tag, "1.0", "end")

        src = self._get_source()

        # 1. Comments: whole-line from ; or # to EOL.
        # Track comment ranges so subsequent regexes can skip them.
        comment_spans = []
        for line_start in range(len(src)):
            pass  # no-op; handled per-line below
        for mline in re.finditer(r'[^\n]*', src):
            line = mline.group()
            base = mline.start()
            cut = len(line)
            for mark in (';', '#'):
                idx = line.find(mark)
                if idx >= 0 and idx < cut:
                    cut = idx
            if cut < len(line):
                self._apply_tag("comment", base + cut, base + len(line))
                comment_spans.append((base + cut, base + len(line)))

        def in_comment(pos):
            for s, e in comment_spans:
                if s <= pos < e:
                    return True
            return False

        for m in LABEL_RE.finditer(src):
            if not in_comment(m.start(1)):
                self._apply_tag("label", m.start(1), m.end(1))
        for m in DIRECTIVE_RE.finditer(src):
            if not in_comment(m.start()):
                self._apply_tag("directive", m.start(), m.end())
        for m in MNEMONIC_RE.finditer(src):
            if not in_comment(m.start()):
                self._apply_tag("mnemonic", m.start(), m.end())
        for m in REG_RE.finditer(src):
            if not in_comment(m.start()):
                self._apply_tag("register", m.start(), m.end())
        for m in IMM_RE.finditer(src):
            if not in_comment(m.start()):
                self._apply_tag("immediate", m.start(), m.end())

    def _apply_tag(self, tag, start, end):
        self.editor.tag_add(tag,
                            f"1.0+{start}c",
                            f"1.0+{end}c")

    def _highlight_pc_line(self):
        self.editor.tag_remove("pc_line", "1.0", "end")
        if self.cpu is None or not self.words:
            return
        # Find line number for PC using the stored line map
        line = self._pc_to_line.get(self.cpu.PC)
        if line is not None:
            self.editor.tag_add("pc_line", f"{line}.0", f"{line}.end+1c")
            self.editor.see(f"{line}.0")

    # ---------------- File commands ----------------

    def _confirm_discard(self):
        if not self.dirty:
            return True
        r = messagebox.askyesnocancel(
            "Unsaved changes",
            "You have unsaved changes. Save before continuing?",
            parent=self.root)
        if r is None:
            return False
        if r is False:
            return True
        return self.cmd_save()

    def cmd_new(self):
        if not self._confirm_discard():
            return
        self.source_path = None
        self._set_source("")
        self._log("New empty buffer.", "info")

    def cmd_open(self, path=None):
        if path is None:
            if not self._confirm_discard():
                return
            path = filedialog.askopenfilename(
                parent=self.root, title="Open assembly",
                filetypes=[("Assembly", "*.asm *.s"), ("All files", "*.*")],
                initialdir=str(_HERE / "examples" if (_HERE / "examples").is_dir() else _HERE))
            if not path:
                return
        self.source_path = Path(path)
        self._set_source(self.source_path.read_text())
        self._log(f"Opened {self.source_path}", "info")

    def cmd_save(self):
        if self.source_path is None:
            return self.cmd_save_as()
        self.source_path.write_text(self._get_source())
        self.dirty = False
        self._update_title()
        self._log(f"Saved {self.source_path}", "info")
        return True

    def cmd_save_as(self):
        path = filedialog.asksaveasfilename(
            parent=self.root, title="Save assembly as",
            defaultextension=".asm",
            filetypes=[("Assembly", "*.asm"), ("All files", "*.*")],
            initialdir=str(_HERE))
        if not path:
            return False
        self.source_path = Path(path)
        return self.cmd_save()

    def _update_title(self):
        name = self.source_path.name if self.source_path else "<untitled>"
        mark = " *" if self.dirty else ""
        self.root.title(f"dsdasm -- {name}{mark}")

    # ---------------- Assemble + VHDL ----------------

    def cmd_assemble(self):
        self.editor.tag_remove("error_line", "1.0", "end")
        self.running = False
        self.btn_run.configure(text="Run (F9)")
        try:
            words, labels = dsdasm.assemble(self._get_source())
        except dsdasm.AsmError as e:
            self._log(f"line {e.line_num}: {e.msg}", "error",
                      link_line=e.line_num)
            self.editor.tag_add("error_line",
                                f"{e.line_num}.0", f"{e.line_num}.end+1c")
            self.status_var.set("asm error")
            return False

        self.words = words
        self.labels = labels
        # Build a PC -> source line number map for the PC highlight feature.
        # Strategy: re-parse source to find line numbers of non-blank, non-label
        # lines that produce words. Cheaper: assemble again tracking lines — but
        # simplest: walk source and count instruction-producing lines in order.
        self._pc_to_line = self._build_pc_line_map(self._get_source())

        label_str = ", ".join(f"{n}=0x{a:02X}"
                              for n, a in sorted(labels.items(),
                                                  key=lambda kv: kv[1]))
        self._log(f"OK: {len(words)} words"
                  + (f"  labels: {label_str}" if labels else ""), "info")
        self.status_var.set(f"assembled ({len(words)} words)")
        self.cmd_reset()
        return True

    def _build_pc_line_map(self, src):
        mapping = {}
        pc = 0
        for lineno, raw in enumerate(src.splitlines(), 1):
            # Strip comment
            cut = len(raw)
            for ch in (';', '#'):
                idx = raw.find(ch)
                if 0 <= idx < cut:
                    cut = idx
            line = raw[:cut].replace(',', ' ')
            toks = line.split()
            # Strip leading labels
            while toks and toks[0].endswith(':'):
                toks = toks[1:]
            if not toks:
                continue
            if toks[0].lower() == '.word' or toks[0].upper() in MNEMONICS:
                mapping[pc] = lineno
                pc += 1
        return mapping

    def cmd_patch_vhdl(self):
        if not self.words:
            if not self.cmd_assemble():
                return
        default = _HERE.parent.parent / "sources" / "hdl" / "Ram256x16.vhd"
        path = filedialog.askopenfilename(
            parent=self.root, title="Select Ram256x16.vhd to patch",
            filetypes=[("VHDL", "*.vhd *.vhdl"), ("All files", "*.*")],
            initialdir=str(default.parent) if default.parent.is_dir()
                        else str(_HERE),
            initialfile=default.name if default.is_file() else "")
        if not path:
            return
        try:
            dsdasm.patch_vhdl(path, self.words)
        except Exception as e:  # noqa: BLE001
            self._log(f"Patch failed: {e}", "error")
            return
        self._log(f"Patched INIT_xx into {path}", "info")

    # ---------------- Simulator commands ----------------

    def cmd_reset(self):
        self.running = False
        self.btn_run.configure(text="Run (F9)")
        if not self.words:
            self.cpu = None
            self._pc_to_line = {}
        else:
            prev_mr = list(self.cpu.MR) if self.cpu else [0] * 8
            self.cpu = dsdasm.CPU(self.words)
            self.cpu.sw = self.board.get_sw()
            self.cpu.MR = prev_mr
        self.status_var.set("reset")
        self._refresh_state()

    def cmd_step(self):
        if self.cpu is None:
            if not self.cmd_assemble():
                return
        if self.cpu.halted:
            self.status_var.set("halted")
            return
        try:
            self.cpu.step()
        except Exception as e:  # noqa: BLE001
            self._log(f"Runtime error: {e}", "error")
            self.status_var.set("error")
            return
        self.status_var.set("halted" if self.cpu.halted else "stepped")
        self._refresh_state()

    def cmd_run_toggle(self):
        if self.cpu is None:
            if not self.cmd_assemble():
                return
        if self.running:
            self.running = False
            self.btn_run.configure(text="Run (F9)")
            self.status_var.set("paused")
            return
        if self.cpu.halted:
            self.status_var.set("halted")
            return
        self.running = True
        self.btn_run.configure(text="Pause (F9)")
        self.status_var.set("running")
        self.root.after(self.SIM_TICK_MS, self._sim_tick)

    def _sim_tick(self):
        if not self.running or self.cpu is None:
            return
        try:
            for _ in range(self.SIM_BATCH):
                if self.cpu.halted:
                    break
                self.cpu.step()
        except Exception as e:  # noqa: BLE001
            self._log(f"Runtime error: {e}", "error")
            self.running = False
            self.btn_run.configure(text="Run (F9)")
            self.status_var.set("error")
            return
        self._refresh_state()
        if self.cpu.halted:
            self.running = False
            self.btn_run.configure(text="Run (F9)")
            self.status_var.set("halted")
            self._log("halted (jmp-to-self)", "info")
            return
        self.root.after(self.SIM_TICK_MS, self._sim_tick)

    # ---------------- Board callbacks ----------------

    def _on_sw_toggle(self):
        if self.cpu is not None:
            self.cpu.sw = self.board.get_sw()

    def _on_btn_press(self, name):
        if self.cpu is None:
            self._log("Assemble a program first before pressing buttons.",
                      "error")
            return
        try:
            self.cpu.press_button(name)
        except ValueError as e:
            self._log(str(e), "error")
            return
        self._refresh_state()

    # ---------------- Refresh ----------------

    def _refresh_state(self):
        if self.cpu is None:
            for v in self.reg_vars:
                v.set("0x00")
            self.pc_var.set("0x00")
            self.flag_var.set("V=0 C=0 N=0 Z=0")
            self.board.update_leds(0)
            self.board.update_7seg(0)
            self._refresh_memview()
            self.editor.tag_remove("pc_line", "1.0", "end")
            return

        for i in range(8):
            self.reg_vars[i].set(f"0x{self.cpu.R[i] & 0xFF:02X}")
        self.pc_var.set(f"0x{self.cpu.PC:02X}")
        self.flag_var.set(
            f"V={self.cpu.V} C={self.cpu.C} N={self.cpu.N} Z={self.cpu.Z}")
        self.board.update_leds(self.cpu.MR[2])
        self.board.update_7seg((self.cpu.MR[1] << 8) | self.cpu.MR[0])
        self._refresh_memview()
        self._highlight_pc_line()

    def _refresh_memview(self):
        self.memview.config(state="normal")
        self.memview.delete("1.0", "end")
        pc = self.cpu.PC if self.cpu else -1
        mem = self.cpu.mem if self.cpu else (self.words + [0]*(256-len(self.words)))
        mrs = self.cpu.MR if self.cpu else [0]*8
        for addr in range(256):
            w = mem[addr] if addr < len(mem) else 0
            dec = dsdasm.decode_insn(w)
            mn = f"{dec[0]:<4} {', '.join(dec[1])}" if dec else "     "
            line = f"{addr:02X}: {w:04X}  {mn}"
            tags = []
            if addr == pc:
                tags.append("pc_row")
            if addr >= 0xF8:
                tags.append("io_row")
                line = f"{addr:02X}: {mrs[addr-0xF8]:04X}  [MR{addr-0xF8}]"
            self.memview.insert("end", line + "\n", tuple(tags))
        if pc >= 0:
            self.memview.see(f"{pc+1}.0")
        self.memview.config(state="disabled")

    # ---------------- Console ----------------

    def _log(self, msg, tag="", link_line=None):
        self.console.config(state="normal")
        if link_line is not None:
            self.console.insert("end", f"line {link_line}: ",
                                (tag, "link", f"link_{link_line}"))
            rest = msg.split(":", 1)[-1].lstrip()
            self.console.insert("end", rest + "\n", (tag,))
        else:
            self.console.insert("end", msg + "\n", (tag,))
        self.console.see("end")
        self.console.config(state="disabled")

    def _on_console_link(self, event):
        idx = self.console.index(f"@{event.x},{event.y}")
        for t in self.console.tag_names(idx):
            if t.startswith("link_"):
                line = int(t.split("_", 1)[1])
                self.editor.mark_set("insert", f"{line}.0")
                self.editor.see(f"{line}.0")
                self.editor.focus_set()
                return

    def cmd_about(self):
        messagebox.showinfo(
            "About dsdasm",
            "dsdasm GUI\n"
            "Streamlined assembler / simulator for DSD 62711 PWF.\n\n"
            "Encoding matches the PWF spec and our PWB controller.\n"
            "Tkinter stdlib only -- no external dependencies.",
            parent=self.root)


def main():
    root = tk.Tk()
    try:
        root.call("tk", "scaling", 1.2)
    except tk.TclError:
        pass
    app = DsdasmGUI(root)
    if len(sys.argv) > 1 and Path(sys.argv[1]).is_file():
        app.cmd_open(sys.argv[1])
    root.mainloop()


if __name__ == "__main__":
    main()
