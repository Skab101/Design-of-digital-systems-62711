----------------------------------------------------------------------------------
-- Module Name: FunctionSelect
-- Description: Decodes FS3, FS2 into MF select signal
--              MF=0: select ALU output (FS3=0, or FS3=1 & FS2=0)
--              MF=1: select Shifter output (FS3=1 & FS2=1)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity FunctionSelect is
    Port (
        FS   : in  STD_LOGIC_vector(3 downto 0 );
        JSel : out STD_LOGIC_VECTOR(3 downto 0);
        HSel : out STD_LOGIC_VECTOR(3 downto 0);
        MF   : out STD_LOGIC
    );
end FunctionSelect;

architecture Structural of FunctionSelect is

    begin
MF <= FS(3) and Fs(2);
JSel(3 downto 0) <= FS(3 downto 0); 
HSel(1 downto 0) <= FS(1 downto 0);  

end Structural;
