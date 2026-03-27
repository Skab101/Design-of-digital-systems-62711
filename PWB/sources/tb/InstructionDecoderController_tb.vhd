library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity InstructionDecoderController_tb is
end InstructionDecoderController_tb;

architecture TB of InstructionDecoderController_tb is

    -- ============================================================
    -- Change TEST_GROUP to select which tests to run:
    --   1 = ALU register-register (MOVA, ADD, SUB, etc.)
    --   2 = Memory & Immediate   (LD, ST, ADI, LDI)
    --   3 = Branch & Jump        (BRZ, BRN, JMP)
    --   4 = Multi-cycle           (LRI, SRM, SLM)
    -- ============================================================
    constant TEST_GROUP : integer := 1;

    signal RESET : std_logic := '1';
    signal CLK   : std_logic := '0';
    signal IR    : std_logic_vector(15 downto 0) := (others => '0');
    signal V, C, N, Z : std_logic := '0';
    signal PS    : std_logic_vector(1 downto 0);
    signal IL    : std_logic;
    signal DX, AX, BX, FS : std_logic_vector(3 downto 0);
    signal MB, MD, RW, MM, MW : std_logic;

    constant CLK_PERIOD : time := 10 ns;

    -- Helper: build IR from opcode + DR + SA + SB
    function make_ir(
        opcode : std_logic_vector(6 downto 0);
        DR     : std_logic_vector(2 downto 0) := "001";
        SA     : std_logic_vector(2 downto 0) := "010";
        SB     : std_logic_vector(2 downto 0) := "011"
    ) return std_logic_vector is
    begin
        return opcode & DR & SA & SB;
    end function;

