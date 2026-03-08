----------------------------------------------------------------------------------
-- Module Name: DestinationDecoder_TB.vhd
-- Description: Dette program er en kort testbench som validerer funktionaliteten af DestinationDecoder.vhd
--
--              Tests:
--                1) Sekvintielt teste alle mulige kombinationer af DA(3:0) og WRITE for at sikre, at LOAD(15:0) er korrekt dekodet.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DestinationDecoder_TB is
end DestinationDecoder_TB;

architecture Behavioral of DestinationDecoder_TB is

    -- Deklareing af Unit Under Test (UUT)
    component DestinationDecoder
        Port (
            WRITE : in  STD_LOGIC;
            DA    : in  STD_LOGIC_VECTOR(3 downto 0);
            LOAD  : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;

    -- nødvændige signaler for UUT
    signal WRITE : STD_LOGIC := '0';
    signal DA    : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal LOAD  : STD_LOGIC_VECTOR(15 downto 0);
begin
    -- Instantiere Unit Under Test (UUT)
    uut: DestinationDecoder
        Port map (
            WRITE => WRITE,
            DA => DA,
            LOAD => LOAD
        );

    -- Stimulus process for at teste DestinationDecoder
    stimulus_process: process
    begin
        -- Test alle kombinationer af DA(3:0) og WRITE
        for i in 0 to 15 loop
            DA <= std_logic_vector(to_unsigned(i, 4));  -- Sæt DA til den aktuelle værdi i loopet
            WRITE <= '1';  -- Aktiver WRITE for at teste dekodning
            wait for 10 ns;  -- Vent for at observere output
            WRITE <= '0';  -- Deaktiver WRITE for at teste at LOAD er nul
            wait for 10 ns;  -- Vent for at observere output
        end loop;

        wait;  -- Stop simulationen efter testene er udført
    end process;

end Behavioral;