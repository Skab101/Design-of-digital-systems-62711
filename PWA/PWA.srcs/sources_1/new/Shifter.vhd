
----------------------------------------------------------------------------------
-- Module Name: Shifter
-- Description: 8-bit barrel shifter (combinatorial)
--              HSel controls the operation:
--                00: H = B          (pass-through)
--                01: H = sr B       (shift right, MSB=0)
--                10: H = sl B       (shift left, LSB=0)
--                11: H = B          (pass-through)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Shifter is
    Port (
        B    : in  STD_LOGIC_VECTOR(7 downto 0);
        HSel : in  STD_LOGIC_VECTOR(1 downto 0);
        H    : out STD_LOGIC_VECTOR(7 downto 0)
    );
end Shifter;

architecture Shifter_Behavioral of Shifter is

    signal HTemp : STD_LOGIC;
    signal sl, sr : STD_LOGIC;
    signal slB, srB : STD_LOGIC_VECTOR(7 downto 0);

begin

    -- Control signal defining which shift is active
    HTemp <= HSel(1) XOR HSel(0);

    -- Enable signals
    sl <= HSel(1) AND HTemp;
    sr <= HSel(0) AND HTemp;

    -- Right shift (LSB moves toward right, MSB=0)
    srB(6 downto 0) <= B(7 downto 1);
    srB(7)          <= '0';

    -- Left shift (MSB moves toward left, LSB=0)
    slB(7 downto 1) <= B(6 downto 0);
    slB(0)          <= '0';

    -- Output selection logic
    H <= (srB AND (7 downto 0 => sr)) OR
         (slB AND (7 downto 0 => sl)) OR
         (B   AND (7 downto 0 => NOT HTemp));

end Shifter_Behavioral;
