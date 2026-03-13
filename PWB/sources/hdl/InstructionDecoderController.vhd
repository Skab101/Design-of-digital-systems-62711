library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity InstructionDecoderController is
    port (
        RESET              : in  std_logic;
        CLK                : in  std_logic;
        IR                 : in  std_logic_vector(15 downto 0);
        V, C, N, Z         : in  std_logic;
        PS                 : out std_logic_vector(1 downto 0);
        IL                 : out std_logic;
        DX, AX, BX, FS    : out std_logic_vector(3 downto 0);
        MB, MD, RW, MM, MW : out std_logic
    );
end InstructionDecoderController;

architecture IDC_Behavorial of InstructionDecoderController is
begin

    -- TODO: Define state type (INF, EX0, EX1, EX2, EX3, EX4)
    -- TODO: Define current_state and next_state signals

    -- TODO: Process 1 - State register (sequential: CLK, RESET)

    -- TODO: Process 2 - Next state logic + output logic (combinatorial)
    --       Inputs:  current_state, opcode (IR(15 downto 9)), V, C, N, Z
    --       Outputs: next_state, PS, IL, DX, AX, BX, MB, FS, MD, RW, MM, MW
    --       Use transition table from page 2 of the project description
    --
    -- TIP: Use a case-in-case structure:
    --   case current_state is
    --       when INF =>
    --           -- set INF outputs (fetch)
    --       when EX0 =>
    --           case opcode is
    --               when "0000000" => -- MOVA
    --               when "0000010" => -- ADD
    --               ...
    --           end case;
    --       when EX1 =>
    --           case opcode is
    --               ...
    --           end case;
    --       ...
    --   end case;

end IDC_Behavorial;
