library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Top-level Microprocessor testbench
--
-- Verificerer at hele systemet (Datapath + MPC + RAM + PortReg + MUX_MR)
-- koerer sum_demo-programmet i RAM korrekt:
--   1) BTNR-tryk med SW = operand A latcher MR3
--   2) BTNL-tryk med SW = operand B latcher MR4
--   3) Programmet beregner R6 = MR3 + MR4 i sin loop og skriver:
--        - LED      <- R6  (MR2)
--        - 7-seg lav <- R6  (MR0)
--   4) Vi laeser LED og D_Word(7:0) tilbage og verificerer summen.
--
-- D_Word(15:8) er IKKE verificeret -- pga MR1-byte-konventionen
-- (MR1 latcher Data_In(15:8) men Zero_Filler_2 saetter den til 0)
-- forbliver de oeverste 7-seg-cifre blanke. Det er en kendt
-- begraensning i den nuvaerende design og er udenfor denne TB's scope.
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

    -- En fuld iteration af sum_demo-loop'et er ca. 40 klokker
    -- (5x LDI + 6x LD + 1x ADD + 3x ST + 1x JMP, hver 2-3 cyklusser).
    -- Vi venter generoest saa output naar at stabilisere.
    constant LOOP_WAIT : time := CLK_PERIOD * 300;

begin

    UUT: entity work.Microprocessor
        port map (
            CLK    => CLK,
            RESET  => RESET,
            SW     => SW,
            BTNC   => BTNC,
            BTNU   => BTNU,
            BTNL   => BTNL,
            BTNR   => BTNR,
            BTND   => BTND,
            LED    => LED,
            D_Word => D_Word
        );

    clk_process: process
    begin
        CLK <= '0'; wait for CLK_PERIOD / 2;
        CLK <= '1'; wait for CLK_PERIOD / 2;
    end process;

    stim_process: process

        -- Pulser en knap i én klokcyklus med given SW-vaerdi
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
        -- TEST 1: 0x10 + 0x05 = 0x15
        -- ============================================
        press_button(BTNR, x"10");   -- MR3 <- 0x10 (operand A)
        press_button(BTNL, x"05");   -- MR4 <- 0x05 (operand B)
        wait for LOOP_WAIT;

        assert LED = x"15"
            report "TEST 1 LED fejlede: forventet 0x15 (0x10+0x05) - se LED i wave"
            severity error;

        assert D_Word(7 downto 0) = x"15"
            report "TEST 1 D_Word(7:0) fejlede: forventet 0x15 (sum paa 7-seg low) - se D_Word i wave"
            severity error;

        -- ============================================
        -- TEST 2: skift operand A til 0x20, summen skal opdateres
        -- 0x20 + 0x05 = 0x25
        -- ============================================
        press_button(BTNR, x"20");
        wait for LOOP_WAIT;

        assert LED = x"25"
            report "TEST 2 LED fejlede: forventet 0x25 (0x20+0x05) - se LED i wave"
            severity error;

        -- ============================================
        -- TEST 3: skift operand B til 0x33
        -- 0x20 + 0x33 = 0x53
        -- ============================================
        press_button(BTNL, x"33");
        wait for LOOP_WAIT;

        assert LED = x"53"
            report "TEST 3 LED fejlede: forventet 0x53 (0x20+0x33) - se LED i wave"
            severity error;

        -- ============================================
        -- TEST 4: 8-bit overflow (255 + 1 = 0)
        -- 0xFF + 0x01 = 0x100 -> trunceres til 0x00 i 8-bit ALU
        -- ============================================
        press_button(BTNR, x"FF");
        press_button(BTNL, x"01");
        wait for LOOP_WAIT;

        assert LED = x"00"
            report "TEST 4 LED fejlede: forventet 0x00 (0xFF+0x01 = overflow) - se LED i wave"
            severity error;

        report "=== Alle Microprocessor sum_demo tests bestaaet ===" severity note;
        wait;
    end process;

end TB;
