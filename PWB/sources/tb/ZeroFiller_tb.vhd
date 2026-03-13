library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ZeroFiller_tb is
end ZeroFiller_tb;

architecture TB of ZeroFiller_tb is

    signal IR           : std_logic_vector(15 downto 0) := (others => '0');
    signal ZeroFilled_8 : std_logic_vector(7 downto 0);

begin

    UUT: entity work.ZeroFiller
        port map (
            IR           => IR,
            ZeroFilled_8 => ZeroFilled_8
        );

    stim_process: process
    begin
        -- IR(2:0) = 000 => ZeroFilled = 00000_000 = 0x00
        IR <= x"0000";
        wait for 10 ns;

        -- IR(2:0) = 101 => ZeroFilled = 00000_101 = 0x05
        IR <= x"0005";
        wait for 10 ns;

        -- IR(2:0) = 111 => ZeroFilled = 00000_111 = 0x07
        IR <= x"FFF7";
        wait for 10 ns;

        -- IR(2:0) = 011 => ZeroFilled = 00000_011 = 0x03
        IR <= x"1233";
        wait for 10 ns;

        wait;
    end process;

end TB;
