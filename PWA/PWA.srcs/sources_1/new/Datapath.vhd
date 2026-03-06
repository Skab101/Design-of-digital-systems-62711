----------------------------------------------------------------------------------
-- Module Name: Datapath
-- Description: Top-level PWA Datapath (figure PWA-1)
--              Structural: instantiates RegisterFile, FunctionUnit,
--              MUXB (ConstantIn vs B_Data), and MUXD (F vs DataIn)
--
--              Signal flow:
--                RegisterFile -> A_Data -> FunctionUnit input A, Address_Out
--                RegisterFile -> B_Data -> MUXB input R, Data_Out
--                MUXB output  -> FunctionUnit input B
--                FunctionUnit -> F -> MUXD input R
--                MUXD output  -> RegisterFile D_Data (write-back)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Datapath is
    Port (
        RESET       : in  STD_LOGIC;
        CLK         : in  STD_LOGIC;
        RW          : in  STD_LOGIC;
        DA, AA, BA  : in  STD_LOGIC_VECTOR(3 downto 0);
        ConstantIn  : in  STD_LOGIC_VECTOR(7 downto 0);
        MB          : in  STD_LOGIC;
        FS3, FS2, FS1, FS0 : in  STD_LOGIC;
        Cin         : in  STD_LOGIC;
        DataIn      : in  STD_LOGIC_VECTOR(7 downto 0);
        MD          : in  STD_LOGIC;
        Address_Out : out STD_LOGIC_VECTOR(7 downto 0);
        Data_Out    : out STD_LOGIC_VECTOR(7 downto 0);
        V, C, N, Z  : out STD_LOGIC
    );
end Datapath;

architecture structural of Datapath is

    component RegisterFile is
        Port (RESET  : in  STD_LOGIC;
              CLK    : in  STD_LOGIC;
              RW     : in  STD_LOGIC;
              DA, AA, BA : in  STD_LOGIC_VECTOR(3 downto 0);
              D_Data : in  STD_LOGIC_VECTOR(7 downto 0);
              A_Data, B_Data : out STD_LOGIC_VECTOR(7 downto 0));
    end component;

    component FunctionUnit is
        Port (A, B                    : in  STD_LOGIC_VECTOR(7 downto 0);
              FS3, FS2, FS1, FS0, Cin : in  STD_LOGIC;
              V, C, N, Z             : out STD_LOGIC;
              F                      : out STD_LOGIC_VECTOR(7 downto 0));
    end component;

    component MUX2x1x8 is
        Port (J, H       : in  STD_LOGIC_VECTOR(7 downto 0);
              MF         : in  STD_LOGIC;
              Y          : out STD_LOGIC_VECTOR(7 downto 0));
    end component;

    -- Internal buses
    signal A_Data   : STD_LOGIC_VECTOR(7 downto 0);  -- RF read port A
    signal B_Data   : STD_LOGIC_VECTOR(7 downto 0);  -- RF read port B
    signal Bus_B    : STD_LOGIC_VECTOR(7 downto 0);  -- MUXB output -> FU input B
    signal F_Out    : STD_LOGIC_VECTOR(7 downto 0);  -- FU result
    signal D_Data   : STD_LOGIC_VECTOR(7 downto 0);  -- MUXD output -> RF write data

begin

    -- (1) Register File: 16x8-bit with dual read ports
    RF: RegisterFile port map (
        RESET  => RESET,
        CLK    => CLK,
        RW     => RW,
        DA     => DA,
        AA     => AA,
        BA     => BA,
        D_Data => D_Data,
        A_Data => A_Data,
        B_Data => B_Data
    );

    -- (3) MUXB: selects between B_Data (MB=0) and ConstantIn (MB=1)
    MUXB: MUX2x1x8 port map (
        J  => B_Data,
        H  => ConstantIn,
        MF => MB,
        Y  => Bus_B
    );

    -- (2) Function Unit: ALU + Shifter + flags
    FU: FunctionUnit port map (
        A   => A_Data,
        B   => Bus_B,
        FS3 => FS3,
        FS2 => FS2,
        FS1 => FS1,
        FS0 => FS0,
        Cin => Cin,
        V   => V,
        C   => C,
        N   => N,
        Z   => Z,
        F   => F_Out
    );

    -- (3) MUXD: selects between F (MD=0) and DataIn (MD=1)
    MUXD: MUX2x1x8 port map (
        J  => F_Out,
        H  => DataIn,
        MF => MD,
        Y  => D_Data
    );

    -- Output connections (directly from register file read ports)
    Address_Out <= A_Data;
    Data_Out    <= B_Data;

end structural;
