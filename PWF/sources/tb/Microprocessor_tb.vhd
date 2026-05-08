library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Top-level Microprocessor testbench
--
-- Verificerer at hele systemet (Datapath + MPC + RAM + PortReg + MUX_MR)
-- kører switch_echo-programmet i RAM korrekt:
--   1) Sæt SW og pulse BTNC -> MR7 latches SW
--   2) CPU'en loop'er konstant og kopierer MR7 til:
--        - LED       (MR2)
--        - 7-seg low (MR0)
--   3) Vi læser LED og D_Word(7:0) tilbage og verificerer at de matcher SW
--
-- BTNR/BTNL/BTND/BTNU bruges IKKE af programmet -- TB tester også at en
-- pulse på BTNR ikke ændrer LED (MR3 bliver latched, men programmet
-- læser kun MR7).
--
-- D_Word(15:8) er IKKE verificeret -- programmet skriver ikke til MR1,
-- så de øverste 7-seg cifre forbliver blanke. Det er bevidst i denne
-- enkle demo.
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

    -- En fuld iteration af switch_echo-loop'et er ca. 10-12 klokker
    -- (1x LD + 2x ST + 1x JMP, hver 2-3 cyklusser). Vi venter generøst
    -- så output når at stabilisere.
    constant LOOP_WAIT : time := CLK_PERIOD * 200;

begin

    -- I simulering driver vi både CLK og CLK_CPU fra samme signal -- vi vil
    -- verificere at omkoblingen til to-klok-interfacet er korrekt, og
    -- DivClk'en selv er triviel nok til ikke at kræve sit eget testbench.
    -- På boardet kører CLK_CPU = CLK/2 (BUFG'et) men funktionel korrekthed
    -- afhænger ikke af det.
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

        -- Pulser en knap i én klokcyklus med given SW-værdi
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
        -- ============================================
        -- Reset
        -- ============================================
        RESET <= '1';
        wait for CLK_PERIOD * 5;
        RESET <= '0';
        wait for CLK_PERIOD;

        -- ============================================
        -- TEST 1: SW=0x42, BTNC pulse -> LED og 7-seg low = 0x42
        -- ============================================
        press_button(BTNC, x"42");
        wait for LOOP_WAIT;

        assert LED = x"42"
            report "TEST 1 LED fejlede: forventet 0x42 (SW echo via BTNC)"
            severity error;

        assert D_Word(7 downto 0) = x"42"
            report "TEST 1 D_Word(7:0) fejlede: forventet 0x42 (SW echo på 7-seg low)"
            severity error;

        -- ============================================
        -- TEST 2: SW=0xA5, ny BTNC pulse -> display opdateres
        -- ============================================
        press_button(BTNC, x"A5");
        wait for LOOP_WAIT;

        assert LED = x"A5"
            report "TEST 2 LED fejlede: forventet 0xA5 efter ny BTNC pulse"
            severity error;

        -- ============================================
        -- TEST 3: SW=0x99 + BTNR pulse -> LED holder 0xA5
        -- (BTNR latcher MR3, ikke MR7 -- programmet læser kun MR7)
        -- ============================================
        press_button(BTNR, x"99");
        wait for LOOP_WAIT;

        assert LED = x"A5"
            report "TEST 3 LED fejlede: forventet 0xA5 (uændret -- BTNR ændrer ikke MR7)"
            severity error;

        -- ============================================
        -- TEST 4: SW=0xFF, BTNC pulse -> alle LED tændt
        -- ============================================
        press_button(BTNC, x"FF");
        wait for LOOP_WAIT;

        assert LED = x"FF"
            report "TEST 4 LED fejlede: forventet 0xFF"
            severity error;

        report "=== Alle Microprocessor switch_echo tests bestået ===" severity note;
        wait;
    end process;

end TB;
