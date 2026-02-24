----------------------------------------------------------------------------------
-- Module Name: Shifter
-- Description: 8-bit barrel shifter (combinatorial)
--              H_Select controls the operation:
--                00: H = B          (pass-through)
--                01: H = sr B       (shift right, MSB=0)
--                10: H = sl B       (shift left, LSB=0)
--                11: H = B          (pass-through)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Shifter is
    Port (
        B        : in  STD_LOGIC_VECTOR(7 downto 0);
        H_Select : in  STD_LOGIC_VECTOR(1 downto 0);
        H        : out STD_LOGIC_VECTOR(7 downto 0)
    );
end Shifter;

architecture dataflow of Shifter is
begin

end dataflow;
