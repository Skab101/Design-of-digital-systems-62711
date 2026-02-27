----------------------------------------------------------------------------------
-- Module Name: TOP_MODUL - Structural
-- Project:     PWA - ALU / DataPath
-- Board:       Nexys 4 DDR (Artix-7 xc7a100t)
-- Description: Top-level wrapper that maps FPGA board I/O to the Datapath
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TOP_MODUL is
    Port (
        CLK      : in  STD_LOGIC;
        RESET    : in  STD_LOGIC;
        SW       : in  STD_LOGIC_VECTOR(7 downto 0);
        LED      : out STD_LOGIC_VECTOR(7 downto 0);
        segments : out STD_LOGIC_VECTOR(6 downto 0);
        dp       : out STD_LOGIC;
        Anode    : out STD_LOGIC_VECTOR(7 downto 0);
        BTNC     : in  STD_LOGIC;
        BTNU     : in  STD_LOGIC;
        BTNL     : in  STD_LOGIC;
        BTNR     : in  STD_LOGIC;
        BTND     : in  STD_LOGIC
    );
end TOP_MODUL;

architecture Structural of TOP_MODUL is

    component Datapath is
        Port (RESET       : in  STD_LOGIC;
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
              V, C, N, Z  : out STD_LOGIC);
    end component;

begin

end Structural;
