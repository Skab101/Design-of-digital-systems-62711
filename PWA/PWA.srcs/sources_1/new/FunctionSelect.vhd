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
        FS3, FS2 : in  STD_LOGIC;
        MF       : out STD_LOGIC
    );
end FunctionSelect;

architecture dataflow of FunctionSelect is
begin

end dataflow;
