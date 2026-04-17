----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.04.2026 13:32:41
-- Design Name: 
-- Module Name: Zero_Filler_2 - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Zero_Filler_2 is
    Port ( Data_Out : in STD_LOGIC_VECTOR (7 downto 0);
           Data_ZF :  out STD_LOGIC_VECTOR (15 downto 0));
end Zero_Filler_2;

architecture Behavioral of Zero_Filler_2 is

begin
    Data_ZF <=  (15 downto 8 => '0') & -- 5 nuller
                 Data_Out(7 downto 0); --LSB af IR

end Behavioral;
