----------------------------------------------------------------------------------
-- Module Name: Datapath
-- Description: Top-level PWA Datapath
--              Structural: instantiates RegisterFile, FunctionUnit,
--              MUXB (Constant_In vs B_Data), and MUXD (F vs DataIn)
--              This is the complete datapath per figure PWA-1
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
        Port (A, B             : in  STD_LOGIC_VECTOR(7 downto 0);
              FS3, FS2, FS1, FS0 : in  STD_LOGIC;
              V, C, N, Z       : out STD_LOGIC;
              F                : out STD_LOGIC_VECTOR(7 downto 0));
    end component;

    component MUX2x1x8 is
        Port (R, S       : in  STD_LOGIC_VECTOR(7 downto 0);
              MUX_Select : in  STD_LOGIC;
              Y          : out STD_LOGIC_VECTOR(7 downto 0));
    end component;

begin

end structural;
