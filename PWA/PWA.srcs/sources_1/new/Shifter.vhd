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
        HSel     : in  STD_LOGIC_VECTOR(1 downto 0);
        H        : out STD_LOGIC_VECTOR(7 downto 0)
    );
end Shifter;


architecture Shifter_Behavorial of Shifter is
signal sl, sr, HTemp: STD_LOGIC;
signal slB, srB: STD_LOGIC_VECTOR(7 downto 0);

begin
 -- Styresignal til hvilket shift skal udføres
 HTemp <= HSel(1) XOR HSel(0);

 -- Enable signal for shift operations
 sl <= HSel(1) AND Htemp;
 sr <= HSel(0) AND Htemp;

 -- Shift operationer
 srB(6 downto 0) <= B(7 downto 1);
 srB(7) <= '0';
 slB(7 downto 1) <= B(6 downto 0);
 slB(0) <= '0';

 -- Resultat baseret på H_Select
H <= (srB and (7 downto 0 => sr)) or -- (7 downto 0 => sr) kopierer værdien af sr til en 8-bit vektor
     (slB and (7 downto 0 => sl)) or -- (7 downto 0 => sl) kopierer værdien af sl til en 8-bit vektor
     (B   and (7 downto 0 => not HTemp)); -- (7 downto 0 => not Htemp) inverter og kopierer værdien af Htemp til en 8-bit vektor

end Shifter_Behavorial;