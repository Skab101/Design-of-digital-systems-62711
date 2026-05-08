library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- 4-cifret 7-segment driver med tidsmultipleksning til Nexys 4 DDR.
-- Viser de 16-bit D_Word som 4 hex-cifre på de fire højre digits;
-- de fire venstre digits holdes slukkede.
--
-- Refresh-tæller dividerer 100 MHz ned så hver enkelt digit lyser
-- ca. 380 Hz (fuld scan ~95 Hz x 4 digits) -- glat og uden flicker.
entity SevenSegDriver is
    port (
        clk      : in  STD_LOGIC;
        reset    : in  STD_LOGIC;
        D_Word   : in  STD_LOGIC_VECTOR(15 downto 0);
        segments : out STD_LOGIC_VECTOR(6 downto 0);  -- CA..CG (active-low)
        dp       : out STD_LOGIC;                     -- decimal point (active-low)
        Anode    : out STD_LOGIC_VECTOR(7 downto 0)   -- digit selects (active-low)
    );
end SevenSegDriver;

architecture SSD_Behavorial of SevenSegDriver is

    -- 18-bit refresh-tæller. Bits (17 downto 16) bruges som digit-vælger,
    -- så hver digit-slot er 2^16 = 65536 klokker = ~655 us @100 MHz.
    -- Fuld scan = 4 slots = ~2.6 ms (~380 Hz per digit).
    signal refresh_cnt : unsigned(17 downto 0) := (others => '0');
    signal disp_cnt    : std_logic_vector(1 downto 0);

    -- Aktuelt valgte 4-bit nibble fra D_Word
    signal nibble : std_logic_vector(3 downto 0);

begin

    -- ---------------------------------------------------------------
    -- Refresh-tæller (synkron, asynkron reset)
    -- ---------------------------------------------------------------
    DispCountReg: process(clk, reset)
    begin
        if reset = '1' then
            refresh_cnt <= (others => '0');
        elsif rising_edge(clk) then
            refresh_cnt <= refresh_cnt + 1;
        end if;
    end process;

    disp_cnt <= std_logic_vector(refresh_cnt(17 downto 16));

    -- ---------------------------------------------------------------
    -- Anode-vælger og nibble-mux
    -- Anode er active-low: '0' = digit tændt, '1' = digit slukket.
    -- Vi bruger kun de fire højre digits (Anode(3..0)); Anode(7..4)
    -- er altid '1' så de fire venstre digits forbliver slukkede.
    -- ---------------------------------------------------------------
    DispCountDec: process(disp_cnt, D_Word)
    begin
        case disp_cnt is
            when "00" =>
                Anode  <= "11111110";              -- digit 0 (længst til højre)
                nibble <= D_Word(3 downto 0);
            when "01" =>
                Anode  <= "11111101";              -- digit 1
                nibble <= D_Word(7 downto 4);
            when "10" =>
                Anode  <= "11111011";              -- digit 2
                nibble <= D_Word(11 downto 8);
            when others =>
                Anode  <= "11110111";              -- digit 3 (længst til venstre af de aktive)
                nibble <= D_Word(15 downto 12);
        end case;
    end process;

    -- Decimal-punkt slukket (active-low)
    dp <= '1';

    -- ---------------------------------------------------------------
    -- Hex til 7-segment dekoder
    -- segments(6 downto 0) = CA, CB, CC, CD, CE, CF, CG  (active-low)
    -- ---------------------------------------------------------------
    with nibble select
        segments <= "0000001" when "0000",   -- 0
                    "1001111" when "0001",   -- 1
                    "0010010" when "0010",   -- 2
                    "0000110" when "0011",   -- 3
                    "1001100" when "0100",   -- 4
                    "0100100" when "0101",   -- 5
                    "0100000" when "0110",   -- 6
                    "0001111" when "0111",   -- 7
                    "0000000" when "1000",   -- 8
                    "0001100" when "1001",   -- 9
                    "0001000" when "1010",   -- A
                    "1100000" when "1011",   -- b
                    "0110001" when "1100",   -- C
                    "1000010" when "1101",   -- d
                    "0110000" when "1110",   -- E
                    "0111000" when "1111",   -- F
                    "1111111" when others;   -- blank

end SSD_Behavorial;
