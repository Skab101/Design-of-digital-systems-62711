----------------------------------------------------------------------------------
-- Module Name: FunctionUnit
-- Description: Function Unit - wraps ALU, Shifter, MUXF, and NegZero
--              FS3..FS0 control all operations (see FU table in spec)
--              Purely combinatorial (no process statements)
--              Outputs: F (8-bit result), V, C, N, Z (flags)
----------------------------------------------------------------------------------

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

architecture structural of FunctionUnit is

    component ALU is
        Port (A, B     : in  STD_LOGIC_VECTOR(7 downto 0);
              J_Select : in  STD_LOGIC_VECTOR(3 downto 0);
              V, C     : out STD_LOGIC;
              J        : out STD_LOGIC_VECTOR(7 downto 0));
    end component;

    component Shifter is
        Port (B        : in  STD_LOGIC_VECTOR(7 downto 0);
              H_Select : in  STD_LOGIC_VECTOR(1 downto 0);
              H        : out STD_LOGIC_VECTOR(7 downto 0));
    end component;

    component FunctionSelect is
        Port (FS3, FS2 : in  STD_LOGIC;
              MF       : out STD_LOGIC);
    end component;

    component MUX2x1x8 is
        Port (R, S       : in  STD_LOGIC_VECTOR(7 downto 0);
              MUX_Select : in  STD_LOGIC;
              Y          : out STD_LOGIC_VECTOR(7 downto 0));
    end component;

    component NegZero is
        Port (MUXF : in  STD_LOGIC_VECTOR(7 downto 0);
              N, Z : out STD_LOGIC);
    end component;

begin

end structural;
