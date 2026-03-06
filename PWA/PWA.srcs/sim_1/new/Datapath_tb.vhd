----------------------------------------------------------------------------------
-- Module Name: Datapath_tb
-- Description: Self-checking integration testbench for the full PWA Datapath
--              Confirms the FU operation table on p.2 of the spec by exercising
--              RegisterFile + MUXB + FunctionUnit + MUXD together.
--
--              Tests:
--                1)  Reset clears all registers
--                2)  Load registers via DataIn (MD=1 bypass)
--                3)  Arithmetic: F = A (transfer)
--                4)  Arithmetic: F = A + 1
--                5)  Arithmetic: F = A + B
--                6)  Arithmetic: F = A + B + 1
--                7)  Arithmetic: F = A + not B
--                8)  Arithmetic: F = A - B
--                9)  Arithmetic: F = A - 1
--                10) Logic: F = A OR B
--                11) Logic: F = A AND B
--                12) Logic: F = A XOR B
--                13) Logic: F = NOT A
--                14) Shift: F = B (pass-through)
--                15) Shift: F = sr B (shift right)
--                16) Shift: F = sl B (shift left)
--                17) MUXB: use ConstantIn as B operand
--                18) Flag checks (V, C, N, Z)
--                19) Write-back loop: RF -> FU -> RF round-trip
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Datapath_tb is
end Datapath_tb;

architecture testbench of Datapath_tb is

    -- Control inputs
    signal RESET      : STD_LOGIC := '0';
    signal CLK        : STD_LOGIC := '0';
    signal RW         : STD_LOGIC := '0';
    signal DA         : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal AA         : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal BA         : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal ConstantIn : STD_LOGIC_VECTOR(7 downto 0) := x"00";
    signal MB         : STD_LOGIC := '0';
    signal FS         : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal Cin        : STD_LOGIC := '0';
    signal DataIn     : STD_LOGIC_VECTOR(7 downto 0) := x"00";
    signal MD         : STD_LOGIC := '0';

    -- Outputs
    signal Address_Out : STD_LOGIC_VECTOR(7 downto 0);
    signal Data_Out    : STD_LOGIC_VECTOR(7 downto 0);
    signal V, C, N, Z  : STD_LOGIC;

    constant CLK_PERIOD : time := 10 ns;
    signal test_done    : boolean := false;

    -- Helper: apply a control word and wait one clock cycle (write-back)
    -- FS is passed as a 4-bit vector for convenience
    procedure apply_control (
        signal s_RW  : out STD_LOGIC;
        signal s_DA  : out STD_LOGIC_VECTOR(3 downto 0);
        signal s_AA  : out STD_LOGIC_VECTOR(3 downto 0);
        signal s_BA  : out STD_LOGIC_VECTOR(3 downto 0);
        signal s_MB  : out STD_LOGIC;
        signal s_CI  : out STD_LOGIC_VECTOR(7 downto 0);
        signal s_FS  : out STD_LOGIC_VECTOR(3 downto 0);
        signal s_Cin : out STD_LOGIC;
        signal s_DI  : out STD_LOGIC_VECTOR(7 downto 0);
        signal s_MD  : out STD_LOGIC;
        constant rw_val  : STD_LOGIC;
        constant da_val  : STD_LOGIC_VECTOR(3 downto 0);
        constant aa_val  : STD_LOGIC_VECTOR(3 downto 0);
        constant ba_val  : STD_LOGIC_VECTOR(3 downto 0);
        constant mb_val  : STD_LOGIC;
        constant ci_val  : STD_LOGIC_VECTOR(7 downto 0);
        constant fs_val  : STD_LOGIC_VECTOR(3 downto 0);
        constant cin_val : STD_LOGIC;
        constant di_val  : STD_LOGIC_VECTOR(7 downto 0);
        constant md_val  : STD_LOGIC
    ) is
    begin
        s_RW  <= rw_val;
        s_DA  <= da_val;
        s_AA  <= aa_val;
        s_BA  <= ba_val;
        s_MB  <= mb_val;
        s_CI  <= ci_val;
        s_FS  <= fs_val;
        s_Cin <= cin_val;
        s_DI  <= di_val;
        s_MD  <= md_val;
    end procedure;

