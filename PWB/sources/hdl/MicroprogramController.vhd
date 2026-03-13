library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MicroprogramController is
    port (
        RESET              : in  std_logic;
        CLK                : in  std_logic;
        Address_In         : in  std_logic_vector(7 downto 0);
        Address_Out        : out std_logic_vector(7 downto 0);
        Instruction_In     : in  std_logic_vector(15 downto 0);
        Constant_Out       : out std_logic_vector(7 downto 0);
        V, C, N, Z         : in  std_logic;
        DX, AX, BX, FS    : out std_logic_vector(3 downto 0);
        MB, MD, RW, MM, MW : out std_logic
    );
end MicroprogramController;

architecture MCU_Behavorial of MicroprogramController is

    -- TODO: Declare internal signals to wire submodules together

begin

    -- TODO: Instantiate ProgramCounter              (1)
    -- TODO: Instantiate InstructionRegister          (2)
    -- TODO: Instantiate SignExtender
    -- TODO: Instantiate ZeroFiller
    -- TODO: Instantiate InstructionDecoderController (3)
    -- TODO: Wire Constant_Out from ZeroFiller output

end MCU_Behavorial;
