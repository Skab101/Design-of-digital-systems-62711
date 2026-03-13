library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity InstructionRegister is
    port (
        RESET          : in  std_logic;
        CLK            : in  std_logic;
        Instruction_In : in  std_logic_vector(15 downto 0);
        IL             : in  std_logic;
        IR             : out std_logic_vector(15 downto 0)
    );
end InstructionRegister;

architecture IR_Behavorial of InstructionRegister is
begin

    -- TODO: Implement sequential process (CLK, RESET)
    -- IL=0: No Load,  IL=1: Load Instruction

end IR_Behavorial;
