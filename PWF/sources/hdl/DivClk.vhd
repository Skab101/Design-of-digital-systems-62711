library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Klokdivider med konfigurerbar dele-faktor.
-- Genererer Clk1 ud fra den hurtige Clk via en tæller (Cnt1).
-- Når Cnt1 = TimeP/2 toggles Clk1_D på næste Clk-flank, hvilket
-- giver en symmetrisk udgangsklok.
--
-- Specialtilfælde TimeP=1: TimeP/2 = 0 (heltalsdivision), så Clear1
-- er høj hver eneste cyklus -- Clk1_D toggler hver Clk-flank, dvs.
-- Clk1 = Clk/2. Det er præcis hvad vi bruger her (50 MHz CPU-klok
-- ud fra 100 MHz Nexys-klokken).
entity DivClk is
    port (
        Reset : in  STD_LOGIC;
        Clk   : in  STD_LOGIC;
        TimeP : in  integer;
        Clk1  : out STD_LOGIC
    );
end DivClk;

architecture DivClk_arch of DivClk is
    signal Cnt1   : integer range 0 to 25000000;
    signal Clear1 : STD_LOGIC;
    signal Clk1_D : STD_LOGIC;
begin

    -- Toggle-register: på hver Clk-flank hvor Clear1 er høj, vendes Clk1_D.
    Div1Reg : process(Clk, Reset)
    begin
        if Reset = '1' then
            Clk1_D <= '0';
        elsif rising_edge(Clk) then
            if Clear1 = '1' then
                Clk1_D <= not Clk1_D;
            end if;
        end if;
    end process;

    -- Kombinatorisk: Clear1 høj når tælleren rammer halvdelen af perioden.
    Div1Dec : process(Cnt1, TimeP)
    begin
        Clear1 <= '0';
        if Cnt1 = TimeP / 2 then
            Clear1 <= '1';
        end if;
    end process;

    -- Periodetæller: nulstilles ved Clear1, tæller op ellers.
    Div1Cnt : process(Clk, Reset)
    begin
        if Reset = '1' then
            Cnt1 <= 0;
        elsif rising_edge(Clk) then
            if Clear1 = '1' then
                Cnt1 <= 0;
            else
                Cnt1 <= Cnt1 + 1;
            end if;
        end if;
    end process;

    Clk1 <= Clk1_D;

end DivClk_arch;
