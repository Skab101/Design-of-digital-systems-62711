


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity FunctionUnit is
    Port (
        A, B                   : in  STD_LOGIC_VECTOR(7 downto 0);
        FS3, FS2, FS1, FS0     : in  STD_LOGIC;
        V, C, N, Z             : out STD_LOGIC;
        F                      : out STD_LOGIC_VECTOR(7 downto 0)
    );
end FunctionUnit;

architecture FU_Behavorial of FunctionUnit is
--mangler
 --   component ALU is
   --     Port (A, B     : in  STD_LOGIC_VECTOR(7 downto 0);
     --         JSel : in  STD_LOGIC_VECTOR(3 downto 0);
       --       V, C     : out STD_LOGIC;
         --     J        : out STD_LOGIC_VECTOR(7 downto 0));
    -- end component;

signal MFsig, Res: STD_LOGIC;

begin
U_Shifter: entity work.Shifter
port map(
    B => B,
    HSel => FS(1 downto 0),
    H => F
);

U_FunctionSelect: entity work.FunctionSelect
port map(
    FS => FS,
    JSel => FS(3 downto 0),
    HSel => FS(1 downto 0),
    MF => MFsig
);

U_MUXF: entity work.MUXF
port map(
    J => F,
    H => F,
    MF => MFsig,
    Y => Res
);

U_NegZero: entity work.NegZero
port map(
    MUXF => Res,
    N => N,
    Z => Z
);
end FU_Behavorial;
