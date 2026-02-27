----------------------------------------------------------------------------------
-- Module Name: RegisterFile_tb
-- Description: Testbench for the 16x8-bit Register File
--              Tests: reset, write to individual registers, read via AA/BA,
--              write-disable (RW=0), simultaneous read of two different registers
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RegisterFile_tb is
end RegisterFile_tb;

architecture testbench of RegisterFile_tb is

    component RegisterFile is
        Port (
            RESET  : in  STD_LOGIC;
            CLK    : in  STD_LOGIC;
            RW     : in  STD_LOGIC;
            DA, AA, BA : in  STD_LOGIC_VECTOR(3 downto 0);
            D_Data : in  STD_LOGIC_VECTOR(7 downto 0);
            A_Data, B_Data : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

    signal RESET  : STD_LOGIC := '0';
    signal CLK    : STD_LOGIC := '0';
    signal RW     : STD_LOGIC := '0';
    signal DA     : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal AA     : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal BA     : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal D_Data : STD_LOGIC_VECTOR(7 downto 0) := "00000000";
    signal A_Data : STD_LOGIC_VECTOR(7 downto 0);
    signal B_Data : STD_LOGIC_VECTOR(7 downto 0);

    constant CLK_PERIOD : time := 10 ns;

begin

    -- Unit Under Test
    UUT: RegisterFile port map (
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

    -- Clock generation
    CLK_PROC: process
    begin
        CLK <= '0';
        wait for CLK_PERIOD / 2;
        CLK <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- Stimulus
    STIM: process
    begin
        -- 1) Reset all registers
        RESET <= '1';
        wait for CLK_PERIOD * 2;
        RESET <= '0';
        wait for CLK_PERIOD;

        -- Verify all registers are zero after reset
        AA <= "0000"; BA <= "0001";
        wait for 1 ns;
        assert A_Data = x"00" report "FAIL: R0 not zero after reset" severity error;
        assert B_Data = x"00" report "FAIL: R1 not zero after reset" severity error;

        -- 2) Write 0xAA to R0 (DA=0000, RW=1)
        DA <= "0000"; D_Data <= x"AA"; RW <= '1';
        wait for CLK_PERIOD;
        RW <= '0';

        -- Read R0 on A_Data
        AA <= "0000";
        wait for 1 ns;
        assert A_Data = x"AA" report "FAIL: R0 should be 0xAA" severity error;

        -- 3) Write 0x55 to R5 (DA=0101, RW=1)
        DA <= "0101"; D_Data <= x"55"; RW <= '1';
        wait for CLK_PERIOD;
        RW <= '0';

        -- Read R5 on B_Data
        BA <= "0101";
        wait for 1 ns;
        assert B_Data = x"55" report "FAIL: R5 should be 0x55" severity error;

        -- 4) Simultaneous read: A_Data=R0, B_Data=R5
        AA <= "0000"; BA <= "0101";
        wait for 1 ns;
        assert A_Data = x"AA" report "FAIL: R0 should still be 0xAA" severity error;
        assert B_Data = x"55" report "FAIL: R5 should still be 0x55" severity error;

        -- 5) Write-disable test: try writing 0xFF to R0 with RW=0
        DA <= "0000"; D_Data <= x"FF"; RW <= '0';
        wait for CLK_PERIOD;
        AA <= "0000";
        wait for 1 ns;
        assert A_Data = x"AA" report "FAIL: R0 should still be 0xAA (RW=0)" severity error;

        -- 6) Write to R10 (DA=1010) with value 0xBB (matches project instruction #4)
        DA <= "1010"; D_Data <= x"BB"; RW <= '1';
        wait for CLK_PERIOD;
        RW <= '0';
        AA <= "1010";
        wait for 1 ns;
        assert A_Data = x"BB" report "FAIL: R10 should be 0xBB" severity error;

        -- 7) Write to R15 (DA=1111) with value 0xCC
        DA <= "1111"; D_Data <= x"CC"; RW <= '1';
        wait for CLK_PERIOD;
        RW <= '0';
        AA <= "1111"; BA <= "1010";
        wait for 1 ns;
        assert A_Data = x"CC" report "FAIL: R15 should be 0xCC" severity error;
        assert B_Data = x"BB" report "FAIL: R10 should still be 0xBB" severity error;

        -- 8) Write all 16 registers with unique values, then verify
        for i in 0 to 15 loop
            DA <= std_logic_vector(to_unsigned(i, 4));
            D_Data <= std_logic_vector(to_unsigned((i * 16) + i, 8)); -- 0x00, 0x11, 0x22, ..., 0xFF
            RW <= '1';
            wait for CLK_PERIOD;
        end loop;
        RW <= '0';

        -- Verify all 16 registers via A_Data
        for i in 0 to 15 loop
            AA <= std_logic_vector(to_unsigned(i, 4));
            wait for 1 ns;
            assert A_Data = std_logic_vector(to_unsigned((i * 16) + i, 8))
                report "FAIL: R" & integer'image(i) & " mismatch after bulk write"
                severity error;
        end loop;

        -- 9) Reset again and verify all cleared
        RESET <= '1';
        wait for CLK_PERIOD;
        RESET <= '0';
        wait for 1 ns;
        for i in 0 to 15 loop
            AA <= std_logic_vector(to_unsigned(i, 4));
            wait for 1 ns;
            assert A_Data = x"00"
                report "FAIL: R" & integer'image(i) & " not zero after second reset"
                severity error;
        end loop;

        report "ALL TESTS PASSED" severity note;
        wait;
    end process;

end testbench;
