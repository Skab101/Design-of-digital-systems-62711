library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Port Register Module: 8 x 8-bit port registers mapped to memory addresses 0xF8-0xFF
--   MR0 (0xF8): D_Word low byte  (7-seg low) -- writable
--   MR1 (0xF9): D_Word high byte (7-seg high) -- writable
--   MR2 (0xFA): LEDs                          -- writable
--   MR3 (0xFB): BTNR input                    -- read-only (loaded from SW on BTNR press)
--   MR4 (0xFC): BTNL input                    -- read-only
--   MR5 (0xFD): BTND input                    -- read-only
--   MR6 (0xFE): BTNU input                    -- read-only
--   MR7 (0xFF): BTNC input                    -- read-only

entity PortReg8x8 is
    port (
        clk        : in  STD_LOGIC;
        MW         : in  STD_LOGIC;
        RESET      : in  STD_LOGIC;
        Data_In    : in  STD_LOGIC_VECTOR(15 downto 0); -- 16-bit Data_in kommer fra RegisterR16 i datapath
        Address_in : in  STD_LOGIC_VECTOR(7 downto 0);
        SW         : in  STD_LOGIC_VECTOR(7 downto 0);
        BTNC       : in  STD_LOGIC;
        BTNU       : in  STD_LOGIC;
        BTNL       : in  STD_LOGIC;
        BTNR       : in  STD_LOGIC;
        BTND       : in  STD_LOGIC;
        MMR        : out STD_LOGIC;
        D_word     : out STD_LOGIC_VECTOR(15 downto 0);
        Data_outR  : out STD_LOGIC_VECTOR(15 downto 0);
        LED        : out STD_LOGIC_VECTOR(7 downto 0)
    );
end PortReg8x8;

architecture PR_Structural of PortReg8x8 is

    component Register8bit is
        Port (
            D     : in  STD_LOGIC_VECTOR(7 downto 0);
            Reset : in  STD_LOGIC;
            Load  : in  STD_LOGIC;
            clk   : in  STD_LOGIC;
            Q     : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

    -- Disse to linjer generer en type af array af std_logic_vector(7 downto 0) 
    -- samt danner 8 signaler af denne type som bruges til at holde registerværdierne
    type reg_array is array (7 downto 0) of std_logic_vector(7 downto 0);
    signal MR : reg_array;

    signal load : STD_LOGIC_VECTOR(2 downto 0); -- Load signaler for MR0..MR2, genereret fra adresse-dekodning

    signal write_data : STD_LOGIC_VECTOR(7 downto 0); -- Data til at loade i MR0..MR2 fra Data_In

begin


    -- process(all) betyder, at processen automatisk er sensitiv over for
    -- alle signaler, som læses inde i processen.
    -- I denne proces er det bl.a.: MW, Address_in, Data_In og MR(0..7).
    -- Dette sikrer korrekt kombinatorisk adfærd og at simulation og hardware stemmer overens.
    process(all)
    begin

        load <= (others => '0'); -- Initialiser alle load signaler til 0

        write_data <= (others => '0'); -- Initialiser write_data til 0

        Data_outR <= (others => '0'); -- Initialiser Data_outR til 0

        if MW = '1' then

            -- opdaterer load signaler og write_data ud fra adresse-dekodning
            case Address_in(2 downto 0) is
                when "000" => load(0) <= '1', write_data <= Data_In(7 downto 0); -- MR0
                when "001" => load(1) <= '1', write_data <= Data_In(15 downto 8); -- MR1
                when "010" => load(2) <= '1', write_data <= Data_In(7 downto 0); -- MR2
                when others => null; -- Ingen register skal loades
            end case;

        elsif MW = '0' then

            -- opdaterer Data_outR ud fra adresse-dekodning
            -- plus forlænger registerværdierne MR(index) til 16 bit ved at sætte de øverste 8 bit til 0
            case Address_in(2 downto 0) is
                when "000" => Data_outR <= x"00" & MR(0); -- MR0
                when "001" => Data_outR <= x"00" & MR(1); -- MR1
                when "010" => Data_outR <= x"00" & MR(2); -- MR2
                when "011" => Data_outR <= x"00" & MR(3); -- MR3
                when "100" => Data_outR <= x"00" & MR(4); -- MR4
                when "101" => Data_outR <= x"00" & MR(5); -- MR5
                when "110" => Data_outR <= x"00" & MR(6); -- MR6
                when "111" => Data_outR <= x"00" & MR(7); -- MR7
            end case;

        end if;

    end process;

    -- MMR logik sørger for at der ikke læses og skrives samtidigt
    -- hvilket realiseres via at MW og MMR ikke er høje på samme tid
    -- samt at MMR kun er aktiv ved de korrekte adresser (0000.0xxx)
    MMR <= '1' when (Address_in(7 downto 3) = "11111" and MW = '0') else '0';

    -- MR0..MR2 (CPU write)
    -- syntaksen betyder D => write_data, Reset => RESET, Load => load(index), clk => clk, Q => MR(index)
    U_MR0 : Register8bit port map (write_data, RESET, load(0), clk, MR(0));
    U_MR1 : Register8bit port map (write_data, RESET, load(1), clk, MR(1));
    U_MR2 : Register8bit port map (write_data, RESET, load(2), clk, MR(2));

    -- MR3..MR7 (buttons + SW)
    U_MR3 : Register8bit port map (SW, RESET, BTNR, clk, MR(3));
    U_MR4 : Register8bit port map (SW, RESET, BTNL, clk, MR(4));
    U_MR5 : Register8bit port map (SW, RESET, BTND, clk, MR(5));
    U_MR6 : Register8bit port map (SW, RESET, BTNU, clk, MR(6));
    U_MR7 : Register8bit port map (SW, RESET, BTNC, clk, MR(7));

    -- Forbindelser
    D_word <= MR(1) & MR(0); -- D_Word er sammensat af MR1 (high byte) og MR0 (low byte)
    LED <= MR(2); -- LED output er forbundet til MR2

end PR_Structural;