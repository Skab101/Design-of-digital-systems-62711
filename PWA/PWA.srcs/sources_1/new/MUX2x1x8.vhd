----------------------------------------------------------------------------------
-- Module Name: MUX2x1x8
-- Description: 2-to-1 multiplexer, 8-bit wide
--              MUX_Select=0: Y = R
--              MUX_Select=1: Y = S
--              Used for MUXB, MUXD, and MUXF in the datapath
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MUXF is
    Port (
        J, H       : in  STD_LOGIC_VECTOR(7 downto 0);
        MF         : in  STD_LOGIC;
        Y          : out STD_LOGIC_VECTOR(7 downto 0)
    );
end MUXF;

architecture Structural of MUXF is
begin

    Y <= (J AND (others => NOT MF)) OR
         (H AND (others => MF));


end Structural;
