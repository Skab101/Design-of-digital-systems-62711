----------------------------------------------------------------------------------
-- Module Name: MUX2x1x8
-- Description: 2-to-1 multiplexer, 8-bit wide
--              MUX_Select=0: Y = R
--              MUX_Select=1: Y = S
--              Used for MUXB, MUXD, and MUXF in the datapath
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MUX2x1x8 is
    Port (
        R, S       : in  STD_LOGIC_VECTOR(7 downto 0);
        MUX_Select : in  STD_LOGIC;
        Y          : out STD_LOGIC_VECTOR(7 downto 0)
    );
end MUX2x1x8;

architecture Structural of MUX2x1x8 is
begin

    Y <= (R AND (7 downto 0 => NOT MUX_Select)) OR
         (S AND (7 downto 0 => MUX_Select));

end Structural;
