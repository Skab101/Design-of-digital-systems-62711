----------------------------------------------------------------------------------
-- Module Name: full_adder
-- Description: Full adder from two half adders
--              S = X xor Y xor Ci,  Co = (X and Y) or (Ci and (X xor Y))
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity full_adder_1_bit is
    Port (
        A, B, Ci : in  STD_LOGIC;
        res      : out STD_LOGIC;
        co       : out STD_LOGIC
    );
end full_adder_1_bit;

architecture structural of full_adder_1_bit is
signal Pi, Gi : STD_LOGIC; 
begin

-- propagate and generate
Pi <= A xor B;
Gi <= A and B;

res <= Pi xor Ci; 
co <= (Pi and Ci) or Gi;  
end structural;
