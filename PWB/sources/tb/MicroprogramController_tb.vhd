library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MicroprogramController_tb is
end MicroprogramController_tb;

architecture TB of MicroprogramController_tb is

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
    begin
        -- Reset
        RESET <= '1';
        wait for CLK_PERIOD * 2;
        RESET <= '0';

        -- INF: fetch instruction (ADD: opcode=0000010, DR=001, SA=010, SB=011)
        Instruction_In <= "0000010001010011";
        wait for CLK_PERIOD;

        -- EX0: execute ADD
        wait for CLK_PERIOD;

        -- INF: fetch next instruction (MOVA: opcode=0000000, DR=100, SA=010, SB=001)
        Instruction_In <= "0000000100010001";
        wait for CLK_PERIOD;

        -- EX0: execute MOVA
        wait for CLK_PERIOD;

        -- INF: fetch LDI instruction (opcode=1001100, DR=010, SB=101)
        Instruction_In <= "1001100010000101";
        wait for CLK_PERIOD;

        -- EX0: execute LDI
        wait for CLK_PERIOD;

        -- INF: fetch JMP instruction (opcode=1110000, SA=011)
        Instruction_In <= "1110000000011000";
        Address_In <= x"20";
        wait for CLK_PERIOD;

        -- EX0: execute JMP
        wait for CLK_PERIOD * 3;

        wait;
    end process;

end TB;
