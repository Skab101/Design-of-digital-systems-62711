----------------------------------------------------------------------------------
-- Module Name: MUX2x1x8
-- Description: 2-to-1 multiplexer, 8-bit wide
--              MF=0: Y = J
--              MF=1: Y = H
--              Used for MUXB, MUXD, and MUXF in the datapath
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MUX2x1x8 is
    Port (
        J, H       : in  STD_LOGIC_VECTOR(7 downto 0);
        MF         : in  STD_LOGIC;
        Y          : out STD_LOGIC_VECTOR(7 downto 0)
    );
end MUX2x1x8;

architecture Structural of MUX2x1x8 is
begin

    Y <= (J AND (7 downto 0 => NOT MF)) OR
         (H AND (7 downto 0 => MF));

end Structural;
