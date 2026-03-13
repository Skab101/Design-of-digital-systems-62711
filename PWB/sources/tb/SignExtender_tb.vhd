library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity SignExtender_tb is
end SignExtender_tb;

architecture TB of SignExtender_tb is

    signal IR         : std_logic_vector(15 downto 0) := (others => '0');
    signal Extended_8 : std_logic_vector(7 downto 0);

begin

    UUT: entity work.SignExtender
        port map (
            IR         => IR,
            Extended_8 => Extended_8
        );

    stim_process: process
    begin
        -- IR(8)=0: positive sign extension
        -- IR(8)=0, IR(7)=1, IR(6)=1, IR(2:0)=111
        -- Expected: 000_11_111 = 0x1F
        IR <= "0000000011000111";
        wait for 10 ns;

        -- IR(8)=1: negative sign extension
        -- IR(8)=1, IR(7)=1, IR(6)=0, IR(2:0)=101
        -- Expected: 111_10_101 = 0xF5
        IR <= "0000000110000101";
        wait for 10 ns;

        -- IR(8)=0, all relevant bits 0
        -- Expected: 000_00_000 = 0x00
        IR <= "0000000000000000";
        wait for 10 ns;

        -- IR(8)=1, all relevant bits 1
        -- Expected: 111_11_111 = 0xFF
        IR <= "0000000111000111";
        wait for 10 ns;

        wait;
    end process;

end TB;
