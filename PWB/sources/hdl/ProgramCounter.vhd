library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ProgramCounter is
    port (
        RESET      : in  std_logic;
        CLK        : in  std_logic;
        Address_In : in  std_logic_vector(7 downto 0);
        PS         : in  std_logic_vector(1 downto 0);
        Offset     : in  std_logic_vector(7 downto 0);
        PC         : out std_logic_vector(7 downto 0)
    );
end ProgramCounter;

architecture PC_Behavorial of ProgramCounter is
begin

    -- TODO: Implement sequential process (CLK, RESET)
    -- PS=00: Hold,  PS=01: Increment,  PS=10: Branch,  PS=11: Jump

end PC_Behavorial;
