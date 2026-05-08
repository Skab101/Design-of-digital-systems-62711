library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Board-level top module for the Nexys 4 DDR.
-- Wraps the Microprocessor core and connects it to the physical pins
-- (constraints in Nexys_4_DDR_Master.xdc).
--
-- RESETN er active-low (matcher boardets CPU_RESETN-pin: '1' i hvile,
-- '0' når der trykkes). Internt bruger alle CPU-modulerne active-high
-- RESET, så vi inverterer RESETN her i toppen.
entity TOP_MODUL_F is
    port (
        CLK      : in  STD_LOGIC;
        RESETN   : in  STD_LOGIC;                       -- active-low (CPU_RESETN)
        SW       : in  STD_LOGIC_VECTOR(7 downto 0);
        BTNC     : in  STD_LOGIC;
        BTNU     : in  STD_LOGIC;
        BTNL     : in  STD_LOGIC;
        BTNR     : in  STD_LOGIC;
        BTND     : in  STD_LOGIC;
        LED      : out STD_LOGIC_VECTOR(7 downto 0);
        segments : out STD_LOGIC_VECTOR(6 downto 0);
        dp       : out STD_LOGIC;
        Anode    : out STD_LOGIC_VECTOR(7 downto 0)
    );
end TOP_MODUL_F;

architecture TOP_Structural of TOP_MODUL_F is

    -- Active-high RESET internt i designet
    signal RESET_int  : STD_LOGIC;

    -- 16-bit display-ord fra Microprocessor til SevenSegDriver:
    -- D_Word_sig(15:8) = MR1 (høje 7-seg cifre)
    -- D_Word_sig(7:0)  = MR0 (lave 7-seg cifre)
    signal D_Word_sig : STD_LOGIC_VECTOR(15 downto 0);

begin

    -- Inverter active-low boards-reset til active-high intern reset
    RESET_int <= not RESETN;

    -- ==========================================================
    -- Microprocessor core: hele CPU + RAM + PortReg + bus-mux
    -- ==========================================================
    CPU_inst : entity work.Microprocessor
        port map (
            CLK    => CLK,
            RESET  => RESET_int,
            SW     => SW,
            BTNC   => BTNC,
            BTNU   => BTNU,
            BTNL   => BTNL,
            BTNR   => BTNR,
            BTND   => BTND,
            LED    => LED,
            D_Word => D_Word_sig
        );

    -- ==========================================================
    -- SevenSegDriver: viser D_Word på de fire højre 7-seg cifre
    -- ==========================================================
    SSD_inst : entity work.SevenSegDriver
        port map (
            clk      => CLK,
            reset    => RESET_int,
            D_Word   => D_Word_sig,
            segments => segments,
            dp       => dp,
            Anode    => Anode
        );

end TOP_Structural;
