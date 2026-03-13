library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity InstructionRegister_tb is
end InstructionRegister_tb;

architecture TB of InstructionRegister_tb is

    signal RESET          : std_logic := '1';
    signal CLK            : std_logic := '0';
    signal Instruction_In : std_logic_vector(15 downto 0) := (others => '0');
    signal IL             : std_logic := '0';
    signal IR             : std_logic_vector(15 downto 0);

    constant CLK_PERIOD : time := 10 ns;

begin

    UUT: entity work.InstructionRegister
        port map (
            RESET          => RESET,
            CLK            => CLK,
            Instruction_In => Instruction_In,
            IL             => IL,
            IR             => IR
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

        -- IL=0: No load (IR should stay 0)
        IL <= '0';
        Instruction_In <= x"ABCD";
        wait for CLK_PERIOD * 2;

        -- IL=1: Load instruction
        IL <= '1';
        Instruction_In <= x"1234";
        wait for CLK_PERIOD;

        -- IL=0: Hold (IR should stay 0x1234)
        IL <= '0';
        Instruction_In <= x"5678";
        wait for CLK_PERIOD * 2;

        -- IL=1: Load new instruction
        IL <= '1';
        Instruction_In <= x"FFFF";
        wait for CLK_PERIOD;

        -- IL=0: Hold
        IL <= '0';
        wait for CLK_PERIOD * 2;

        wait;
    end process;

end TB;
