----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03.03.2026 11:52:30
-- Design Name: 
-- Module Name: Register_file_sim - Behavioral
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
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Register_file_sim is
end Register_file_sim;

architecture sim of Register_file_sim is

    -- Signaler til at forbinde til RegisterFile
    signal RESET  : std_logic := '0';
    signal CLK    : std_logic := '0';
    signal RW     : std_logic := '0';
    signal DA     : std_logic_vector(3 downto 0) := (others => '0');
    signal AA     : std_logic_vector(3 downto 0) := (others => '0');
    signal BA     : std_logic_vector(3 downto 0) := (others => '0');
    signal D_Data : std_logic_vector(7 downto 0) := (others => '0');
    signal A_Data : std_logic_vector(7 downto 0);
    signal B_Data : std_logic_vector(7 downto 0);

begin

    -- DUT: instans af RegisterFile
    DUT: entity work.RegisterFile
        port map (
            RESET  => RESET,
            CLK    => CLK,
            RW     => RW,
            DA     => DA,
            AA     => AA,
            BA     => BA,
            D_Data => D_Data,
            A_Data => A_Data,
            B_Data => B_Data
        );

    -- Clock-proces: 20 ns periode
    clk_proc : process
    begin
        CLK <= '0';
        wait for 10 ns;
        CLK <= '1';
        wait for 10 ns;
    end process;

    -- Stimuli-proces
    stim_proc : process
    begin
        -- 1) Reset
        RESET <= '1';
        wait for 30 ns;
        RESET <= '0';

        -- 2) Skriv 0x3C til R3
        RW     <= '1';
        DA     <= "0011";
        D_Data <= x"3C";
        wait for 40 ns;  -- dækker mindst én rising edge

        -- 3) Læs R3 på A og B
        RW <= '0';
        AA <= "0011";
        BA <= "0011";
        wait for 40 ns;

        -- 4) Skriv 0xA5 til R5 og læs både R3 og R5
        RW     <= '1';
        DA     <= "0101";
        D_Data <= x"A5";
        wait for 40 ns;

        RW <= '0';
        AA <= "0101";   -- A læser R5
        BA <= "0011";   -- B læser stadig R3
        wait for 40 ns;

        -- 5) Stop simulationen
        wait;
    end process;

end sim;
