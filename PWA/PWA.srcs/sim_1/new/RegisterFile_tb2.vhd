----------------------------------------------------------------------------------
-- Module Name: RegisterFile_tb2
-- Description: Self-checking testbench for the 16x8-bit Register File
--              Tests:
--                1) Reset clears all registers
--                2) Write unique values to all 16 registers and read back
--                3) RW=0 prevents writing
--                4) Simultaneous read of two different registers (A and B)
--                5) Overwrite a register with a new value
--                6) Reset mid-operation clears all registers
--                7) Data is only captured on the rising CLK edge
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RegisterFile_tb2 is
end RegisterFile_tb2;

architecture testbench of RegisterFile_tb2 is

    signal RESET  : STD_LOGIC := '0';
    signal CLK    : STD_LOGIC := '0';
    signal RW     : STD_LOGIC := '0';
    signal DA     : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal AA     : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal BA     : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal D_Data : STD_LOGIC_VECTOR(7 downto 0) := x"00";
    signal A_Data : STD_LOGIC_VECTOR(7 downto 0);
    signal B_Data : STD_LOGIC_VECTOR(7 downto 0);

    constant CLK_PERIOD : time := 10 ns;
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

    -- Clock generation, stops when test_done is set
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

    STIM: process
    begin

        -----------------------------------------------------------------------
        -- TEST 1: Reset clears all registers
        -----------------------------------------------------------------------
        report "TEST 1: Reset clears all registers";
        RESET <= '1';
        wait for CLK_PERIOD * 2;
        RESET <= '0';
        wait for CLK_PERIOD;

        -- Read all 16 registers and verify they are zero
        for i in 0 to 15 loop
            AA <= std_logic_vector(to_unsigned(i, 4));
            BA <= std_logic_vector(to_unsigned(i, 4));
            wait for 1 ns; -- combinational settling time for MUX
            assert A_Data = x"00"
                report "TEST 1 FAIL: R" & integer'image(i) &
                       " A_Data /= 0x00 after reset, got " &
                       integer'image(to_integer(unsigned(A_Data)))
                severity error;
            assert B_Data = x"00"
                report "TEST 1 FAIL: R" & integer'image(i) &
                       " B_Data /= 0x00 after reset"
                severity error;
        end loop;
        report "TEST 1 PASSED";
        wait for CLK_PERIOD;

        -----------------------------------------------------------------------
        -- TEST 2: Write unique values to all 16 registers and read back
        -----------------------------------------------------------------------
        report "TEST 2: Write to all 16 registers and verify";
        RW <= '1';
        for i in 0 to 15 loop
            DA     <= std_logic_vector(to_unsigned(i, 4));
            D_Data <= std_logic_vector(to_unsigned(10 + i*13, 8));  -- unique values: 10, 23, 36 ...
            wait for CLK_PERIOD;  -- value captured on rising edge
        end loop;
        RW <= '0';

        -- Read all registers back via A port and verify
        for i in 0 to 15 loop
            AA <= std_logic_vector(to_unsigned(i, 4));
            wait for 1 ns;
            assert A_Data = std_logic_vector(to_unsigned(10 + i*13, 8))
                report "TEST 2 FAIL: R" & integer'image(i) &
                       " expected " & integer'image(10 + i*13) &
                       " got " & integer'image(to_integer(unsigned(A_Data)))
                severity error;
        end loop;

        -- Read all registers via B port and verify
        for i in 0 to 15 loop
            BA <= std_logic_vector(to_unsigned(i, 4));
            wait for 1 ns;
            assert B_Data = std_logic_vector(to_unsigned(10 + i*13, 8))
                report "TEST 2 FAIL: R" & integer'image(i) &
                       " B_Data expected " & integer'image(10 + i*13) &
                       " got " & integer'image(to_integer(unsigned(B_Data)))
                severity error;
        end loop;
        report "TEST 2 PASSED";
        wait for CLK_PERIOD;

        -----------------------------------------------------------------------
        -- TEST 3: RW=0 prevents writing
        -----------------------------------------------------------------------
        report "TEST 3: RW=0 blocks writing";
        -- R0 holds value 10 from test 2, attempt to overwrite with 0xFF
        RW     <= '0';
        DA     <= "0000";
        D_Data <= x"FF";
        wait for CLK_PERIOD;

        AA <= "0000";
        wait for 1 ns;
        assert A_Data = std_logic_vector(to_unsigned(10, 8))
            report "TEST 3 FAIL: R0 was overwritten despite RW=0, got " &
                   integer'image(to_integer(unsigned(A_Data)))
            severity error;
        report "TEST 3 PASSED";
        wait for CLK_PERIOD;

        -----------------------------------------------------------------------
        -- TEST 4: Simultaneous read of two different registers
        -----------------------------------------------------------------------
        report "TEST 4: Simultaneous read of A and B from different registers";
        -- R3 = 10+3*13 = 49, R12 = 10+12*13 = 166
        AA <= "0011";   -- read R3
        BA <= "1100";   -- read R12
        wait for 1 ns;
        assert A_Data = std_logic_vector(to_unsigned(49, 8))
            report "TEST 4 FAIL: A_Data(R3) expected 49, got " &
                   integer'image(to_integer(unsigned(A_Data)))
            severity error;
        assert B_Data = std_logic_vector(to_unsigned(166, 8))
            report "TEST 4 FAIL: B_Data(R12) expected 166, got " &
                   integer'image(to_integer(unsigned(B_Data)))
            severity error;

        -- Test boundary registers: R0=10, R15=10+15*13=205
        AA <= "0000";
        BA <= "1111";
        wait for 1 ns;
        assert A_Data = std_logic_vector(to_unsigned(10, 8))
            report "TEST 4 FAIL: A_Data(R0) expected 10"
            severity error;
        assert B_Data = std_logic_vector(to_unsigned(205, 8))
            report "TEST 4 FAIL: B_Data(R15) expected 205"
            severity error;
        report "TEST 4 PASSED";
        wait for CLK_PERIOD;

        -----------------------------------------------------------------------
        -- TEST 5: Overwrite a register and verify neighbours are unaffected
        -----------------------------------------------------------------------
        report "TEST 5: Overwrite R7 with new value";
        -- R7 = 10+7*13 = 101, overwrite with 0xAB = 171
        RW     <= '1';
        DA     <= "0111";
        D_Data <= x"AB";
        wait for CLK_PERIOD;
        RW <= '0';

        AA <= "0111";
        wait for 1 ns;
        assert A_Data = x"AB"
            report "TEST 5 FAIL: R7 expected 0xAB after overwrite, got " &
                   integer'image(to_integer(unsigned(A_Data)))
            severity error;

        -- Verify neighbour R6 was not affected (R6 = 10+6*13 = 88)
        AA <= "0110";
        wait for 1 ns;
        assert A_Data = std_logic_vector(to_unsigned(88, 8))
            report "TEST 5 FAIL: R6 was unintentionally modified"
            severity error;

        -- Verify neighbour R8 was not affected (R8 = 10+8*13 = 114)
        AA <= "1000";
        wait for 1 ns;
        assert A_Data = std_logic_vector(to_unsigned(114, 8))
            report "TEST 5 FAIL: R8 was unintentionally modified"
            severity error;
        report "TEST 5 PASSED";
        wait for CLK_PERIOD;

        -----------------------------------------------------------------------
        -- TEST 6: Reset mid-operation clears everything
        -----------------------------------------------------------------------
        report "TEST 6: Reset mid-operation";
        RESET <= '1';
        wait for CLK_PERIOD;
        RESET <= '0';
        wait for CLK_PERIOD;

        -- All registers should be zero again
        for i in 0 to 15 loop
            AA <= std_logic_vector(to_unsigned(i, 4));
            wait for 1 ns;
            assert A_Data = x"00"
                report "TEST 6 FAIL: R" & integer'image(i) &
                       " /= 0x00 after mid-operation reset"
                severity error;
        end loop;
        report "TEST 6 PASSED";
        wait for CLK_PERIOD;

        -----------------------------------------------------------------------
        -- TEST 7: Data is only captured on the rising CLK edge
        -----------------------------------------------------------------------
        report "TEST 7: Data captured only on rising edge";
        -- Write 0xCC to R5, synchronized to clock
        RW     <= '1';
        DA     <= "0101";
        D_Data <= x"CC";
        wait until rising_edge(CLK);    -- 0xCC captured here
        wait for 1 ns;
        RW <= '0';

        -- Verify 0xCC was written
        AA <= "0101";
        wait for 1 ns;
        assert A_Data = x"CC"
            report "TEST 7 FAIL: R5 expected 0xCC"
            severity error;

        -- Sync to falling edge so we know exactly where we are in the cycle
        wait until falling_edge(CLK);
        -- Now the next rising edge is CLK_PERIOD/2 = 5 ns away
        RW     <= '1';
        DA     <= "0101";
        D_Data <= x"DD";               -- initial value during low phase
        wait for 1 ns;
        D_Data <= x"EE";               -- change data, still in low phase
        wait for 1 ns;
        D_Data <= x"99";               -- final value, 3 ns before rising edge
        wait until rising_edge(CLK);    -- 0x99 is captured here
        wait for 1 ns;
        RW <= '0';

        AA <= "0101";
        wait for 1 ns;
        assert A_Data = x"99"
            report "TEST 7 FAIL: R5 expected 0x99 (value at rising edge), got " &
                   integer'image(to_integer(unsigned(A_Data)))
            severity error;
        report "TEST 7 PASSED";

        -----------------------------------------------------------------------
        -- DONE
        -----------------------------------------------------------------------
        report "ALL TESTS PASSED" severity note;
        test_done <= true;
        wait;
    end process;

end testbench;
