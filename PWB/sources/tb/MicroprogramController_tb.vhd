library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MicroprogramController_tb is
end MicroprogramController_tb;

architecture TB of MicroprogramController_tb is

    -- ============================================================
    -- Change TEST_GROUP to select which tests to run:
    --   1 = ALU register-register (MOVA, INC, ADD, SUB, etc.)
    --   2 = Memory & Immediate   (LD, ST, ADI, LDI)
    --   3 = Branch & Jump        (BRZ, BRN, JMP)
    --   4 = Multi-cycle          (LRI, SRM, SLM)
    -- ============================================================
    constant TEST_GROUP : integer := 1;

    signal RESET          : std_logic := '1';
    signal CLK            : std_logic := '0';
    signal Address_In     : std_logic_vector(7 downto 0) := (others => '0');
    signal Address_Out    : std_logic_vector(7 downto 0);
    signal Instruction_In : std_logic_vector(15 downto 0) := (others => '0');
    signal Constant_Out   : std_logic_vector(7 downto 0);
    signal V, C, N, Z     : std_logic := '0';
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

    UUT: entity work.MicroprogramController
        port map (
            RESET          => RESET,
            CLK            => CLK,
            Address_In     => Address_In,
            Address_Out    => Address_Out,
            Instruction_In => Instruction_In,
            Constant_Out   => Constant_Out,
            V              => V,
            C              => C,
            N              => N,
            Z              => Z,
            DX             => DX,
            AX             => AX,
            BX             => BX,
            FS             => FS,
            MB             => MB,
            MD             => MD,
            RW             => RW,
            MM             => MM,
            MW             => MW
        );

    clk_process: process
    begin
        CLK <= '0'; wait for CLK_PERIOD / 2;
        CLK <= '1'; wait for CLK_PERIOD / 2;
    end process;

    stim_process: process
        variable expected_pc : unsigned(7 downto 0) := (others => '0');
    begin
        -- ============================================================
        -- Reset: PC=0, state=INF
        -- ============================================================
        RESET <= '1';
        wait for CLK_PERIOD * 2;
        RESET <= '0';
        wait for 1 ns;
        assert Address_Out = x"00" report "RESET: Address_Out expected 00" severity error;

        -- After reset we are in INF.
        -- Timing per 2-cycle instruction:
        --   1) Set Instruction_In before INF rising_edge
        --   2) rising_edge (INF->EX0): IR loads, PC holds (PS=00)
        --   3) wait 1 ns, check EX0 control signals
        --   4) rising_edge (EX0->INF): PC increments (PS=01)
        --   5) Address_Out now = old PC + 1

        ---------------------------------------------------------------
        -- GROUP 1: ALU register-register
        --   DR=001, SA=010, SB=011
        --   Verifies: control signals, PC increment, Constant_Out
        ---------------------------------------------------------------
        if TEST_GROUP = 1 then
            report "=== Group 1: ALU register-register ===" severity note;
            expected_pc := x"00";

            -- MOVA: R[DR] <- R[SA]
            Instruction_In <= make_ir("0000000");
            wait until rising_edge(CLK); wait for 1 ns;  -- INF->EX0
            -- During INF: IL=1, MM=1 were active (IR loaded)
            -- Now in EX0: check control outputs
            assert FS  = "0000" report "MOVA: FS expected 0000"  severity error;
            assert RW  = '1'    report "MOVA: RW expected 1"     severity error;
            assert MD  = '0'    report "MOVA: MD expected 0"     severity error;
            assert DX  = "0001" report "MOVA: DX expected 0001"  severity error;
            assert AX  = "0010" report "MOVA: AX expected 0010"  severity error;
            -- Constant_Out = ZeroFill(IR) = 00000 & SB = 00000011
            assert Constant_Out = "00000011" report "MOVA: Constant_Out expected 00000011" severity error;
            wait until rising_edge(CLK); wait for 1 ns;  -- EX0->INF, PC+1
            expected_pc := expected_pc + 1;
            assert Address_Out = std_logic_vector(expected_pc)
                report "MOVA: Address_Out expected " & integer'image(to_integer(expected_pc)) severity error;

            -- INC: R[DR] <- R[SA] + 1
            Instruction_In <= make_ir("0000001");
            wait until rising_edge(CLK); wait for 1 ns;  -- INF->EX0
            assert FS  = "0001" report "INC: FS expected 0001"  severity error;
            assert RW  = '1'    report "INC: RW expected 1"     severity error;
            assert DX  = "0001" report "INC: DX expected 0001"  severity error;
            wait until rising_edge(CLK); wait for 1 ns;  -- EX0->INF, PC+1
            expected_pc := expected_pc + 1;
            assert Address_Out = std_logic_vector(expected_pc)
                report "INC: Address_Out expected " & integer'image(to_integer(expected_pc)) severity error;

            -- ADD: R[DR] <- R[SA] + R[SB]
            Instruction_In <= make_ir("0000010");
            wait until rising_edge(CLK); wait for 1 ns;
            assert FS  = "0010" report "ADD: FS expected 0010"  severity error;
            assert RW  = '1'    report "ADD: RW expected 1"     severity error;
            assert MB  = '0'    report "ADD: MB expected 0"     severity error;
            assert BX  = "0011" report "ADD: BX expected 0011"  severity error;
            wait until rising_edge(CLK); wait for 1 ns;
            expected_pc := expected_pc + 1;
            assert Address_Out = std_logic_vector(expected_pc)
                report "ADD: Address_Out mismatch" severity error;

            -- SUB: R[DR] <- R[SA] - R[SB]
            Instruction_In <= make_ir("0000101");
            wait until rising_edge(CLK); wait for 1 ns;
            assert FS  = "0101" report "SUB: FS expected 0101"  severity error;
            assert RW  = '1'    report "SUB: RW expected 1"     severity error;
            assert MB  = '0'    report "SUB: MB expected 0"     severity error;
            wait until rising_edge(CLK); wait for 1 ns;
            expected_pc := expected_pc + 1;
            assert Address_Out = std_logic_vector(expected_pc)
                report "SUB: Address_Out mismatch" severity error;

            -- DEC: R[DR] <- R[SA] - 1
            Instruction_In <= make_ir("0000110");
            wait until rising_edge(CLK); wait for 1 ns;
            assert FS  = "0110" report "DEC: FS expected 0110"  severity error;
            assert RW  = '1'    report "DEC: RW expected 1"     severity error;
            wait until rising_edge(CLK); wait for 1 ns;
            expected_pc := expected_pc + 1;
            assert Address_Out = std_logic_vector(expected_pc)
                report "DEC: Address_Out mismatch" severity error;

            -- OR: R[DR] <- R[SA] v R[SB]
            Instruction_In <= make_ir("0001000");
            wait until rising_edge(CLK); wait for 1 ns;
            assert FS  = "1000" report "OR: FS expected 1000"   severity error;
            assert RW  = '1'    report "OR: RW expected 1"      severity error;
            assert MB  = '0'    report "OR: MB expected 0"      severity error;
            wait until rising_edge(CLK); wait for 1 ns;
            expected_pc := expected_pc + 1;
            assert Address_Out = std_logic_vector(expected_pc)
                report "OR: Address_Out mismatch" severity error;

            -- AND: R[DR] <- R[SA] ^ R[SB]
            Instruction_In <= make_ir("0001001");
            wait until rising_edge(CLK); wait for 1 ns;
            assert FS  = "1001" report "AND: FS expected 1001"  severity error;
            assert RW  = '1'    report "AND: RW expected 1"     severity error;
            wait until rising_edge(CLK); wait for 1 ns;
            expected_pc := expected_pc + 1;
            assert Address_Out = std_logic_vector(expected_pc)
                report "AND: Address_Out mismatch" severity error;

            -- XOR: R[DR] <- R[SA] xor R[SB]
            Instruction_In <= make_ir("0001010");
            wait until rising_edge(CLK); wait for 1 ns;
            assert FS  = "1010" report "XOR: FS expected 1010"  severity error;
            assert RW  = '1'    report "XOR: RW expected 1"     severity error;
            wait until rising_edge(CLK); wait for 1 ns;
            expected_pc := expected_pc + 1;
            assert Address_Out = std_logic_vector(expected_pc)
                report "XOR: Address_Out mismatch" severity error;

            -- NOT: R[DR] <- R[SA]'
            Instruction_In <= make_ir("0001011");
            wait until rising_edge(CLK); wait for 1 ns;
            assert FS  = "1011" report "NOT: FS expected 1011"  severity error;
            assert RW  = '1'    report "NOT: RW expected 1"     severity error;
            wait until rising_edge(CLK); wait for 1 ns;
            expected_pc := expected_pc + 1;
            assert Address_Out = std_logic_vector(expected_pc)
                report "NOT: Address_Out mismatch" severity error;

            -- MOVB: R[DR] <- R[SB]
            Instruction_In <= make_ir("0001100");
            wait until rising_edge(CLK); wait for 1 ns;
            assert FS  = "1100" report "MOVB: FS expected 1100" severity error;
            assert RW  = '1'    report "MOVB: RW expected 1"    severity error;
            wait until rising_edge(CLK); wait for 1 ns;
            expected_pc := expected_pc + 1;
            assert Address_Out = std_logic_vector(expected_pc)
                report "MOVB: Address_Out mismatch" severity error;

            report "=== Group 1: PASSED ===" severity note;
        end if;

        ---------------------------------------------------------------
        -- GROUP 2: Memory & Immediate
        ---------------------------------------------------------------
        if TEST_GROUP = 2 then
            report "=== Group 2: Memory & Immediate ===" severity note;
            expected_pc := x"00";

            -- LD: R[DR] <- M[R[SA]]
            Instruction_In <= make_ir("0010000");
            wait until rising_edge(CLK); wait for 1 ns;  -- INF->EX0
            assert MD  = '1'  report "LD: MD expected 1"  severity error;
            assert RW  = '1'  report "LD: RW expected 1"  severity error;
            assert MW  = '0'  report "LD: MW expected 0"  severity error;
            assert MM  = '0'  report "LD: MM expected 0"  severity error;
            wait until rising_edge(CLK); wait for 1 ns;  -- EX0->INF, PC+1
            expected_pc := expected_pc + 1;
            assert Address_Out = std_logic_vector(expected_pc)
                report "LD: Address_Out mismatch" severity error;

            -- ST: M[R[SA]] <- R[SB]
            Instruction_In <= make_ir("0100000");
            wait until rising_edge(CLK); wait for 1 ns;
            assert MW  = '1'  report "ST: MW expected 1"  severity error;
            assert RW  = '0'  report "ST: RW expected 0"  severity error;
            assert MM  = '0'  report "ST: MM expected 0"  severity error;
            wait until rising_edge(CLK); wait for 1 ns;
            expected_pc := expected_pc + 1;
            assert Address_Out = std_logic_vector(expected_pc)
                report "ST: Address_Out mismatch" severity error;

            -- ADI: R[DR] <- R[SA] + zf OP  (SB=101 -> Constant_Out=00000101)
            Instruction_In <= make_ir("1000010", "001", "010", "101");
            wait until rising_edge(CLK); wait for 1 ns;
            assert FS  = "0010" report "ADI: FS expected 0010" severity error;
            assert MB  = '1'    report "ADI: MB expected 1"    severity error;
            assert RW  = '1'    report "ADI: RW expected 1"    severity error;
            assert Constant_Out = "00000101" report "ADI: Constant_Out expected 00000101" severity error;
            wait until rising_edge(CLK); wait for 1 ns;
            expected_pc := expected_pc + 1;
            assert Address_Out = std_logic_vector(expected_pc)
                report "ADI: Address_Out mismatch" severity error;

            -- LDI: R[DR] <- zf OP  (SB=110 -> Constant_Out=00000110)
            Instruction_In <= make_ir("1001100", "010", "000", "110");
            wait until rising_edge(CLK); wait for 1 ns;
            assert FS  = "1100" report "LDI: FS expected 1100" severity error;
            assert MB  = '1'    report "LDI: MB expected 1"    severity error;
            assert RW  = '1'    report "LDI: RW expected 1"    severity error;
            assert Constant_Out = "00000110" report "LDI: Constant_Out expected 00000110" severity error;
            wait until rising_edge(CLK); wait for 1 ns;
            expected_pc := expected_pc + 1;
            assert Address_Out = std_logic_vector(expected_pc)
                report "LDI: Address_Out mismatch" severity error;

            report "=== Group 2: PASSED ===" severity note;
        end if;

        ---------------------------------------------------------------
        -- GROUP 3: Branch & Jump (verify PC changes)
        ---------------------------------------------------------------
        if TEST_GROUP = 3 then
            report "=== Group 3: Branch & Jump ===" severity note;
            expected_pc := x"00";

            -- BRZ taken (Z=1): PC <- PC + sign-extended offset
            -- IR = 1100000 | DR=001 | SA=010 | SB=011
            -- SignExtend: IR8=1 -> 111.IR7IR6.IR2IR1IR0 = 111.01.011 = 11101011 = -21
            -- PC should go from 0 to 0 + (-21) ... but let's use a positive offset
            -- IR = 1100000 | 0.00 | 010 | 011  -> IR8=0 -> SE = 000.00.011 = 00000011 = +3
            Instruction_In <= make_ir("1100000", "000", "010", "011");
            Z <= '1';
            wait until rising_edge(CLK); wait for 1 ns;  -- INF->EX0
            assert RW  = '0'  report "BRZ(Z=1): RW expected 0"  severity error;
            -- PS=10 means branch: PC <- PC + offset on next edge
            wait until rising_edge(CLK); wait for 1 ns;  -- EX0->INF
            -- Offset = SignExtend = 00000011 = 3, old PC = 0 -> new PC = 0+3 = 3
            expected_pc := x"03";
            assert Address_Out = std_logic_vector(expected_pc)
                report "BRZ(Z=1): Address_Out expected 03, got " &
                       integer'image(to_integer(unsigned(Address_Out))) severity error;
            Z <= '0';

            -- BRZ not taken (Z=0): PC <- PC+1
            Instruction_In <= make_ir("1100000", "000", "010", "011");
            wait until rising_edge(CLK); wait for 1 ns;  -- INF->EX0
            -- PS=01 means increment
            wait until rising_edge(CLK); wait for 1 ns;  -- EX0->INF
            expected_pc := expected_pc + 1;  -- 3+1=4
            assert Address_Out = std_logic_vector(expected_pc)
                report "BRZ(Z=0): Address_Out expected 04" severity error;

            -- BRN taken (N=1): PC <- PC + offset
            -- Use IR8=0, IR7IR6=01, SB=010 -> SE = 000.01.010 = 00001010 = +10
            Instruction_In <= make_ir("1100001", "001", "010", "010");
            N <= '1';
            wait until rising_edge(CLK); wait for 1 ns;  -- INF->EX0
            assert RW  = '0' report "BRN(N=1): RW expected 0" severity error;
            wait until rising_edge(CLK); wait for 1 ns;  -- EX0->INF
            -- offset=10, old PC=4, new PC=4+10=14=0x0E
            expected_pc := x"0E";
            assert Address_Out = std_logic_vector(expected_pc)
                report "BRN(N=1): Address_Out expected 0E, got " &
                       integer'image(to_integer(unsigned(Address_Out))) severity error;
            N <= '0';

            -- BRN not taken (N=0): PC <- PC+1
            Instruction_In <= make_ir("1100001", "001", "010", "010");
            wait until rising_edge(CLK); wait for 1 ns;
            wait until rising_edge(CLK); wait for 1 ns;
            expected_pc := expected_pc + 1;  -- 14+1=15=0x0F
            assert Address_Out = std_logic_vector(expected_pc)
                report "BRN(N=0): Address_Out expected 0F" severity error;

            -- JMP: PC <- Address_In
            Instruction_In <= make_ir("1110000", "000", "011", "000");
            Address_In <= x"42";
            wait until rising_edge(CLK); wait for 1 ns;  -- INF->EX0
            assert RW = '0' report "JMP: RW expected 0" severity error;
            -- PS=11 means jump: PC <- Address_In on next edge
            wait until rising_edge(CLK); wait for 1 ns;  -- EX0->INF
            expected_pc := x"42";
            assert Address_Out = std_logic_vector(expected_pc)
                report "JMP: Address_Out expected 42, got " &
                       integer'image(to_integer(unsigned(Address_Out))) severity error;

            -- Verify PC increments normally after jump
            Instruction_In <= make_ir("0000000");  -- MOVA (2-cycle)
            wait until rising_edge(CLK); wait for 1 ns;  -- INF->EX0
            wait until rising_edge(CLK); wait for 1 ns;  -- EX0->INF, PC+1
            expected_pc := expected_pc + 1;  -- 0x42+1=0x43
            assert Address_Out = std_logic_vector(expected_pc)
                report "Post-JMP increment: Address_Out expected 43" severity error;

            report "=== Group 3: PASSED ===" severity note;
        end if;

        ---------------------------------------------------------------
        -- GROUP 4: Multi-cycle (LRI, SRM, SLM)
        --   Verifies PC holds during multi-cycle, then increments
        ---------------------------------------------------------------
        if TEST_GROUP = 4 then
            report "=== Group 4: Multi-cycle ===" severity note;
            expected_pc := x"00";

            -- ============================================================
            -- LRI: 3-cycle (INF -> EX0 -> EX1 -> INF)
            --   EX0: R8 <- M[R[SA]], PS=00 (hold PC)
            --   EX1: R[DR] <- M[R8], PS=01 (PC+1)
            -- ============================================================
            Instruction_In <= make_ir("0010001", "001", "010", "011");
            wait until rising_edge(CLK); wait for 1 ns;  -- INF->EX0
            assert DX  = "1000" report "LRI EX0: DX expected 1000" severity error;
            assert MD  = '1'    report "LRI EX0: MD expected 1"    severity error;
            assert RW  = '1'    report "LRI EX0: RW expected 1"    severity error;
            assert MM  = '0'    report "LRI EX0: MM expected 0"    severity error;
            -- PC should still be 0 (PS=00 hold during EX0)
            assert Address_Out = std_logic_vector(expected_pc)
                report "LRI EX0: PC should hold" severity error;

            wait until rising_edge(CLK); wait for 1 ns;  -- EX0->EX1
            assert AX  = "1000" report "LRI EX1: AX expected 1000" severity error;
            assert DX  = "0001" report "LRI EX1: DX expected 0001" severity error;
            assert MD  = '1'    report "LRI EX1: MD expected 1"    severity error;
            assert RW  = '1'    report "LRI EX1: RW expected 1"    severity error;
            -- PC still held (increments on this edge's PS=01 -> next cycle)
            assert Address_Out = std_logic_vector(expected_pc)
                report "LRI EX1: PC should still hold" severity error;

            wait until rising_edge(CLK); wait for 1 ns;  -- EX1->INF, PC+1
            expected_pc := expected_pc + 1;
            assert Address_Out = std_logic_vector(expected_pc)
                report "LRI done: Address_Out expected 01" severity error;

            -- ============================================================
            -- SRM with Z=1: skip (only EX0, then back to INF)
            --   EX0: R8 <- R[SA], Z=1 -> INF, PS=01
            -- ============================================================
            Instruction_In <= make_ir("0001101", "001", "010", "011");
            Z <= '1';
            wait until rising_edge(CLK); wait for 1 ns;  -- INF->EX0
            assert DX  = "1000" report "SRM(Z=1) EX0: DX expected 1000" severity error;
            assert RW  = '1'    report "SRM(Z=1) EX0: RW expected 1"    severity error;
            wait until rising_edge(CLK); wait for 1 ns;  -- EX0->INF, PC+1
            expected_pc := expected_pc + 1;
            assert Address_Out = std_logic_vector(expected_pc)
                report "SRM(Z=1): Address_Out mismatch" severity error;
            Z <= '0';

            -- ============================================================
            -- SRM with Z=0: full loop
            --   EX0: R8 <- R[SA], Z=0 -> EX1, PS=00
            --   EX1: R9 <- zf OP, Z=0 -> EX2, PS=00
            --   EX2: R8 <- sr R8 (FS=1101), -> EX3, PS=00
            --   EX3: R9 <- R9-1 (FS=0110), Z=0 -> EX2 (loop)
            --   EX3: R9 <- R9-1, Z=1 -> EX4
            --   EX4: R[DR] <- R8, PS=01 -> INF
            -- ============================================================
            Instruction_In <= make_ir("0001101", "001", "010", "011");
            wait until rising_edge(CLK); wait for 1 ns;  -- INF->EX0
            assert DX  = "1000" report "SRM EX0: DX expected 1000"  severity error;
            assert RW  = '1'    report "SRM EX0: RW expected 1"     severity error;
            -- PC holds during entire multi-cycle
            assert Address_Out = std_logic_vector(expected_pc)
                report "SRM EX0: PC should hold" severity error;

            wait until rising_edge(CLK); wait for 1 ns;  -- EX0->EX1
            assert DX  = "1001" report "SRM EX1: DX expected 1001"  severity error;
            assert FS  = "1100" report "SRM EX1: FS expected 1100"  severity error;
            assert MB  = '1'    report "SRM EX1: MB expected 1"     severity error;
            assert RW  = '1'    report "SRM EX1: RW expected 1"     severity error;

            wait until rising_edge(CLK); wait for 1 ns;  -- EX1->EX2
            assert FS  = "1101" report "SRM EX2: FS expected 1101 (shift right)" severity error;
            assert DX  = "1000" report "SRM EX2: DX expected 1000"  severity error;
            assert AX  = "1000" report "SRM EX2: AX expected 1000"  severity error;

            wait until rising_edge(CLK); wait for 1 ns;  -- EX2->EX3 (Z=0 -> loop)
            assert FS  = "0110" report "SRM EX3: FS expected 0110 (DEC)" severity error;
            assert DX  = "1001" report "SRM EX3: DX expected 1001"  severity error;
            assert AX  = "1001" report "SRM EX3: AX expected 1001"  severity error;

            wait until rising_edge(CLK); wait for 1 ns;  -- EX3->EX2 (loop back)
            assert FS  = "1101" report "SRM EX2(loop): FS expected 1101" severity error;

            -- Set Z=1 so EX3 exits loop -> EX4
            Z <= '1';
            wait until rising_edge(CLK); wait for 1 ns;  -- EX2->EX3
            assert FS  = "0110" report "SRM EX3(exit): FS expected 0110" severity error;

            wait until rising_edge(CLK); wait for 1 ns;  -- EX3->EX4
            assert AX  = "1000" report "SRM EX4: AX expected 1000"  severity error;
            assert RW  = '1'    report "SRM EX4: RW expected 1"     severity error;
            -- PC still held
            assert Address_Out = std_logic_vector(expected_pc)
                report "SRM EX4: PC should still hold" severity error;

            wait until rising_edge(CLK); wait for 1 ns;  -- EX4->INF, PC+1
            expected_pc := expected_pc + 1;
            assert Address_Out = std_logic_vector(expected_pc)
                report "SRM done: Address_Out mismatch" severity error;
            Z <= '0';

            -- ============================================================
            -- SLM: verify uses shift left (FS=1110 in EX2)
            --   Same structure as SRM, just FS=1110 instead of 1101
            -- ============================================================
            Instruction_In <= make_ir("0001110", "001", "010", "011");
            wait until rising_edge(CLK); wait for 1 ns;  -- INF->EX0
            assert DX  = "1000" report "SLM EX0: DX expected 1000" severity error;

            wait until rising_edge(CLK); wait for 1 ns;  -- EX0->EX1
            assert DX  = "1001" report "SLM EX1: DX expected 1001" severity error;
            assert FS  = "1100" report "SLM EX1: FS expected 1100" severity error;
            assert MB  = '1'    report "SLM EX1: MB expected 1"    severity error;

            wait until rising_edge(CLK); wait for 1 ns;  -- EX1->EX2
            assert FS  = "1110" report "SLM EX2: FS expected 1110 (shift left)" severity error;

            Z <= '1';
            wait until rising_edge(CLK); wait for 1 ns;  -- EX2->EX3
            wait until rising_edge(CLK); wait for 1 ns;  -- EX3->EX4
            assert AX  = "1000" report "SLM EX4: AX expected 1000" severity error;
            assert RW  = '1'    report "SLM EX4: RW expected 1"    severity error;

            wait until rising_edge(CLK); wait for 1 ns;  -- EX4->INF, PC+1
            expected_pc := expected_pc + 1;
            assert Address_Out = std_logic_vector(expected_pc)
                report "SLM done: Address_Out mismatch" severity error;
            Z <= '0';

            report "=== Group 4: PASSED ===" severity note;
        end if;

        report "=== Test group " & integer'image(TEST_GROUP) & " completed ===" severity note;
        wait;
    end process;

end TB;
