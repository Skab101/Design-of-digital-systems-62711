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

architecture NegZero_Behavorial of NegZero is

signal ZeroCheck: STD_LOGIC_VECTOR(7 downto 0);
begin

N <= MUXF(7) AND '1';
Z <= NOT (  ZeroCheck(7) OR ZeroCheck(6) OR ZeroCheck(5)
OR ZeroCheck(4) OR ZeroCheck(3) OR ZeroCheck(2) OR 
ZeroCheck(1) OR ZeroCheck(0) ); 
 

end NegZero_Behavorial;
