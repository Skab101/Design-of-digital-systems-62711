


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity FunctionUnit is
    Port (
        A, B                        : in  STD_LOGIC_VECTOR(7 downto 0);
        FS3, FS2, FS1, FS0, Cin     : in  STD_LOGIC;
        V, C, N, Z                  : out STD_LOGIC;
        F                           : out STD_LOGIC_VECTOR(7 downto 0)
    );
end FunctionUnit;   

architecture FU_Structural of FunctionUnit is

signal MFsig: STD_LOGIC;
signal FS: STD_LOGIC_VECTOR(3 downto 0);
signal Res, HSig, Jsig: STD_LOGIC_VECTOR(7 downto 0);

begin
FS <= FS3 & FS2 & FS1 & FS0;
F <= Res;

U_ALU: entity work.ALU
port map(
    A => A,
    B => B,
    JSel => FS(3 downto 0),
    V => V,
    C => C,
    Cin => Cin, ---------------------------- evalueres "Cin => FS0"? -----------------------------
    J => JSig
);

U_Shifter: entity work.Shifter
port map(
    B => B,
    HSel => FS(1 downto 0),
    H => HSig
);

U_FunctionSelect: entity work.FunctionSelect
port map(
    FS => FS,
    MF => MFsig
);

U_MUXF: entity work.MUX2x1x8
port map(
    J => JSig,
    H => HSig,
    MF => MFsig,
    Y => Res
);

U_NegZero: entity work.NegZero
port map(
    MUXF => Res,
    N => N,
    Z => Z
);
end FU_Structural;
