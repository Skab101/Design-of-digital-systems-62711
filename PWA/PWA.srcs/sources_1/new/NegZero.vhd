----------------------------------------------------------------------------------
-- Module Name: NegZero
-- Description: Computes N and Z flags from the FU output
--              N = MUXF(7)               (sign bit / negative)
--              Z = NOR of all MUXF bits  (high when result is zero)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity NegZero is
    Port (
        MUXF : in  STD_LOGIC_VECTOR(7 downto 0);
        N, Z : out STD_LOGIC
    );
end NegZero;

architecture dataflow of NegZero is
begin

end dataflow;
