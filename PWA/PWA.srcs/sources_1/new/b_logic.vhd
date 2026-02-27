----------------------------------------------------------------------------------
-- Module Name: b_logic
-- Description: B input logic for one bit of the arithmetic circuit (Figure 8-4)
--              Selects Y based on S1, S0:
--                S1 S0 | Y
--                 0  0 | 0        (all zeros)
--                 0  1 | B        (pass-through)
--                 1  0 | not B    (complement)
--                 1  1 | 1        (all ones)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity logic is
    Port (
        B      : in  STD_LOGIC;
        J0, J1 : in  STD_LOGIC;
        Y      : out STD_LOGIC
    );
end b_logic;

architecture dataflow of b_logic is
begin




end dataflow;
