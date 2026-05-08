library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Xilinx primitive-bibliotek til BUFG (global clock buffer) på CPU-klokken.
library UNISIM;
use UNISIM.vcomponents.all;

-- Board-level top module for the Nexys 4 DDR.
-- Wraps the Microprocessor core and connects it to the physical pins
-- (constraints in Nexys_4_DDR_Master.xdc).
--
-- RESET er bundet til boardets CPU_RESETN-pin (C12) som er active-low:
-- '1' i hvile, '0' når der trykkes. Internt bruger alle CPU-modulerne
-- active-high reset, så vi inverterer her i toppen.
--
-- Klokdomæner:
--   CLK     -- 100 MHz board-klok. Driver BRAM (Ram256x16) og SevenSegDriver.
--   CPU_CLK -- divideret klok fra DivClk (TimeP=1 -> CLK/2 = 50 MHz). Driver
--              CPU-logikken (Datapath, MPC, PortReg) inde i Microprocessor.
--              Routes gennem BUFG så den lander på det globale klok-netværk
--              og er fasesynkront afledt af CLK.
entity TOP_MODUL_F is
    port (
        CLK      : in  STD_LOGIC;
        RESET    : in  STD_LOGIC;                       -- active-low (bundet til CPU_RESETN)
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

    -- Divideret CPU-klok: rå udgang fra DivClk og BUFG-bufret version.
    signal CPU_CLK_pre : STD_LOGIC;
    signal CPU_CLK     : STD_LOGIC;

    -- Dele-faktor for CPU-klokken. TimeP=1 giver CLK/2 = 50 MHz.
    -- Sæt højere for langsommere CPU (god til at se enkelte instruktioner
    -- på 7-seg/LED). Frekvens = CLK / (2 * (TimeP/2 + 1)) for TimeP >= 2;
    -- TimeP = 1 er specialtilfældet hvor Clk1 = Clk/2.
    constant CPU_DIV : integer := 1;

begin

    -- Inverter active-low boards-reset til active-high intern reset
    RESET_int <= not RESET;

    -- ==========================================================
    -- Klokdivider: laver CPU_CLK_pre = CLK / (2*(CPU_DIV/2 + 1))
    -- ==========================================================
    DivClk_inst : entity work.DivClk
        port map (
            Reset => RESET_int,
            Clk   => CLK,
            TimeP => CPU_DIV,
            Clk1  => CPU_CLK_pre
        );

    -- BUFG bringer den dividerede klok ind på det globale klok-netværk,
    -- så Vivado kan style timing korrekt og skew holdes lavt.
    BUFG_CPU : BUFG
        port map (
            I => CPU_CLK_pre,
            O => CPU_CLK
        );

    -- ==========================================================
    -- Microprocessor core: hele CPU + RAM + PortReg + bus-mux
    -- RAM kører på fuld CLK; resten på CPU_CLK.
    -- ==========================================================
    CPU_inst : entity work.Microprocessor
        port map (
            CLK     => CLK,
            CLK_CPU => CPU_CLK,
            RESET   => RESET_int,
            SW      => SW,
            BTNC    => BTNC,
            BTNU    => BTNU,
            BTNL    => BTNL,
            BTNR    => BTNR,
            BTND    => BTND,
            LED     => LED,
            D_Word  => D_Word_sig
        );

    -- ==========================================================
    -- SevenSegDriver: viser D_Word på de fire højre 7-seg cifre.
    -- Kører på fuld CLK for stabil ~380 Hz refresh per digit.
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
