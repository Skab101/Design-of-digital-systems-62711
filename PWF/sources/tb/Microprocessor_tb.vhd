library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =====================================================================
-- Microprocessor testbench -- sw_to_led
-- =====================================================================
-- Verificerer at hele systemet (Datapath + MPC + RAM + PortReg + MUX_MR)
-- kører sw_to_led-programmet korrekt:
--   1) Pulse BTNR med en SW-værdi -> MR3 latches
--   2) CPU'en loop'er og kopierer MR3 til MR2 (LED)
--   3) Vi læser LED tilbage og verificerer at det matcher SW
--
-- Programmet er DEC-baseret (bruger ikke SUB), så det virker uanset
-- om Cin = '0' eller Cin = FS_sig(0) i Microprocessor.vhd.
-- Ingen 7-seg writes, så D_Word forbliver 0x0000 hele kørselen.
--
-- Wave-tip: tilføj /Microprocessor_tb/UUT/Address_Out_PC til wave-viewet
-- for at se PC tælle 0,1,2,...,9 og hoppe tilbage til 1 ved JMP.
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
    constant LOOP_WAIT  : time := CLK_PERIOD * 100;

begin

    -- I simulering driver vi både CLK og CLK_CPU fra samme signal.
    -- På boardet kører CLK_CPU = CLK/2 (BUFG'et i TOP_MODUL_F).
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

        procedure press_button(
            signal btn   : out std_logic;
            constant val : in  std_logic_vector(7 downto 0)
        ) is
        begin
            wait until falling_edge(CLK);
            SW  <= val;
            btn <= '1';
            wait until rising_edge(CLK);
            wait for 1 ns;
            btn <= '0';
        end procedure;

    begin
        -- ============================================================
        -- Reset
        -- ============================================================
        RESET <= '1';
        wait for CLK_PERIOD * 5;
        RESET <= '0';
        wait for CLK_PERIOD * 2;

        assert LED = x"00"
            report "Efter reset: LED skal være 0x00"
            severity error;

        wait for LOOP_WAIT;

        -- ============================================================
        -- TEST 1: BTNR + SW=0x42 -> LED = 0x42
        -- ============================================================
        press_button(BTNR, x"42");
        wait for LOOP_WAIT;

        assert LED = x"42"
            report "TEST 1 fejlede: forventet LED = 0x42 efter BTNR med SW=0x42"
            severity error;

        -- ============================================================
        -- TEST 2: BTNR + SW=0xA5 -> LED = 0xA5 (tester JMP-loop)
        -- ============================================================
        press_button(BTNR, x"A5");
        wait for LOOP_WAIT;

        assert LED = x"A5"
            report "TEST 2 fejlede: forventet LED = 0xA5 efter ny BTNR-pulse (kræver at JMP-loop'et virker)"
            severity error;

        -- ============================================================
        -- TEST 3: BTNL + SW=0x99 -> LED stadig 0xA5
        -- (BTNL latcher MR4, ikke MR3 -- programmet rører ikke MR4)
        -- ============================================================
        press_button(BTNL, x"99");
        wait for LOOP_WAIT;

        assert LED = x"A5"
            report "TEST 3 fejlede: LED skal være uændret 0xA5 (BTNL latcher MR4, ikke MR3)"
            severity error;

        -- ============================================================
        -- TEST 4: BTNR + SW=0xFF -> alle LEDs tændt
        -- ============================================================
        press_button(BTNR, x"FF");
        wait for LOOP_WAIT;

        assert LED = x"FF"
            report "TEST 4 fejlede: forventet LED = 0xFF (alle tændt)"
            severity error;

        -- ============================================================
        -- TEST 5: BTNR + SW=0x00 -> alle LEDs slukket
        -- ============================================================
        press_button(BTNR, x"00");
        wait for LOOP_WAIT;

        assert LED = x"00"
            report "TEST 5 fejlede: forventet LED = 0x00 (alle slukket)"
            severity error;

        report "=== Alle Microprocessor sw_to_led tests bestået ===" severity note;
        wait;
    end process;

end TB;
