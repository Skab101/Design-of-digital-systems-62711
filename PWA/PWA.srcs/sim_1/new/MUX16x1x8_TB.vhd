----------------------------------------------------------------------------------
-- Module Name: MuX16x1x8_TB.vhd
-- Description: Dette program er en kort testbench som validerer funktionaliteten af MUX16x1x8.vhd
--
--              Tests:
--                1)  tester at MUX'en kan vidersende værdierne i R0-R15 baseret på D_Select(3:0)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MUX16x1x8_TB is
end MUX16x1x8_TB;

architecture Behavioral of MUX16x1x8_TB is

    -- Deklareing af Unit Under Test (UUT)
    component MUX16x1x8
        Port (
        R0, R1, R2, R3     : in  STD_LOGIC_VECTOR(7 downto 0);
        R4, R5, R6, R7     : in  STD_LOGIC_VECTOR(7 downto 0);
        R8, R9, R10, R11   : in  STD_LOGIC_VECTOR(7 downto 0);
        R12, R13, R14, R15 : in  STD_LOGIC_VECTOR(7 downto 0);
        D_Select            : in  STD_LOGIC_VECTOR(3 downto 0);
        Y_Data              : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

    -- nødvændige signaler for UUT
    signal R0, R1, R2, R3     : STD_LOGIC_VECTOR    (7 downto 0) := (others => '0');
    signal R4, R5, R6, R7     : STD_LOGIC_VECTOR    (7 downto 0) := (others => '0');
    signal R8, R9, R10, R11   : STD_LOGIC_VECTOR    (7 downto 0) := (others => '0');
    signal R12, R13, R14, R15 : STD_LOGIC_VECTOR    (7 downto 0) := (others => '0');
    signal D_Select            : STD_LOGIC_VECTOR    (3 downto 0) := (others => '0');
    signal Y_Data              : STD_LOGIC_VECTOR    (7 downto 0);

begin
    -- Instantiere Unit Under Test (UUT)
    uut: MUX16x1x8
        Port map (
            R0 => R0,
            R1 => R1,
            R2 => R2,
            R3 => R3,
            R4 => R4,
            R5 => R5,
            R6 => R6,
            R7 => R7,
            R8 => R8,
            R9 => R9,
            R10 => R10,
            R11 => R11,
            R12 => R12,
            R13 => R13,
            R14 => R14,
            R15 => R15,
            D_Select => D_Select,
            Y_Data => Y_Data
        );
    -- Stimulus process for at teste MUX16x1x8
    stimulus_process: process
    begin

        -- Test 1: Sæt R0-R15 til kendte værdier for at teste at MUX'en kan vidersende den korrekte Rn baseret på D_Select(3:0)
        R0 <= "00000001";
        R1 <= "00000010";
        R2 <= "00000011";
        R3 <= "00000100";
        R4 <= "00000101";
        R5 <= "00000110";
        R6 <= "00000111";
        R7 <= "00001000";
        R8 <= "00001001";
        R9 <= "00001010";
        R10 <= "00001011";
        R11 <= "00001100";
        R12 <= "00001101";
        R13 <= "00001110";
        R14 <= "00001111";
        R15 <= "00010000";

        -- Test alle kombinationer af D_Select(3:0) for at sikre, at Y_Data følger den korrekte Rn
        for i in 0 to 15 loop
            D_Select <= std_logic_vector(to_unsigned(i, 4));  -- Sæt D_Select til den aktuelle værdi i loopet
            wait for 10 ns;  -- Vent for at observere output
        end loop;

        wait;  -- Stop simulationen efter testene er udført
    end process;
end Behavioral;