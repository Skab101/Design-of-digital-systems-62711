library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ProgramCounter_tb is
end ProgramCounter_tb;

architecture TB of ProgramCounter_tb is

    signal RESET      : std_logic := '1';
    signal CLK        : std_logic := '0';
    signal Address_In : std_logic_vector(7 downto 0) := (others => '0');
    signal PS         : std_logic_vector(1 downto 0) := "00";
    signal Offset     : std_logic_vector(7 downto 0) := (others => '0');
    signal CarryO     : std_logic;
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
            CarryO     => CarryO,
            PC         => PC
        );

    -- Clock generation
    clk_process: process
    begin
        CLK <= '0'; wait for CLK_PERIOD / 2;
        CLK <= '1'; wait for CLK_PERIOD / 2;
    end process;

    stim_process: process
    begin
        -- ============================================
        -- RESET: PC should go to 0
        -- ============================================
        RESET <= '1';
        PS <= "00";
        wait for CLK_PERIOD * 2;
        RESET <= '0';
        wait for CLK_PERIOD;
        assert PC = x"00"
            report "RESET failed: PC should be 00, got " & integer'image(to_integer(unsigned(PC)))
            severity error;

        -- ============================================
        -- TEST 1: PS=00 (Hold) - PC should stay at 0
        -- ============================================
        PS <= "00";
        wait for CLK_PERIOD;
        assert PC = x"00"
            report "HOLD failed: PC should be 00, got " & integer'image(to_integer(unsigned(PC)))
            severity error;

        wait for CLK_PERIOD;
        assert PC = x"00"
            report "HOLD (2nd cycle) failed: PC should be 00, got " & integer'image(to_integer(unsigned(PC)))
            severity error;

        -- ============================================
        -- TEST 2: PS=01 (Increment) - PC should count up
        -- ============================================
        PS <= "01";
        wait for CLK_PERIOD;
        assert PC = x"01"
            report "INCREMENT 1 failed: PC should be 01, got " & integer'image(to_integer(unsigned(PC)))
            severity error;

        wait for CLK_PERIOD;
        assert PC = x"02"
            report "INCREMENT 2 failed: PC should be 02, got " & integer'image(to_integer(unsigned(PC)))
            severity error;

        wait for CLK_PERIOD;
        assert PC = x"03"
            report "INCREMENT 3 failed: PC should be 03, got " & integer'image(to_integer(unsigned(PC)))
            severity error;

        -- Hold after increment to verify value stays
        PS <= "00";
        wait for CLK_PERIOD;
        assert PC = x"03"
            report "HOLD after INCREMENT failed: PC should be 03, got " & integer'image(to_integer(unsigned(PC)))
            severity error;

        -- ============================================
        -- TEST 3: PS=11 (Jump) - PC should load Address_In
        -- ============================================
        Address_In <= x"42";
        PS <= "11";
        wait for CLK_PERIOD;
        assert PC = x"42"
            report "JUMP failed: PC should be 42 (66), got " & integer'image(to_integer(unsigned(PC)))
            severity error;

        -- Hold after jump
        PS <= "00";
        wait for CLK_PERIOD;
        assert PC = x"42"
            report "HOLD after JUMP failed: PC should be 42 (66), got " & integer'image(to_integer(unsigned(PC)))
            severity error;

        -- ============================================
        -- TEST 4: PS=10 (Branch) - PC + positive Offset
        -- PC=0x42, Offset=0x05 => PC should be 0x47
        -- ============================================
        Offset <= x"05";
        PS <= "10";
        wait for CLK_PERIOD;
        assert PC = x"47"
            report "BRANCH +5 failed: PC should be 47 (71), got " & integer'image(to_integer(unsigned(PC)))
            severity error;

        -- Hold after branch
        PS <= "00";
        wait for CLK_PERIOD;
        assert PC = x"47"
            report "HOLD after BRANCH failed: PC should be 47 (71), got " & integer'image(to_integer(unsigned(PC)))
            severity error;

        -- ============================================
        -- TEST 5: PS=10 (Branch) - negative Offset (two's complement)
        -- PC=0x47, Offset=0xFD (-3) => PC should be 0x44
        -- ============================================
        Offset <= x"FD";
        PS <= "10";
        wait for CLK_PERIOD;
        assert PC = x"44"
            report "BRANCH -3 failed: PC should be 44 (68), got " & integer'image(to_integer(unsigned(PC)))
            severity error;

        PS <= "00";
        wait for CLK_PERIOD;

        -- ============================================
        -- TEST 6: Jump to 0xFF, increment to test wrap-around
        -- ============================================
        Address_In <= x"FF";
        PS <= "11";
        wait for CLK_PERIOD;
        assert PC = x"FF"
            report "JUMP to FF failed: got " & integer'image(to_integer(unsigned(PC)))
            severity error;

        PS <= "01";
        wait for CLK_PERIOD;
        assert PC = x"00"
            report "INCREMENT wrap-around failed: PC should be 00, got " & integer'image(to_integer(unsigned(PC)))
            severity error;

        -- ============================================
        -- Done
        -- ============================================
        report "=== All ProgramCounter tests completed ===" severity note;
        wait;
    end process;

end TB;
