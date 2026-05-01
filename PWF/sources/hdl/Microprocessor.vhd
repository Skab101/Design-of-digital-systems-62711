library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Top-level Microprocessor: Datapath + Microprogram Controller + RAM + Port Register + MUX MR
-- This is the core system (excluding the board-level TOP_MODUL wrapper)
entity Microprocessor is
    port (
        CLK      : in  STD_LOGIC;
        RESET    : in  STD_LOGIC;
        -- Board peripherals (exposed through Port Register)
        SW       : in  STD_LOGIC_VECTOR(7 downto 0);
        BTNC     : in  STD_LOGIC;
        BTNU     : in  STD_LOGIC;
        BTNL     : in  STD_LOGIC;
        BTNR     : in  STD_LOGIC;
        BTND     : in  STD_LOGIC;
        LED      : out STD_LOGIC_VECTOR(7 downto 0);
        D_Word   : out STD_LOGIC_VECTOR(15 downto 0)  -- drives 7-seg via TOP_MODUL_F
    );
end Microprocessor;

architecture MP_Structural of Microprocessor is

    -- Control signals from MPC to Datapath
    signal DX_sig, AX_sig, BX_sig, FS_sig : STD_LOGIC_VECTOR(3 downto 0);
    signal MB_sig, MD_sig, RW_sig         : STD_LOGIC;
    signal MM_sig, MW_sig                 : STD_LOGIC;

    -- MPC <-> Datapath data/address
    signal Address_Out_DP  : STD_LOGIC_VECTOR(7 downto 0);  -- from Datapath
    signal Address_Out_PC  : STD_LOGIC_VECTOR(7 downto 0);  -- from MPC (PC)
    signal Data_Out_DP     : STD_LOGIC_VECTOR(7 downto 0);  -- from Datapath to memory
    signal Constant_Out    : STD_LOGIC_VECTOR(7 downto 0);  -- from MPC (ZeroFiller)

    -- Status flags
    signal V_sig, C_sig, N_sig, Z_sig : STD_LOGIC;

    -- MUX M: selects between Datapath address (MM=0) and PC (MM=1)
    signal Mem_Address : STD_LOGIC_VECTOR(7 downto 0);

    -- RAM and PortReg outputs
    signal Data_outM    : STD_LOGIC_VECTOR(15 downto 0);
    signal Data_outR    : STD_LOGIC_VECTOR(15 downto 0);
    signal MMR_sig      : STD_LOGIC;

    -- MUX MR output (goes to Datapath DataIn and MPC Instruction_In)
    signal Data_Bus_Out : STD_LOGIC_VECTOR(15 downto 0);

    -- Zero-filled 16-bit Data_In for RAM (from Datapath's 8-bit output)
    signal Data_In_RAM  : STD_LOGIC_VECTOR(15 downto 0);

begin

    -- ==========================================================
    -- MUX M: vaelger memory-adressen
    --   MM='1' -> instruktions-fetch, brug PC (Address_Out_PC)
    --   MM='0' -> operand-adgang,    brug Datapath (Address_Out_DP)
    -- ==========================================================
    Mem_Address <= Address_Out_PC when MM_sig = '1' else Address_Out_DP;

    -- ==========================================================
    -- Zero Filler: 8-bit Data_Out fra Datapath -> 16-bit til RAM/PortReg
    -- Den oeverste byte saettes til 0; lav byte indeholder data.
    -- ==========================================================
    ZF_inst : entity work.Zero_Filler_2
        port map (
            Data_Out => Data_Out_DP,
            Data_ZF  => Data_In_RAM
        );

    -- ==========================================================
    -- Datapath (PWA): register file + ALU + flags
    -- Cin er ikke leveret af MPC; tied til '0'. Det betyder at
    -- SUB/ADC-instruktioner ikke virker, men ADD/LD/ST/JMP gor.
    -- ==========================================================
    DP_inst : entity work.Datapath
        port map (
            RESET       => RESET,
            CLK         => CLK,
            RW          => RW_sig,
            DA          => DX_sig,
            AA          => AX_sig,
            BA          => BX_sig,
            ConstantIn  => Constant_Out,
            MB          => MB_sig,
            FS3         => FS_sig(3),
            FS2         => FS_sig(2),
            FS1         => FS_sig(1),
            FS0         => FS_sig(0),
            Cin         => '0',
            DataIn      => Data_Bus_Out(7 downto 0),
            MD          => MD_sig,
            Address_Out => Address_Out_DP,
            Data_Out    => Data_Out_DP,
            V           => V_sig,
            C           => C_sig,
            N           => N_sig,
            Z           => Z_sig
        );

    -- ==========================================================
    -- Microprogram Controller (PWB): IR + PC + IDC + ZF + SE
    -- ==========================================================
    MPC_inst : entity work.MicroprogramController
        port map (
            RESET          => RESET,
            CLK            => CLK,
            Address_In     => Address_Out_DP,
            Address_Out    => Address_Out_PC,
            Instruction_In => Data_Bus_Out,
            Constant_Out   => Constant_Out,
            V              => V_sig,
            C              => C_sig,
            N              => N_sig,
            Z              => Z_sig,
            DX             => DX_sig,
            AX             => AX_sig,
            BX             => BX_sig,
            FS             => FS_sig,
            MB             => MB_sig,
            MD             => MD_sig,
            RW             => RW_sig,
            MM             => MM_sig,
            MW             => MW_sig
        );

    -- ==========================================================
    -- 256 x 16 RAM med microcode i INIT
    -- ==========================================================
    RAM_inst : entity work.Ram256x16
        port map (
            clk        => CLK,
            Reset      => RESET,
            Data_in    => Data_In_RAM,
            Address_in => Mem_Address,
            MW         => MW_sig,
            Data_out   => Data_outM
        );

    -- ==========================================================
    -- Port Register: memory-mapped I/O paa 0xF8..0xFF
    -- ==========================================================
    PR_inst : entity work.PortReg8x8
        port map (
            clk        => CLK,
            MW         => MW_sig,
            RESET      => RESET,
            Data_In    => Data_In_RAM,
            Address_in => Mem_Address,
            SW         => SW,
            BTNC       => BTNC,
            BTNU       => BTNU,
            BTNL       => BTNL,
            BTNR       => BTNR,
            BTND       => BTND,
            MMR        => MMR_sig,
            D_word     => D_Word,
            Data_outR  => Data_outR,
            LED        => LED
        );

    -- ==========================================================
    -- MUX MR: vaelger mellem RAM- og PortReg-output
    --   MMR='0' -> RAM     (Data_outM)
    --   MMR='1' -> PortReg (Data_outR)
    -- ==========================================================
    MUXMR_inst : entity work.MUX_MR
        port map (
            Data_outM    => Data_outM,
            Data_outR    => Data_outR,
            MMR          => MMR_sig,
            Data_Bus_Out => Data_Bus_Out
        );

end MP_Structural;
