----------------------------------------------------------------------------------
-- Module Name: TOP_MODUL - Structural
-- Project:     PWA - ALU / DataPath
-- Board:       Nexys 4 DDR (Artix-7 xc7a100t)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TOP_MODUL is
    Port (
    -- Inputs
        CLK           : in STD_LOGIC;
        RW            : in STD_LOGIC;
        DA            : in STD_LOGIC_VECTOR(3 downto 0);
        AA            : in STD_LOGIC_VECTOR(3 downto 0);
        BA            : in STD_LOGIC_VECTOR(3 downto 0);
        Constant_int  : in STD_LOGIC;
        MB            : in STD_LOGIC_VECTOR(7 downto 0);
        FS            : in STD_LOGIC_VECTOR(3 downto 0);
        Data_In       : in STD_LOGIC_VECTOR(7 downto 0);
        MD            : in STD_LOGIC;
        
        
    -- Outputs
        Addr_out      : out STD_LOGIC_VECTOR(7 downto 0);
        Data_Out      : out STD_LOGIC_VECTOR(7 downto 0);
        V             : out STD_LOGIC;
        C             : out STD_LOGIC;
        N             : out STD_LOGIC;
        Z             : out STD_LOGIC
    );
end TOP_MODUL;

architecture Structural of TOP_MODUL is
begin
    -- Component declarations go here


process(CLK)
begin

    -- Component instantiations go here
end process; 
end Structural;
