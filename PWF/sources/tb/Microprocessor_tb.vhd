library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Top-level Microprocessor testbench -- teammate's wrong code
--
-- Programmet i RAM er teammate_wrong.asm. Det HER TB tester den ADFAERD
-- TEAMMATE'EN INTENDEREDE (SW -> LED + 7-seg, looper på BTNR-tryk),
-- så fejlede assertions afslører fejlene i programmet.
--
-- Forventede fejl ved kørsel:
--   - TEST 1 LED  : burde virke (programmet skriver LED korrekt før den
--                   gale JMP)
--   - TEST 1 7seg : FEJL -- programmet skriver aldrig MR0/MR1
--   - TEST 2 LED  : FEJL -- JMP'en hopper til 0xF9 (I/O-space) i stedet
--                   for tilbage til programstart, så CPU'en eksekverer
--                   I/O-registre som instruktioner og bliver korrupt.
--                   Anden BTNR-tryk propageres derfor ikke.
--   - TEST 2 7seg : FEJL -- som ovenfor + ingen MR0-skrivning
--
-- Prøv at åbne wave-viewet og se PC, R-registre og MR-registre over tid
-- for at se præcis hvor det går galt.

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
    constant LOOP_WAIT  : time := CLK_PERIOD * 300;

begin

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
        -- ============================================
        -- Reset
        -- ============================================
        RESET <= '1';
        wait for CLK_PERIOD * 5;
        RESET <= '0';
        wait for CLK_PERIOD;

        -- ============================================
        -- TEST 1: SW=0x42 + BTNR -> intenderet: LED=0x42, D_Word=0x0042
        -- Forventet udfald:
        --   LED  = 0x42  (PASS -- programmet når at skrive LED)
        --   7seg = 0x42  (FAIL -- programmet skriver aldrig MR0)
        -- ============================================
        press_button(BTNR, x"42");
        wait for LOOP_WAIT;

        assert LED = x"42"
            report "TEST 1 LED fejlede: forventet 0x42 (programmet burde skrive LED)"
            severity error;

        assert D_Word(7 downto 0) = x"42"
            report "TEST 1 7-seg fejlede: forventet 0x42 -- programmet skriver aldrig MR0/MR1, så 7-seg er blank. BUG: mangler ST'er til 0xF8/0xF9 efter NOT/INC."
            severity error;

        -- ============================================
        -- TEST 2: SW=0xA5 + BTNR -> intenderet: LED=0xA5
        -- Forventet udfald:
        --   LED forventes 0xA5, men hvis JMP-bug'en gør CPU'en
        --   korrupt, kan det vaere noget andet.
        -- ============================================
        press_button(BTNR, x"A5");
        wait for LOOP_WAIT;

        assert LED = x"A5"
            report "TEST 2 LED fejlede: forventet 0xA5 efter ny BTNR-tryk. BUG: JMP R7 (R7=0xF9) hopper til I/O-space i stedet for at loope tilbage til programstart."
            severity error;

        assert D_Word(7 downto 0) = x"A5"
            report "TEST 2 7-seg fejlede: forventet 0xA5 -- programmet skriver aldrig MR0/MR1."
            severity error;

        -- ============================================
        -- TEST 3: SW=0xFF + BTNR -> intenderet: LED=0xFF
        -- ============================================
        press_button(BTNR, x"FF");
        wait for LOOP_WAIT;

        assert LED = x"FF"
            report "TEST 3 LED fejlede: forventet 0xFF -- bekraefter at loop'et er broken (samme JMP-bug som TEST 2)."
            severity error;

        report "=== TB faerdig -- tjek hvilke assertions der fejlede for at se bug-summary ===" severity note;
        wait;
    end process;

end TB;
