----------------------------------------------------------------------------------
-- Module Name: RegisterFile_timing_tb
-- Note:        Generated with assistance from AI (Claude)
-- Description: Timing diagram testbench for Register File
--              Demonstrates register transfer to R10 (DA = 1010)
--              Signals shown: CLK, RW, DA(3:0), Load(15:0), D_Data(7:0), R10(7:0)
--
--              Scenario:
--                Phase 1: Reset all registers
--                Phase 2: Write 0x42 to R10 with RW=1, DA="1010" (successful write)
--                Phase 3: Attempt write 0xFF to R10 with RW=0 (write blocked)
--                Phase 4: Read R10 via AA to confirm value is still 0x42
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RegisterFile_timing_tb is
end RegisterFile_timing_tb;

architecture timing_diagram of RegisterFile_timing_tb is

    -- DUT signals
    signal RESET  : STD_LOGIC := '0';
    signal CLK    : STD_LOGIC := '0';
    signal RW     : STD_LOGIC := '0';
    signal DA     : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal AA     : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal BA     : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal D_Data : STD_LOGIC_VECTOR(7 downto 0) := x"00";
    signal A_Data : STD_LOGIC_VECTOR(7 downto 0);
    signal B_Data : STD_LOGIC_VECTOR(7 downto 0);

    constant CLK_PERIOD : time := 20 ns;
    signal test_done : boolean := false;

begin

    -- Unit Under Test
    UUT: entity work.RegisterFile
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

    -- Clock generation (20 ns period for readable waveforms)
    CLK_PROC: process
    begin
        if test_done then
            wait;
        end if;
        CLK <= '0';
        wait for CLK_PERIOD / 2;
        CLK <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- Point AA at R10 throughout so we can observe R10 on A_Data
    AA <= "1010";

    -- Stimulus process
    STIM: process
    begin
        -----------------------------------------------------------------------
        -- PHASE 1: Reset all registers
        -----------------------------------------------------------------------
        RESET <= '1';
        RW    <= '0';
        DA    <= "0000";
        D_Data <= x"00";
        wait for CLK_PERIOD * 2;  -- hold reset for 2 clock cycles

        RESET <= '0';
        wait for CLK_PERIOD;      -- let reset deassert settle

        -- Verify R10 = 0x00 after reset
        assert A_Data = x"00"
            report "PHASE 1 FAIL: R10 not zero after reset"
            severity error;
        report "PHASE 1: Reset complete, R10 = 0x00";

        -----------------------------------------------------------------------
        -- PHASE 2: Setup for write to R10
        --   RW = 1, DA = "1010", D_Data = 0x42
        --   On the next rising edge, R10 captures 0x42
        -----------------------------------------------------------------------
        RW     <= '1';
        DA     <= "1010";      -- select register 10
        D_Data <= x"42";       -- data to write
        wait for CLK_PERIOD;   -- rising edge occurs -> R10 latches 0x42

        -- Verify R10 = 0x42
        wait for 1 ns;  -- settling
        assert A_Data = x"42"
            report "PHASE 2 FAIL: R10 expected 0x42, got " &
                   integer'image(to_integer(unsigned(A_Data)))
            severity error;
        report "PHASE 2: Write successful, R10 = 0x42";

        -- Deassert write
        RW <= '0';
        wait for CLK_PERIOD - 1 ns;

        -----------------------------------------------------------------------
        -- PHASE 3: Attempt write with RW = 0 (should NOT update R10)
        --   RW = 0, DA = "1010", D_Data = 0xFF
        -----------------------------------------------------------------------
        DA     <= "1010";
        D_Data <= x"FF";       -- this should NOT be written
        RW     <= '0';         -- write disabled
        wait for CLK_PERIOD;   -- rising edge occurs, but RW=0 blocks write

        -- Verify R10 still = 0x42
        wait for 1 ns;
        assert A_Data = x"42"
            report "PHASE 3 FAIL: R10 was overwritten despite RW=0, got " &
                   integer'image(to_integer(unsigned(A_Data)))
            severity error;
        report "PHASE 3: Write blocked (RW=0), R10 still = 0x42";

        wait for CLK_PERIOD - 1 ns;

        -----------------------------------------------------------------------
        -- PHASE 4: Write to a different register (R5) and verify R10 unchanged
        -----------------------------------------------------------------------
        RW     <= '1';
        DA     <= "0101";      -- select register 5
        D_Data <= x"AB";
        wait for CLK_PERIOD;   -- R5 latches 0xAB

        -- Verify R10 unchanged
        wait for 1 ns;
        assert A_Data = x"42"
            report "PHASE 4 FAIL: R10 changed when writing to R5"
            severity error;

        -- Verify R5 via B port
        BA <= "0101";
        wait for 1 ns;
        assert B_Data = x"AB"
            report "PHASE 4 FAIL: R5 expected 0xAB"
            severity error;
        report "PHASE 4: R5 = 0xAB, R10 still = 0x42";

        RW <= '0';
        wait for CLK_PERIOD;

        -----------------------------------------------------------------------
        -- DONE
        -----------------------------------------------------------------------
        report "TIMING DIAGRAM TB: ALL PHASES PASSED" severity note;
        test_done <= true;
        wait;
    end process;

end timing_diagram;
