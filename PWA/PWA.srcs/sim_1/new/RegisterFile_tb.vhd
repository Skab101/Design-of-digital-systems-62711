----------------------------------------------------------------------------------
-- Module Name: RegisterFile_tb
-- Description: Testbench for the 16x8-bit Register File
--              Tests: reset, write to individual registers, read via AA/BA,
--              write-disable (RW=0), simultaneous read of two different registers
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RegisterFile_tb is
end RegisterFile_tb;

architecture testbench of RegisterFile_tb is

    -- Testbench signalerne som matches portene i RegisterFile entity
    signal RESET  : STD_LOGIC := '0';
    signal CLK    : STD_LOGIC := '0';
    signal RW     : STD_LOGIC := '0';
    signal DA     : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal AA     : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal BA     : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal D_Data : STD_LOGIC_VECTOR(7 downto 0) := "00000000";
    signal A_Data : STD_LOGIC_VECTOR(7 downto 0);
    signal B_Data : STD_LOGIC_VECTOR(7 downto 0);

    -- Længde af klokkens periode, bruges i CLK_PROC for at generere klokken
    constant CLK_PERIOD : time := 10 ns;

begin

    -- Unit Under Test (UUT) dette er den entity/komponent som vi undersøger med denne testbench
    UUT: entity work.RegisterFile
    port map (
        RESET  => RESET,
        CLK    => CLK,
        RW     => RW,
        DA     => DA,
        AA     => AA,
        BA     => BA,
        D_Data => D_Data,
        A_Data => A_Data,
        B_Data => B_Data
    );


    -- Denne procces generer klokken i denne TB, den toggler mellem '0' og '1' hver halv periode
    CLK_PROC: process
    begin
        CLK <= '0';
        wait for CLK_PERIOD / 2;
        CLK <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- Stimulus dette er proccesen som kører alle funktionaliteter af RegisterFile igennem, den tester reset, skrive og læse funktionalitet, og RW signalet
    STIM: process
    begin
        -- 1) Disse fire linjer tester reset funktionen samt initialiserer kredsløbet til nul, så vi har er klart udgangspunkt for de efterfølgende test
        RESET <= '1';
        wait for CLK_PERIOD * 2;
        RESET <= '0';
        wait for CLK_PERIOD * 5; -- venter lidt ekstra tid så det er nemmere visuelt at se at reset har virket i en simulator

        -- 2) Disse 9 linjer tester at der ikke kan indsamles data imellem clk kanter, og at RW signalet skal være aktivt for at data kan indsamles i registre
        RW <= '1'; -- registre kan nu indsamle data på næste stigende CLK kant når LOAD er aktivt
        D_Data <= x"FF"; -- data tilgænglig til at læse ind i registre
        DA <= "0000"; -- Prøver at skrive til R0
        wait for CLK_PERIOD - 6 ns; -- venter næsten en clk
        D_Data <= x"00"; -- ændrer data lige inden clk for at teste at data ikke kan indsamles imellem clk kanter
        wait for 6 ns; -- venter til næste clk kant
        D_Data <= x"FF"; -- sætter data tilbage til x"FF" for at teste at det ikke kan indsamles når LOAD ikke er aktivt
        RW <= '0'; -- deaktiverer skrivefunktionen for at tæste at data ikke kan indsamles når RW=0
        wait for CLK_PERIOD;

        RW <= '1'; -- data kan nu indsamles

        -- 3) Dette loop skriver til alle 16 registre
        for i in 0 to 15 loop
            D_Data <= std_logic_vector(to_unsigned(1 + i*2, 8)); -- danner en unik værdi som skrives til hvert register
            DA <= std_logic_vector(to_unsigned(i, 4));
            wait for CLK_PERIOD;
        end loop;

        -- 4) Dette loop tester at der kan skrives ud til A_data og B_data fra alle registre
        for i in 0 to 15 loop
            AA <= std_logic_vector(to_unsigned(i, 4));
            BA <= std_logic_vector(to_unsigned(i, 4));
            wait for CLK_PERIOD;
        end loop;

        wait;
    end process;

end testbench;
