library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Edge_Detector_CLK is
    port (
        Clk      : in  std_logic;
        PS       : in  STD_LOGIC_VECTOR(1 downto 0);
        PSsig    : out STD_LOGIC_VECTOR(1 downto 0)
        );
end Edge_Detector_CLK;

architecture Edge_Behavioral of Edge_Detector_CLK is
signal QCLK: STD_LOGIC;

begin
process ( Clk ) 
begin
if rising_edge ( Clk ) then

QCLK <= Clk ;

end if;

end process ;

PSsig(0) <= QCLK and ( not PS(0) );
PSsig(1) <= QCLK and ( not PS(1) );
end Edge_Behavioral;
