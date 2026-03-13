library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ProgramCounter_tb is
end ProgramCounter_tb;

architecture TB of ProgramCounter_tb is

    signal RESET      : std_logic := '1';
    signal CLK        : std_logic := '0';
    signal Address_In : std_logic_vector(7 downto 0) := (others => '0');
    signal PS         : std_logic_vector(1 downto 0) := "00";
    signal Offset     : std_logic_vector(7 downto 0) := (others => '0');
    signal PC         : std_logic_vector(7 downto 0);

    constant CLK_PERIOD : time := 10 ns;

begin

    UUT: entity work.ProgramCounter
        port map (
            RESET      => RESET,
            CLK        => CLK,
            Address_In => Address_In,
            PS         => PS,
            Offset     => Offset,
            PC         => PC
        );

    clk_process: process
    begin
        CLK <= '0'; wait for CLK_PERIOD / 2;
        CLK <= '1'; wait for CLK_PERIOD / 2;
    end process;

    stim_process: process
    begin
        -- Reset
        RESET <= '1';
        wait for CLK_PERIOD * 2;
        RESET <= '0';

        -- PS=00: Hold (PC should stay 0)
        PS <= "00";
        wait for CLK_PERIOD * 2;

        -- PS=01: Increment (PC should go 1, 2, 3)
        PS <= "01";
        wait for CLK_PERIOD * 3;

        -- PS=00: Hold (PC should stay at 3)
        PS <= "00";
        wait for CLK_PERIOD;

        -- PS=10: Branch with Offset=5 (PC should be 3+5=8)
        Offset <= x"05";
        PS <= "10";
        wait for CLK_PERIOD;

        -- PS=00: Hold
        PS <= "00";
        wait for CLK_PERIOD;

        -- PS=10: Branch with negative Offset (-3 = 0xFD) (PC should be 8-3=5)
        Offset <= x"FD";
        PS <= "10";
        wait for CLK_PERIOD;

        -- PS=00: Hold
        PS <= "00";
        wait for CLK_PERIOD;

        -- PS=11: Jump to address 0x42 (PC should be 0x42)
        Address_In <= x"42";
        PS <= "11";
        wait for CLK_PERIOD;

        -- PS=00: Hold
        PS <= "00";
        wait for CLK_PERIOD * 2;

        wait;
    end process;

end TB;
