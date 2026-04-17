----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.04.2026 13:22:00
-- Design Name: 
-- Module Name: MUX_M - Behavioral
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



entity MUX_M is
    Port ( Address_Out_MUXB : in STD_LOGIC_VECTOR (15 downto 0);
           Address_Out_PC : in STD_LOGIC_VECTOR (15 downto 0);
           MM : in STD_LOGIC;
           Address : out STD_LOGIC_VECTOR (15 downto 0));
end MUX_M;

architecture Behavioral of MUX_M is

begin

Address <= (Address_Out_MUXB AND     (15 downto 0 => MM) ) OR 
           (Address_Out_PC   AND  NOT(15 downto 0 => MM) );
end Behavioral;
