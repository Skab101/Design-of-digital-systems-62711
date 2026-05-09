library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Testbench for PortReg8x8 -- følger flowet fra timing-diagrammet.
-- Spec siger (PWF, p.1): "For the data, only the 8 lowest bits (low byte)
-- are used". Datapath outputtet er 8-bit, og Zero_Filler_2 i toppen padder
-- de oeverste 8 bit til 0. Saa ALLE MR-skrivninger laeser Data_In(7:0).
-- Vi tester at high-byten i Data_In ignoreres ved at saette den til noget
-- ikke-nul.
--
--   1) Skriv F8 <- 0xAB34   -> MR0 = 0x34   (low byte; 0xAB high ignoreres)
--   2) Skriv F9 <- 0xCD12   -> MR1 = 0x12   (low byte; 0xCD high ignoreres)
--                              D_word skal nu vaere 0x1234
--   3) Skriv FA <- 0xABCD   -> MR2 = 0xCD   (low byte)
--   4) Laes FA               -> Data_outR = 0x00CD
--   5) BTNR pulse, SW=0x5A   -> MR3 = 0x5A
--   6) Laes FB               -> Data_outR = 0x005A
--   7) RESET                 -> alle registre = 0
entity PortReg8x8_tb is
end PortReg8x8_tb;

architecture TB of PortReg8x8_tb is

    signal clk        : std_logic := '0';
    signal MW         : std_logic := '0';
    signal RESET      : std_logic := '0';
    signal Data_In    : std_logic_vector(15 downto 0) := (others => '0');
    signal Address_in : std_logic_vector(7 downto 0)  := (others => '0');
    signal SW         : std_logic_vector(7 downto 0)  := (others => '0');
    signal BTNC       : std_logic := '0';
    signal BTNU       : std_logic := '0';
    signal BTNL       : std_logic := '0';
    signal BTNR       : std_logic := '0';
    signal BTND       : std_logic := '0';
    signal MMR        : std_logic;
    signal D_word     : std_logic_vector(15 downto 0);
    signal Data_outR  : std_logic_vector(15 downto 0);
    signal LED        : std_logic_vector(7 downto 0);

    constant CLK_PERIOD : time := 10 ns;

begin

    UUT: entity work.PortReg8x8
        port map (
            clk        => clk,
            MW         => MW,
            RESET      => RESET,
            Data_In    => Data_In,
            Address_in => Address_in,
            SW         => SW,
            BTNC       => BTNC,
            BTNU       => BTNU,
            BTNL       => BTNL,
            BTNR       => BTNR,
            BTND       => BTND,
            MMR        => MMR,
            D_word     => D_word,
            Data_outR  => Data_outR,
            LED        => LED
        );

    clk_process: process
    begin
        clk <= '0'; wait for CLK_PERIOD / 2;
        clk <= '1'; wait for CLK_PERIOD / 2;
    end process;

    -- Stimulus følger timing-diagrammet præcist:
    -- alle skifte sker på faldende kant, så data er stabile inden næste stigende kant latcher.
    stim_process: process
    begin
        -- Initial RESET puls så alle MR(*) starter på 0 (i stedet for 'U')
        RESET <= '1';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        RESET <= '0';

        -- ============================================
        -- Skrive-cyklus 1: MW pulse, F8 <- 0xAB34  (MR0 <- 0x34)
        -- High byte 0xAB skal ignoreres (spec: kun low byte bruges).
        -- ============================================
        MW         <= '1';
        Address_in <= x"F8";
        Data_In    <= x"AB34";
        wait until rising_edge(clk);   -- latcher MR0
        wait for 1 ns;
        assert D_word(7 downto 0) = x"34"
            report "MR0 fejlede: D_word(7:0) skulle vaere 34"
            severity error;

        -- MW slip mellem skrivninger (data_write -> 00)
        wait until falling_edge(clk);
        MW <= '0';
        wait until rising_edge(clk);
        wait for 1 ns;

        -- ============================================
        -- Skrive-cyklus 2: MW pulse, F9 <- 0xCD12  (MR1 <- 0x12)
        -- Low byte (0x12) loades i MR1; high byte (0xCD) skal ignoreres.
        -- D_word bliver MR1 || MR0 = 0x12 || 0x34 = 0x1234.
        -- ============================================
        wait until falling_edge(clk);
        MW         <= '1';
        Address_in <= x"F9";
        Data_In    <= x"CD12";
        wait until rising_edge(clk);   -- latcher MR1
        wait for 1 ns;
        assert D_word = x"1234"
            report "MR1 fejlede: D_word skulle vaere 1234 (MR1=12, MR0=34)"
            severity error;

        wait until falling_edge(clk);
        MW <= '0';
        wait until rising_edge(clk);
        wait for 1 ns;

        -- ============================================
        -- Skrive-cyklus 3: MW pulse, FA <- 0xABCD  (MR2 <- 0xCD - lav byte)
        -- ============================================
        wait until falling_edge(clk);
        MW         <= '1';
        Address_in <= x"FA";
        Data_In    <= x"ABCD";
        wait until rising_edge(clk);   -- latcher MR2
        wait for 1 ns;
        assert LED = x"CD"
            report "MR2 fejlede: LED skulle være CD"
            severity error;

        -- ============================================
        -- Læsning af FA  (MW=0, Data_outR = 0x00CD)
        -- ============================================
        wait until falling_edge(clk);
        MW         <= '0';
        Address_in <= x"FA";
        wait for 1 ns;
        assert Data_outR = x"00CD"
            report "Læsning FA fejlede: Data_outR skulle være 00CD"
            severity error;
        assert MMR = '1'
            report "MMR skulle være 1 ved læsning af FA"
            severity error;

        -- ============================================
        -- Cyklus 5: BTNR pulse med SW=0x5A, addr=FB  (MR3 <- 0x5A)
        -- ============================================
        wait until falling_edge(clk);
        Address_in <= x"FB";
        SW         <= x"5A";
        BTNR       <= '1';
        wait until rising_edge(clk);   -- latcher MR3
        wait for 1 ns;

        -- ============================================
        -- Cyklus 6: BTNR slip + læs FB  (Data_outR = 0x005A)
        -- ============================================
        wait until falling_edge(clk);
        BTNR <= '0';
        wait for 1 ns;
        assert Data_outR = x"005A"
            report "Læsning FB fejlede: Data_outR skulle være 005A (MR3)"
            severity error;

        -- ============================================
        -- Cyklus 7: RESET  (alle registre -> 0)
        -- ============================================
        wait until falling_edge(clk);
        RESET <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;
        wait until falling_edge(clk);
        RESET <= '0';
        wait for 1 ns;

        assert D_word = x"0000"
            report "RESET fejlede: D_word skulle være 0000"
            severity error;
        assert LED = x"00"
            report "RESET fejlede: LED skulle være 00"
            severity error;

        Address_in <= x"FB";
        wait for 1 ns;
        assert Data_outR = x"0000"
            report "RESET fejlede: MR3 skulle være 0"
            severity error;

        -- ============================================
        -- Færdig
        -- ============================================
        report "=== Alle PortReg8x8 tests bestået ===" severity note;
        wait;
    end process;

end TB;
