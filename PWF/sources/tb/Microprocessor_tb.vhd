library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =====================================================================
-- Microprocessor testbench -- srm_led_pulse
-- =====================================================================
-- Verificerer hele systemet (Datapath + MPC + RAM + PortReg + MUX_MR)
-- mod srm_led_pulse-programmet, som fylder LED'erne fra top og toemmer
-- dem igen i en evig loop. Forventet LED-sekvens per cyklus:
--   FILL : 0x80, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC, 0xFE, 0xFF
--   DRAIN: 0x7F, 0x3F, 0x1F, 0x0F, 0x07, 0x03, 0x01, 0x00
-- TB'en foelger 1,5 cyklus for ogsaa at faa wrap'et fra drain tilbage
-- til fill (validerer BRZ-stien efter drain_loop).
--
-- Programmet er injiceret i Ram256x16.vhd via:
--   python PWF/tools/asm/dsdasm.py asm srm_led_pulse.asm --vhdl Ram256x16.vhd
-- =====================================================================

entity Microprocessor_tb is
end Microprocessor_tb;

architecture TB of Microprocessor_tb is

    signal CLK    : STD_LOGIC := '0';
    signal RESET  : STD_LOGIC := '1';
    signal SW     : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal BTNC, BTNU, BTNL, BTNR, BTND : STD_LOGIC := '0';
    signal LED    : STD_LOGIC_VECTOR(7 downto 0);
    signal D_Word : STD_LOGIC_VECTOR(15 downto 0);

    constant CLK_PERIOD : time := 10 ns;
    -- Forventet LED-sekvens: fill, drain, fill (1,5 cyklus).
    -- Python-simulering: 0x80,0xC0,...,0xFF,0x7F,...,0x00,0x80,...,0xFF.
    type led_seq_t is array (natural range <>) of std_logic_vector(7 downto 0);
    constant EXPECTED_SEQ : led_seq_t := (
        -- fill #1
        x"80", x"C0", x"E0", x"F0", x"F8", x"FC", x"FE", x"FF",
        -- drain
        x"7F", x"3F", x"1F", x"0F", x"07", x"03", x"01", x"00",
        -- fill #2 (verificerer at programmet wrappet korrekt)
        x"80", x"C0", x"E0", x"F0", x"F8", x"FC", x"FE", x"FF"
    );

begin

    -- I simulering driver vi baade CLK og CLK_CPU fra samme signal.
    -- Paa boardet koerer CLK_CPU = CLK/2 (BUFG'et i TOP_MODUL_F).
    UUT: entity work.Microprocessor
        port map (
            CLK     => CLK,
            CLK_CPU => CLK,
            RESET   => RESET,
            SW      => SW,
            BTNC    => BTNC,
            BTNU    => BTNU,
            BTNL    => BTNL,
            BTNR    => BTNR,
            BTND    => BTND,
            LED     => LED,
            D_Word  => D_Word
        );

    clk_process: process
    begin
        CLK <= '0'; wait for CLK_PERIOD / 2;
        CLK <= '1'; wait for CLK_PERIOD / 2;
    end process;

    stim_process: process
        variable seq_idx : natural := 0;
        variable last_led : std_logic_vector(7 downto 0) := (others => '0');
    begin
        -- ============================================================
        -- Reset
        -- ============================================================
        RESET <= '1';
        wait for CLK_PERIOD * 5;
        RESET <= '0';
        wait for CLK_PERIOD * 2;

        assert LED = x"00"
            report "Efter reset: LED skal vaere 0x00"
            severity error;

        -- ============================================================
        -- Foelg pulse-progressionen: en gang hver gang LED skifter vaerdi
        -- sammenlignes med EXPECTED_SEQ. Timeout efter 50 us per skridt.
        -- ============================================================
        last_led := LED;
        while seq_idx < EXPECTED_SEQ'length loop
            wait until LED /= last_led for 50 us;
            exit when LED = last_led;  -- timeout: ingen aendring
            assert LED = EXPECTED_SEQ(seq_idx)
                report "Pulse step " & integer'image(seq_idx)
                     & " forkert: forventet "
                     & integer'image(to_integer(unsigned(EXPECTED_SEQ(seq_idx))))
                     & ", fik "
                     & integer'image(to_integer(unsigned(LED)))
                severity error;
            last_led := LED;
            seq_idx := seq_idx + 1;
        end loop;

        assert seq_idx = EXPECTED_SEQ'length
            report "Pulse stoppede for tidligt: kun " & integer'image(seq_idx)
                 & " ud af " & integer'image(EXPECTED_SEQ'length) & " skridt"
            severity error;

        report "=== srm_led_pulse: alle steps bestaaet ===" severity note;
        wait;
    end process;

end TB;
