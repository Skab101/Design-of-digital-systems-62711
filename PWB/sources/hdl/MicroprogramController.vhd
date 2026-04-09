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

architecture MCU_Structural of MicroprogramController is

    signal IR_sig       : std_logic_vector(15 downto 0);
    signal PS_sig       : std_logic_vector(1 downto 0);
    signal IL_sig       : std_logic;
    signal PC_sig       : std_logic_vector(7 downto 0);
    signal Extended_sig : std_logic_vector(7 downto 0);

begin

    PC_inst: entity work.ProgramCounter
    port map(
        RESET      => RESET,
        CLK        => CLK,
        Address_In => Address_In,
        PS         => PS_sig,
        Offset     => Extended_sig,
        PC         => PC_sig
    );

    IR_inst: entity work.InstructionRegister
    port map(
        RESET          => RESET,
        CLK            => CLK,
        Instruction_In => Instruction_In,
        IL             => IL_sig,
        IR             => IR_sig
    );

    SE_inst: entity work.SignExtender
    port map(
        IR         => IR_sig,
        Extended_8 => Extended_sig
    );

    ZF_inst: entity work.ZeroFiller
    port map(
        IR           => IR_sig,
        ZeroFilled_8 => Constant_Out
    );

    IDC_inst: entity work.InstructionDecoderController
    port map(
        RESET => RESET,
        CLK   => CLK,
        IR    => IR_sig,
        V     => V,
        C     => C,
        N     => N,
        Z     => Z,
        PS    => PS_sig,
        IL    => IL_sig,
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

    Address_Out <= PC_sig;

end MCU_Structural;
