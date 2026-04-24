----------------------------------------------------------------------------------
-- Module Name: MUX2x1
-- Description: 2-to-1 multiplexer
--              MUX_Select=0: Y = Q
--              MUX_Select=1: Y = D
--              Used for 8bit parralel register in register file
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MUX2x1 is
    Port (
        D, Q       : in  STD_LOGIC;
        Enable     : in  STD_LOGIC;
        Y          : out STD_LOGIC
    );
end MUX2x1;

-- Denne arkitektur implementerer en 2-til-1 multiplexer i sin simpleste form via structural
architecture Structural of MUX2x1 is
begin
    Y <= (Q AND (not Enable)) OR
         (D AND Enable);
end Structural;
