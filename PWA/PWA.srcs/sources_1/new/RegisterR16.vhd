----------------------------------------------------------------------------------
-- Module Name: RegisterR16
-- Description: 16 x 8-bit register block
--              LOAD(15:0) selects which register captures D_Data on CLK edge
--              All 16 register outputs exposed (R0..R15)
--              Built structurally from flip_flop using for...generate
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity RegisterR16 is
    Port (
        RESET  : in  STD_LOGIC;
        CLK    : in  STD_LOGIC;
        LOAD   : in  STD_LOGIC_VECTOR(15 downto 0);
        D_Data : in  STD_LOGIC_VECTOR(7 downto 0);
        R0, R1, R2, R3     : out STD_LOGIC_VECTOR(7 downto 0);
        R4, R5, R6, R7     : out STD_LOGIC_VECTOR(7 downto 0);
        R8, R9, R10, R11   : out STD_LOGIC_VECTOR(7 downto 0);
        R12, R13, R14, R15 : out STD_LOGIC_VECTOR(7 downto 0)
    );
end RegisterR16;

architecture structural of RegisterR16 is

    component flip_flop is
        Port (D, Reset, load, clk : in  STD_LOGIC;
              Q                   : out STD_LOGIC);
    end component;

begin

end structural;
