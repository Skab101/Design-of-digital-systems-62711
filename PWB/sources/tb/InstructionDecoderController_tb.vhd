library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity InstructionDecoderController_tb is
end InstructionDecoderController_tb;

architecture TB of InstructionDecoderController_tb is

    signal RESET : std_logic := '1';
    signal CLK   : std_logic := '0';
    signal IR    : std_logic_vector(15 downto 0) := (others => '0');
    signal V, C, N, Z : std_logic := '0';
    signal PS    : std_logic_vector(1 downto 0);
    signal IL    : std_logic;
    signal DX, AX, BX, FS : std_logic_vector(3 downto 0);
    signal MB, MD, RW, MM, MW : std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin

    UUT: entity work.InstructionDecoderController
        port map (
            RESET => RESET,
            CLK   => CLK,
            IR    => IR,
            V     => V,
            C     => C,
            N     => N,
            Z     => Z,
            PS    => PS,
            IL    => IL,
            DX    => DX,
            AX    => AX,
            BX    => BX,
            FS    => FS,
            MB    => MB,
            MD    => MD,
            RW    => RW,
            MM    => MM,
            MW    => MW
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

        -- INF cycle: should set IL=1, go to EX0
        wait for CLK_PERIOD;

        -- Test ADD instruction: opcode=0000010, DR=001, SA=010, SB=011
        IR <= "0000010001010011";
        wait for CLK_PERIOD;

        -- EX0 for ADD: PS=01, FS=0010, RW=1, MD=0
        wait for CLK_PERIOD;

        -- Back to INF
        -- Test LD instruction: opcode=0010000, DR=001, SA=010, SB=000
        IR <= "0010000001010000";
        wait for CLK_PERIOD;

        -- EX0 for LD
        wait for CLK_PERIOD;

        -- Back to INF
        -- Test BRZ with Z=1 (branch taken)
        IR <= "1100000001010000";
        Z <= '1';
        wait for CLK_PERIOD;

        -- EX0 for BRZ: PS should be 10 (branch)
        wait for CLK_PERIOD;

        -- Back to INF
        -- Test BRZ with Z=0 (not taken)
        Z <= '0';
        wait for CLK_PERIOD;

        -- EX0 for BRZ: PS should be 01 (increment)
        wait for CLK_PERIOD;

        -- Test JMP instruction: opcode=1110000
        IR <= "1110000001010000";
        wait for CLK_PERIOD;

        -- EX0 for JMP: PS should be 11
        wait for CLK_PERIOD * 2;

        wait;
    end process;

end TB;