begin

    UUT: entity work.InstructionDecoderController
        port map (
            RESET => RESET, CLK => CLK, IR => IR,
            V => V, C => C, N => N, Z => Z,
            PS => PS, IL => IL,
            DX => DX, AX => AX, BX => BX, FS => FS,
            MB => MB, MD => MD, RW => RW, MM => MM, MW => MW
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
        wait until rising_edge(CLK);  -- INF -> EX0 (don't care)
        wait until rising_edge(CLK);  -- EX0 -> INF

        ---------------------------------------------------------------
        -- GROUP 1: ALU register-register
        ---------------------------------------------------------------
        if TEST_GROUP = 1 then
            report "=== Group 1: ALU register-register ===" severity note;

            -- MOVA
            IR <= make_ir("0000000");
            wait until rising_edge(CLK); wait for 1 ns;
            assert FS = "0000" report "MOVA: FS expected 0000" severity error;
            assert RW = '1'    report "MOVA: RW expected 1"    severity error;
            assert PS = "01"   report "MOVA: PS expected 01"   severity error;
            wait until rising_edge(CLK);

            -- INC
            IR <= make_ir("0000001");
            wait until rising_edge(CLK); wait for 1 ns;
            assert FS = "0001" report "INC: FS expected 0001" severity error;
            assert RW = '1'    report "INC: RW expected 1"    severity error;
            wait until rising_edge(CLK);

            -- ADD
            IR <= make_ir("0000010");
            wait until rising_edge(CLK); wait for 1 ns;
            assert FS = "0010" report "ADD: FS expected 0010" severity error;
            assert RW = '1'    report "ADD: RW expected 1"    severity error;
            wait until rising_edge(CLK);

            -- SUB
            IR <= make_ir("0000101");
            wait until rising_edge(CLK); wait for 1 ns;
            assert FS = "0101" report "SUB: FS expected 0101" severity error;
            assert RW = '1'    report "SUB: RW expected 1"    severity error;
            wait until rising_edge(CLK);

            -- DEC
            IR <= make_ir("0000110");
            wait until rising_edge(CLK); wait for 1 ns;
            assert FS = "0110" report "DEC: FS expected 0110" severity error;
            assert RW = '1'    report "DEC: RW expected 1"    severity error;
            wait until rising_edge(CLK);

            -- OR
            IR <= make_ir("0001000");
            wait until rising_edge(CLK); wait for 1 ns;
            assert FS = "1000" report "OR: FS expected 1000" severity error;
            wait until rising_edge(CLK);

            -- AND
            IR <= make_ir("0001001");
            wait until rising_edge(CLK); wait for 1 ns;
            assert FS = "1001" report "AND: FS expected 1001" severity error;
            wait until rising_edge(CLK);

            -- XOR
            IR <= make_ir("0001010");
            wait until rising_edge(CLK); wait for 1 ns;
            assert FS = "1010" report "XOR: FS expected 1010" severity error;
            wait until rising_edge(CLK);

            -- NOT
            IR <= make_ir("0001011");
            wait until rising_edge(CLK); wait for 1 ns;
            assert FS = "1011" report "NOT: FS expected 1011" severity error;
            wait until rising_edge(CLK);

            -- MOVB
            IR <= make_ir("0001100");
            wait until rising_edge(CLK); wait for 1 ns;
            assert FS = "1100" report "MOVB: FS expected 1100" severity error;
            wait until rising_edge(CLK);

            report "=== Group 1: PASSED ===" severity note;
        end if;

        ---------------------------------------------------------------
        -- GROUP 2: Memory & Immediate
        ---------------------------------------------------------------
        if TEST_GROUP = 2 then
            report "=== Group 2: Memory & Immediate ===" severity note;

            -- LD
            IR <= make_ir("0010000");
            wait until rising_edge(CLK); wait for 1 ns;
            assert PS = "01" report "LD: PS expected 01" severity error;
            assert MD = '1'  report "LD: MD expected 1"  severity error;
            assert RW = '1'  report "LD: RW expected 1"  severity error;
            assert MW = '0'  report "LD: MW expected 0"  severity error;
            wait until rising_edge(CLK);

            -- ST
            IR <= make_ir("0100000");
            wait until rising_edge(CLK); wait for 1 ns;
            assert PS = "01" report "ST: PS expected 01" severity error;
            assert MW = '1'  report "ST: MW expected 1"  severity error;
            assert RW = '0'  report "ST: RW expected 0"  severity error;
            wait until rising_edge(CLK);

            -- ADI
            IR <= make_ir("1000010");
            wait until rising_edge(CLK); wait for 1 ns;
            assert PS = "01"   report "ADI: PS expected 01"   severity error;
            assert FS = "0010" report "ADI: FS expected 0010" severity error;
            assert MB = '1'    report "ADI: MB expected 1"    severity error;
            assert RW = '1'    report "ADI: RW expected 1"    severity error;
            wait until rising_edge(CLK);

            -- LDI
            IR <= make_ir("1001100");
            wait until rising_edge(CLK); wait for 1 ns;
            assert PS = "01"   report "LDI: PS expected 01"   severity error;
            assert FS = "1100" report "LDI: FS expected 1100" severity error;
            assert MB = '1'    report "LDI: MB expected 1"    severity error;
            assert RW = '1'    report "LDI: RW expected 1"    severity error;
            wait until rising_edge(CLK);

            report "=== Group 2: PASSED ===" severity note;
        end if;

        ---------------------------------------------------------------
        -- GROUP 3: Branch & Jump
        ---------------------------------------------------------------
        if TEST_GROUP = 3 then
            report "=== Group 3: Branch & Jump ===" severity note;

            -- BRZ taken (Z=1)
            IR <= make_ir("1100000");
            Z <= '1';
            wait until rising_edge(CLK); wait for 1 ns;
            assert PS = "10" report "BRZ(Z=1): PS expected 10" severity error;
            assert RW = '0'  report "BRZ: RW expected 0"       severity error;
            wait until rising_edge(CLK);

            -- BRZ not taken (Z=0)
            Z <= '0';
            wait until rising_edge(CLK); wait for 1 ns;
            assert PS = "01" report "BRZ(Z=0): PS expected 01" severity error;
            wait until rising_edge(CLK);

            -- BRN taken (N=1)
            IR <= make_ir("1100001");
            N <= '1';
            wait until rising_edge(CLK); wait for 1 ns;
            assert PS = "10" report "BRN(N=1): PS expected 10" severity error;
            wait until rising_edge(CLK);

            -- BRN not taken (N=0)
            N <= '0';
            wait until rising_edge(CLK); wait for 1 ns;
            assert PS = "01" report "BRN(N=0): PS expected 01" severity error;
            wait until rising_edge(CLK);

            -- JMP
            IR <= make_ir("1110000");
            wait until rising_edge(CLK); wait for 1 ns;
            assert PS = "11" report "JMP: PS expected 11" severity error;
            assert RW = '0'  report "JMP: RW expected 0"  severity error;
            wait until rising_edge(CLK);

            report "=== Group 3: PASSED ===" severity note;
        end if;

        ---------------------------------------------------------------
        -- GROUP 4: Multi-cycle (LRI, SRM, SLM)
        ---------------------------------------------------------------
        if TEST_GROUP = 4 then
            report "=== Group 4: Multi-cycle ===" severity note;

            -- LRI: 3-cycle (INF -> EX0 -> EX1 -> INF)
            IR <= make_ir("0010001");
            wait until rising_edge(CLK); wait for 1 ns;  -- EX0
            assert DX = "1000" report "LRI EX0: DX expected 1000" severity error;
            assert MD = '1'    report "LRI EX0: MD expected 1"    severity error;
            assert RW = '1'    report "LRI EX0: RW expected 1"    severity error;
            assert PS = "00"   report "LRI EX0: PS expected 00"   severity error;
            wait until rising_edge(CLK); wait for 1 ns;  -- EX1
            assert AX = "1000" report "LRI EX1: AX expected 1000" severity error;
            assert MD = '1'    report "LRI EX1: MD expected 1"    severity error;
            assert RW = '1'    report "LRI EX1: RW expected 1"    severity error;
            assert PS = "01"   report "LRI EX1: PS expected 01"   severity error;
            wait until rising_edge(CLK);  -- back to INF

            -- SRM with Z=1 (zero shifts, skip)
            IR <= make_ir("0001101");
            Z <= '1';
            wait until rising_edge(CLK); wait for 1 ns;  -- EX0
            assert DX = "1000" report "SRM(Z=1): DX expected 1000" severity error;
            assert PS = "01"   report "SRM(Z=1): PS expected 01"   severity error;
            wait until rising_edge(CLK);  -- back to INF
            Z <= '0';

            -- SRM with Z=0: full loop EX0->EX1->EX2->EX3->EX2->EX3->EX4->INF
            IR <= make_ir("0001101");
            wait until rising_edge(CLK); wait for 1 ns;  -- EX0
            assert DX = "1000" report "SRM EX0: DX expected 1000" severity error;
            assert PS = "00"   report "SRM EX0: PS expected 00"   severity error;
            wait until rising_edge(CLK); wait for 1 ns;  -- EX1
            assert DX = "1001"  report "SRM EX1: DX expected 1001" severity error;
            assert FS = "1100"  report "SRM EX1: FS expected 1100" severity error;
            assert MB = '1'     report "SRM EX1: MB expected 1"    severity error;
            wait until rising_edge(CLK); wait for 1 ns;  -- EX2
            assert FS = "1101"  report "SRM EX2: FS expected 1101" severity error;
            assert DX = "1000"  report "SRM EX2: DX expected 1000" severity error;
            assert AX = "1000"  report "SRM EX2: AX expected 1000" severity error;
            wait until rising_edge(CLK); wait for 1 ns;  -- EX3 (Z=0 -> loop)
            assert FS = "0110"  report "SRM EX3: FS expected 0110" severity error;
            assert DX = "1001"  report "SRM EX3: DX expected 1001" severity error;
            wait until rising_edge(CLK); wait for 1 ns;  -- EX2 again
            assert FS = "1101"  report "SRM EX2(loop): FS expected 1101" severity error;
            Z <= '1';
            wait until rising_edge(CLK);  -- EX3 (Z=1 -> EX4)
            wait until rising_edge(CLK); wait for 1 ns;  -- EX4
            assert AX = "1000" report "SRM EX4: AX expected 1000" severity error;
            assert PS = "01"   report "SRM EX4: PS expected 01"   severity error;
            assert RW = '1'    report "SRM EX4: RW expected 1"    severity error;
            wait until rising_edge(CLK);  -- back to INF
            Z <= '0';

            -- SLM: verify FS uses shift left (1110)
            IR <= make_ir("0001110");
            wait until rising_edge(CLK);  -- EX0
            wait until rising_edge(CLK);  -- EX1
            wait until rising_edge(CLK); wait for 1 ns;  -- EX2
            assert FS = "1110" report "SLM EX2: FS expected 1110" severity error;
            Z <= '1';
            wait until rising_edge(CLK);  -- EX3
            wait until rising_edge(CLK);  -- EX4
            wait until rising_edge(CLK);  -- INF
            Z <= '0';

            report "=== Group 4: PASSED ===" severity note;
        end if;

        report "=== Test group " & integer'image(TEST_GROUP) & " completed ===" severity note;
        wait;
    end process;

end TB;
