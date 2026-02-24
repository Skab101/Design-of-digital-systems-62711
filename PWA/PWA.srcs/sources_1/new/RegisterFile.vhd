----------------------------------------------------------------------------------
-- Module Name: RegisterFile
-- Description: 16 x 8-bit Register File (RF)
--              Structural: instantiates DestinationDecoder, RegisterR16,
--              and two MUX16x1x8 (for A_Data and B_Data outputs)
--              RW + DA  -> selects which register to write
--              AA       -> selects register for A_Data output
--              BA       -> selects register for B_Data output
--              D_Data written on rising CLK edge when RW=1
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity RegisterFile is
    Port (
        RESET  : in  STD_LOGIC;
        CLK    : in  STD_LOGIC;
        RW     : in  STD_LOGIC;
        DA, AA, BA : in  STD_LOGIC_VECTOR(3 downto 0);
        D_Data : in  STD_LOGIC_VECTOR(7 downto 0);
        A_Data, B_Data : out STD_LOGIC_VECTOR(7 downto 0)
    );
end RegisterFile;

architecture structural of RegisterFile is

    component DestinationDecoder is
        Port (WRITE : in  STD_LOGIC;
              DA    : in  STD_LOGIC_VECTOR(3 downto 0);
              LOAD  : out STD_LOGIC_VECTOR(15 downto 0));
    end component;

    component RegisterR16 is
        Port (RESET  : in  STD_LOGIC;
              CLK    : in  STD_LOGIC;
              LOAD   : in  STD_LOGIC_VECTOR(15 downto 0);
              D_Data : in  STD_LOGIC_VECTOR(7 downto 0);
              R0, R1, R2, R3     : out STD_LOGIC_VECTOR(7 downto 0);
              R4, R5, R6, R7     : out STD_LOGIC_VECTOR(7 downto 0);
              R8, R9, R10, R11   : out STD_LOGIC_VECTOR(7 downto 0);
              R12, R13, R14, R15 : out STD_LOGIC_VECTOR(7 downto 0));
    end component;

    component MUX16x1x8 is
        Port (R0, R1, R2, R3     : in  STD_LOGIC_VECTOR(7 downto 0);
              R4, R5, R6, R7     : in  STD_LOGIC_VECTOR(7 downto 0);
              R8, R9, R10, R11   : in  STD_LOGIC_VECTOR(7 downto 0);
              R12, R13, R14, R15 : in  STD_LOGIC_VECTOR(7 downto 0);
              D_Select            : in  STD_LOGIC_VECTOR(3 downto 0);
              Y_Data              : out STD_LOGIC_VECTOR(7 downto 0));
    end component;

begin

end structural;