begin

    -- Unit Under Test
    UUT: entity work.Datapath
    port map (
        RESET       => RESET,
        CLK         => CLK,
        RW          => RW,
        DA          => DA,
        AA          => AA,
        BA          => BA,
        ConstantIn  => ConstantIn,
        MB          => MB,
        FS3         => FS(3),
        FS2         => FS(2),
        FS1         => FS(1),
        FS0         => FS(0),
        Cin         => Cin,
        DataIn      => DataIn,
        MD          => MD,
        Address_Out => Address_Out,
        Data_Out    => Data_Out,
        V           => V,
        C           => C,
        N           => N,
        Z           => Z
    );

    -- Clock generation
    CLK_PROC: process
    begin
        if test_done then wait; end if;
        CLK <= '0'; wait for CLK_PERIOD / 2;
        CLK <= '1'; wait for CLK_PERIOD / 2;
    end process;

    STIM: process
    begin

        -----------------------------------------------------------------------
        -- TEST 1: Reset
        -----------------------------------------------------------------------
        report "TEST 1: Reset clears all registers";
        RESET <= '1';
        wait for CLK_PERIOD * 2;
        RESET <= '0';
        wait for CLK_PERIOD;

        -- After reset, read R0 via AA -> Address_Out should be 0x00
        AA <= "0000"; BA <= "0000";
        wait for 1 ns;
        assert Address_Out = x"00"
            report "TEST 1 FAIL: Address_Out /= 0x00 after reset" severity error;
        report "TEST 1 PASSED";
        wait for CLK_PERIOD;

        -----------------------------------------------------------------------
        -- TEST 2: Load registers via DataIn (MD=1 bypass)
        --         R0 = 0x0A (10), R1 = 0x14 (20), R2 = 0x1E (30), R3 = 0x50 (80)
        -----------------------------------------------------------------------
        report "TEST 2: Load registers via DataIn";

        -- Load R0 = 0x0A
        apply_control(RW, DA, AA, BA, MB, ConstantIn, FS, Cin, DataIn, MD,
            '1', "0000", "0000", "0000", '0', x"00", "0000", '0', x"0A", '1');
        wait for CLK_PERIOD;

        -- Load R1 = 0x14
        apply_control(RW, DA, AA, BA, MB, ConstantIn, FS, Cin, DataIn, MD,
            '1', "0001", "0000", "0000", '0', x"00", "0000", '0', x"14", '1');
        wait for CLK_PERIOD;

        -- Load R2 = 0x1E
        apply_control(RW, DA, AA, BA, MB, ConstantIn, FS, Cin, DataIn, MD,
            '1', "0010", "0000", "0000", '0', x"00", "0000", '0', x"1E", '1');
        wait for CLK_PERIOD;

        -- Load R3 = 0x50
        apply_control(RW, DA, AA, BA, MB, ConstantIn, FS, Cin, DataIn, MD,
            '1', "0011", "0000", "0000", '0', x"00", "0000", '0', x"50", '1');
        wait for CLK_PERIOD;

        RW <= '0';

        -- Verify loads: read R0 on AA, R1 on BA
        AA <= "0000"; BA <= "0001";
        wait for 1 ns;
        assert Address_Out = x"0A"
            report "TEST 2 FAIL: R0 expected 0x0A, got " &
                   integer'image(to_integer(unsigned(Address_Out))) severity error;
        assert Data_Out = x"14"
            report "TEST 2 FAIL: R1 expected 0x14, got " &
                   integer'image(to_integer(unsigned(Data_Out))) severity error;

        AA <= "0010"; BA <= "0011";
        wait for 1 ns;
        assert Address_Out = x"1E"
            report "TEST 2 FAIL: R2 expected 0x1E" severity error;
        assert Data_Out = x"50"
            report "TEST 2 FAIL: R3 expected 0x50" severity error;
        report "TEST 2 PASSED";
        wait for CLK_PERIOD;

        -----------------------------------------------------------------------
        -- ARITHMETIC TESTS (FS3=0)
        -- Using R0=0x0A(10), R1=0x14(20) as operands
        -- AA=R0 (A=10), BA=R1 (B=20), MB=0 (use B_Data), MD=0 (use F)
        -----------------------------------------------------------------------

        -- TEST 3: F = A (transfer), FS=0000, Cin=0 -> F = 10 = 0x0A
        report "TEST 3: F = A (transfer)";
        apply_control(RW, DA, AA, BA, MB, ConstantIn, FS, Cin, DataIn, MD,
            '1', "0100", "0000", "0001", '0', x"00", "0000", '0', x"00", '0');
        wait for CLK_PERIOD;
        RW <= '0'; AA <= "0100"; wait for 1 ns;
        assert Address_Out = x"0A"
            report "TEST 3 FAIL: F=A expected 0x0A, got " &
                   integer'image(to_integer(unsigned(Address_Out))) severity error;
        report "TEST 3 PASSED";
        wait for CLK_PERIOD;

        -- TEST 4: F = A + 1, FS=0001, Cin=1 -> F = 10+1 = 11 = 0x0B
        report "TEST 4: F = A + 1";
        apply_control(RW, DA, AA, BA, MB, ConstantIn, FS, Cin, DataIn, MD,
            '1', "0100", "0000", "0001", '0', x"00", "0001", '1', x"00", '0');
        wait for CLK_PERIOD;
        RW <= '0'; AA <= "0100"; wait for 1 ns;
        assert Address_Out = x"0B"
            report "TEST 4 FAIL: F=A+1 expected 0x0B, got " &
                   integer'image(to_integer(unsigned(Address_Out))) severity error;
        report "TEST 4 PASSED";
        wait for CLK_PERIOD;

        -- TEST 5: F = A + B, FS=0010, Cin=0 -> F = 10+20 = 30 = 0x1E
        report "TEST 5: F = A + B";
        apply_control(RW, DA, AA, BA, MB, ConstantIn, FS, Cin, DataIn, MD,
            '1', "0100", "0000", "0001", '0', x"00", "0010", '0', x"00", '0');
        wait for CLK_PERIOD;
        RW <= '0'; AA <= "0100"; wait for 1 ns;
        assert Address_Out = x"1E"
            report "TEST 5 FAIL: F=A+B expected 0x1E, got " &
                   integer'image(to_integer(unsigned(Address_Out))) severity error;
        report "TEST 5 PASSED";
        wait for CLK_PERIOD;

        -- TEST 6: F = A + B + 1, FS=0011, Cin=1 -> F = 10+20+1 = 31 = 0x1F
        report "TEST 6: F = A + B + 1";
        apply_control(RW, DA, AA, BA, MB, ConstantIn, FS, Cin, DataIn, MD,
            '1', "0100", "0000", "0001", '0', x"00", "0011", '1', x"00", '0');
        wait for CLK_PERIOD;
        RW <= '0'; AA <= "0100"; wait for 1 ns;
        assert Address_Out = x"1F"
            report "TEST 6 FAIL: F=A+B+1 expected 0x1F, got " &
                   integer'image(to_integer(unsigned(Address_Out))) severity error;
        report "TEST 6 PASSED";
        wait for CLK_PERIOD;

        -- TEST 7: F = A + not B, FS=0100, Cin=0 -> F = 10 + NOT(20) = 10+235 = 245 = 0xF5
        report "TEST 7: F = A + not B";
        apply_control(RW, DA, AA, BA, MB, ConstantIn, FS, Cin, DataIn, MD,
            '1', "0100", "0000", "0001", '0', x"00", "0100", '0', x"00", '0');
        wait for CLK_PERIOD;
        RW <= '0'; AA <= "0100"; wait for 1 ns;
        assert Address_Out = x"F5"
            report "TEST 7 FAIL: F=A+notB expected 0xF5, got " &
                   integer'image(to_integer(unsigned(Address_Out))) severity error;
        report "TEST 7 PASSED";
        wait for CLK_PERIOD;

        -- TEST 8: F = A - B, FS=0101, Cin=1 -> F = 10-20 = -10 = 0xF6 (two's complement)
        report "TEST 8: F = A - B";
        apply_control(RW, DA, AA, BA, MB, ConstantIn, FS, Cin, DataIn, MD,
            '1', "0100", "0000", "0001", '0', x"00", "0101", '1', x"00", '0');
        wait for CLK_PERIOD;
        RW <= '0'; AA <= "0100"; wait for 1 ns;
        assert Address_Out = x"F6"
            report "TEST 8 FAIL: F=A-B expected 0xF6, got " &
                   integer'image(to_integer(unsigned(Address_Out))) severity error;
        report "TEST 8 PASSED";
        wait for CLK_PERIOD;

        -- TEST 9: F = A - 1, FS=0110, Cin=0 -> F = 10-1 = 9 = 0x09
        report "TEST 9: F = A - 1";
        apply_control(RW, DA, AA, BA, MB, ConstantIn, FS, Cin, DataIn, MD,
            '1', "0100", "0000", "0001", '0', x"00", "0110", '0', x"00", '0');
        wait for CLK_PERIOD;
        RW <= '0'; AA <= "0100"; wait for 1 ns;
        assert Address_Out = x"09"
            report "TEST 9 FAIL: F=A-1 expected 0x09, got " &
                   integer'image(to_integer(unsigned(Address_Out))) severity error;
        report "TEST 9 PASSED";
        wait for CLK_PERIOD;

        -----------------------------------------------------------------------
        -- LOGIC TESTS (FS3=1, FS2=0)
        -- A=R0=0x0A=00001010, B=R1=0x14=00010100
        -----------------------------------------------------------------------

        -- TEST 10: F = A OR B, FS=1000 -> 0x0A OR 0x14 = 0x1E
        report "TEST 10: F = A OR B";
        apply_control(RW, DA, AA, BA, MB, ConstantIn, FS, Cin, DataIn, MD,
            '1', "0100", "0000", "0001", '0', x"00", "1000", '0', x"00", '0');
        wait for CLK_PERIOD;
        RW <= '0'; AA <= "0100"; wait for 1 ns;
        assert Address_Out = x"1E"
            report "TEST 10 FAIL: A OR B expected 0x1E, got " &
                   integer'image(to_integer(unsigned(Address_Out))) severity error;
        report "TEST 10 PASSED";
        wait for CLK_PERIOD;

        -- TEST 11: F = A AND B, FS=1001 -> 0x0A AND 0x14 = 0x00
        report "TEST 11: F = A AND B";
        apply_control(RW, DA, AA, BA, MB, ConstantIn, FS, Cin, DataIn, MD,
            '1', "0100", "0000", "0001", '0', x"00", "1001", '0', x"00", '0');
        wait for CLK_PERIOD;
        RW <= '0'; AA <= "0100"; wait for 1 ns;
        assert Address_Out = x"00"
            report "TEST 11 FAIL: A AND B expected 0x00, got " &
                   integer'image(to_integer(unsigned(Address_Out))) severity error;
        report "TEST 11 PASSED";
        wait for CLK_PERIOD;

        -- TEST 12: F = A XOR B, FS=1010 -> 0x0A XOR 0x14 = 0x1E
        report "TEST 12: F = A XOR B";
        apply_control(RW, DA, AA, BA, MB, ConstantIn, FS, Cin, DataIn, MD,
            '1', "0100", "0000", "0001", '0', x"00", "1010", '0', x"00", '0');
        wait for CLK_PERIOD;
        RW <= '0'; AA <= "0100"; wait for 1 ns;
        assert Address_Out = x"1E"
            report "TEST 12 FAIL: A XOR B expected 0x1E, got " &
                   integer'image(to_integer(unsigned(Address_Out))) severity error;
        report "TEST 12 PASSED";
        wait for CLK_PERIOD;

        -- TEST 13: F = NOT A, FS=1011 -> NOT 0x0A = 0xF5
        report "TEST 13: F = NOT A";
        apply_control(RW, DA, AA, BA, MB, ConstantIn, FS, Cin, DataIn, MD,
            '1', "0100", "0000", "0001", '0', x"00", "1011", '0', x"00", '0');
        wait for CLK_PERIOD;
        RW <= '0'; AA <= "0100"; wait for 1 ns;
        assert Address_Out = x"F5"
            report "TEST 13 FAIL: NOT A expected 0xF5, got " &
                   integer'image(to_integer(unsigned(Address_Out))) severity error;
        report "TEST 13 PASSED";
        wait for CLK_PERIOD;

        -----------------------------------------------------------------------
        -- SHIFT TESTS (FS3=1, FS2=1, MF=1 -> shifter selected)
        -- Shifter operates on B: B=R1=0x14=00010100
        -----------------------------------------------------------------------

        -- TEST 14: F = B (pass-through), FS=1100 -> 0x14
        report "TEST 14: F = B (shift pass-through)";
        apply_control(RW, DA, AA, BA, MB, ConstantIn, FS, Cin, DataIn, MD,
            '1', "0100", "0000", "0001", '0', x"00", "1100", '0', x"00", '0');
        wait for CLK_PERIOD;
        RW <= '0'; AA <= "0100"; wait for 1 ns;
        assert Address_Out = x"14"
            report "TEST 14 FAIL: F=B expected 0x14, got " &
                   integer'image(to_integer(unsigned(Address_Out))) severity error;
        report "TEST 14 PASSED";
        wait for CLK_PERIOD;

        -- TEST 15: F = sr B, FS=1101 -> 00010100 >> 1 = 00001010 = 0x0A
        report "TEST 15: F = sr B (shift right)";
        apply_control(RW, DA, AA, BA, MB, ConstantIn, FS, Cin, DataIn, MD,
            '1', "0100", "0000", "0001", '0', x"00", "1101", '0', x"00", '0');
        wait for CLK_PERIOD;
        RW <= '0'; AA <= "0100"; wait for 1 ns;
        assert Address_Out = x"0A"
            report "TEST 15 FAIL: sr B expected 0x0A, got " &
                   integer'image(to_integer(unsigned(Address_Out))) severity error;
        report "TEST 15 PASSED";
        wait for CLK_PERIOD;

        -- TEST 16: F = sl B, FS=1110 -> 00010100 << 1 = 00101000 = 0x28
        report "TEST 16: F = sl B (shift left)";
        apply_control(RW, DA, AA, BA, MB, ConstantIn, FS, Cin, DataIn, MD,
            '1', "0100", "0000", "0001", '0', x"00", "1110", '0', x"00", '0');
        wait for CLK_PERIOD;
        RW <= '0'; AA <= "0100"; wait for 1 ns;
        assert Address_Out = x"28"
            report "TEST 16 FAIL: sl B expected 0x28, got " &
                   integer'image(to_integer(unsigned(Address_Out))) severity error;
        report "TEST 16 PASSED";
        wait for CLK_PERIOD;

        -----------------------------------------------------------------------
        -- TEST 17: MUXB test -- MB=1, ConstantIn as B operand
        --          F = A + B with A=R0=0x0A, B=ConstantIn=0x05 -> 15 = 0x0F
        -----------------------------------------------------------------------
        report "TEST 17: MUXB selects ConstantIn";
        apply_control(RW, DA, AA, BA, MB, ConstantIn, FS, Cin, DataIn, MD,
            '1', "0100", "0000", "0001", '1', x"05", "0010", '0', x"00", '0');
        wait for CLK_PERIOD;
        RW <= '0'; AA <= "0100"; wait for 1 ns;
        assert Address_Out = x"0F"
            report "TEST 17 FAIL: A+ConstantIn expected 0x0F, got " &
                   integer'image(to_integer(unsigned(Address_Out))) severity error;
        report "TEST 17 PASSED";
        wait for CLK_PERIOD;

        -----------------------------------------------------------------------
        -- TEST 18: Flag checks
        -----------------------------------------------------------------------
        report "TEST 18: Flag checks";

        -- 18a: Zero flag -- compute 0x0A AND 0x14 = 0x00, Z should be 1
        AA <= "0000"; BA <= "0001"; MB <= '0'; MD <= '0';
        FS <= "1001"; Cin <= '0';
        RW <= '0';
        wait for 1 ns;
        assert Z = '1'
            report "TEST 18a FAIL: Z expected 1 for 0x0A AND 0x14 = 0x00" severity error;
        assert N = '0'
            report "TEST 18a FAIL: N expected 0 for zero result" severity error;

        -- 18b: Negative flag -- compute NOT A where A=0x0A -> 0xF5 (MSB=1)
        FS <= "1011";
        wait for 1 ns;
        assert N = '1'
            report "TEST 18b FAIL: N expected 1 for NOT 0x0A = 0xF5" severity error;
        assert Z = '0'
            report "TEST 18b FAIL: Z expected 0 for 0xF5" severity error;

        -- 18c: Carry flag -- compute A + B with A=R3=0x50(80), B=R3=0x50(80)
        --      using FS=0010 (A+B), 80+80=160=0xA0, no unsigned carry (160<256), C=0
        --      But for carry: let's use 0xFF + 0x01 approach
        --      Load R5=0xFF via DataIn, then add R5 + R1(0x14)
        apply_control(RW, DA, AA, BA, MB, ConstantIn, FS, Cin, DataIn, MD,
            '1', "0101", "0000", "0000", '0', x"00", "0000", '0', x"FF", '1');
        wait for CLK_PERIOD;
        RW <= '0';

        -- Now compute R5 + R1: A=R5=0xFF, B=R1=0x14, FS=0010 -> 0xFF+0x14 = 0x13 with C=1
        AA <= "0101"; BA <= "0001"; MB <= '0'; MD <= '0';
        FS <= "0010"; Cin <= '0';
        wait for 1 ns;
        assert C = '1'
            report "TEST 18c FAIL: C expected 1 for 0xFF + 0x14" severity error;

        -- 18d: Overflow -- compute 0x50 + 0x50 (80+80=160, signed overflow from +ve to -ve)
        --      A=R3=0x50, B=R3=0x50, FS=0010
        AA <= "0011"; BA <= "0011"; MB <= '0';
        FS <= "0010"; Cin <= '0';
        wait for 1 ns;
        assert V = '1'
            report "TEST 18d FAIL: V expected 1 for 0x50 + 0x50 (signed overflow)" severity error;

        report "TEST 18 PASSED";
        wait for CLK_PERIOD;

        -----------------------------------------------------------------------
        -- TEST 19: Write-back loop (RF -> FU -> RF round-trip)
        --          Compute R0 + R1 = 10 + 20 = 30 = 0x1E, write to R6
        --          Then read R6 and verify
        -----------------------------------------------------------------------
        report "TEST 19: Write-back loop RF -> FU -> RF";
        -- Compute A+B (R0+R1) and write result to R6
        apply_control(RW, DA, AA, BA, MB, ConstantIn, FS, Cin, DataIn, MD,
            '1', "0110", "0000", "0001", '0', x"00", "0010", '0', x"00", '0');
        wait for CLK_PERIOD;
        RW <= '0';

        -- Read R6
        AA <= "0110";
        wait for 1 ns;
        assert Address_Out = x"1E"
            report "TEST 19 FAIL: R6 expected 0x1E after A+B write-back, got " &
                   integer'image(to_integer(unsigned(Address_Out))) severity error;

        -- Now use R6 as input: compute R6 + R0 = 30 + 10 = 40 = 0x28, write to R7
        apply_control(RW, DA, AA, BA, MB, ConstantIn, FS, Cin, DataIn, MD,
            '1', "0111", "0110", "0000", '0', x"00", "0010", '0', x"00", '0');
        wait for CLK_PERIOD;
        RW <= '0';

        AA <= "0111";
        wait for 1 ns;
        assert Address_Out = x"28"
            report "TEST 19 FAIL: R7 expected 0x28 after chained write-back, got " &
                   integer'image(to_integer(unsigned(Address_Out))) severity error;

        report "TEST 19 PASSED";

        -----------------------------------------------------------------------
        -- DONE
        -----------------------------------------------------------------------
        report "ALL TESTS PASSED" severity note;
        test_done <= true;
        wait;
    end process;

end testbench;
