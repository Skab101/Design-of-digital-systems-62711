----------------------------------------------------------------------------------
-- Module Name: arithmetic
-- Description: n-bit arithmetic circuit (Table 8.1, internal ALU sub-block)
--              Uses b_logic + full_adder with for...generate
--              Operations selected by S1, S0, Cin:
--                000: Transfer A    001: Increment A
--                010: A + B         011: A + B + 1
--                100: A + B'        101: A - B
--                110: A - 1         111: Transfer A
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity arithmetic is
    generic (n : integer := 8);
    Port (
        A, B       : in  STD_LOGIC_VECTOR(n-1 downto 0);
        S0, S1     : in  STD_LOGIC;
        Cin        : in  STD_LOGIC;
        G          : out STD_LOGIC_VECTOR(n-1 downto 0);
        Cout       : out STD_LOGIC;
        overflow   : out STD_LOGIC
    );
end arithmetic;

architecture structural of arithmetic is

    component b_logic is
        Port (B, S0, S1 : in  STD_LOGIC;
              Y         : out STD_LOGIC);
    end component;

    component full_adder_1_bit is
        Port (A, B, Ci : in  STD_LOGIC;
              res, co  : out STD_LOGIC);
    end component;

begin

end structural;
