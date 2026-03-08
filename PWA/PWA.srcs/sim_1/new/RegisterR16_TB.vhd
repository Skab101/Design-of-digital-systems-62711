----------------------------------------------------------------------------------
-- Module Name: RegisterR16_TB.vhd
-- Description: Dette program er en kort testbench som validerer funktionaliteten af RegisterR16.vhd
--
--              Tests:
--                1)  Reset alle register
--                2)  Indlæse data i alle registrende
--                3)  Se at register værdierne holder i flere clockperioder
--               
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RegisterR16_TB is
end RegisterR16_TB;

architecture Behavioral of RegisterR16_TB is

    -- Deklareing af Unit Under Test (UUT)
    component RegisterR16
        Port (
        RESET  : in  STD_LOGIC;
        CLK    : in  STD_LOGIC;
        LOAD   : in  STD_LOGIC_VECTOR(15 downto 0);
        D_Data : in  STD_LOGIC_VECTOR(7 downto 0);
        R0, R1, R2, R3   : out STD_LOGIC_VECTOR(7 downto 0);
        R4, R5, R6, R7     : out STD_LOGIC_VECTOR(7 downto 0);
        R8, R9, R10, R11   : out STD_LOGIC_VECTOR(7 downto 0);
        R12, R13, R14, R15 : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

    -- nødvændige signaler for UUT
    signal RESET  : std_logic := '0';
    signal CLK    : std_logic := '0';
    signal LOAD   : std_logic_vector(15 downto 0) := (others => '0');
    signal D_Data : std_logic_vector(7 downto 0) := (others => '0');
    signal R0, R1, R2, R3   : std_logic_vector(7 downto 0);
    signal R4, R5, R6, R7     : std_logic_vector(7 downto 0);
    signal R8, R9, R10, R11   : std_logic_vector(7 downto 0);
    signal R12, R13, R14, R15 : std_logic_vector(7 downto 0);  

    constant CLK_PERIOD : time := 20 ns;

begin
    -- Instantiere Unit Under Test (UUT)
    uut: RegisterR16
        Port map (
            RESET => RESET,
            CLK => CLK,
            LOAD => LOAD,
            D_Data => D_Data,
            R0 => R0, R1 => R1, R2 => R2, R3 => R3,
            R4 => R4, R5 => R5, R6 => R6, R7 => R7,
            R8 => R8, R9 => R9, R10 => R10, R11 => R11,
            R12 => R12, R13 => R13, R14 => R14, R15 => R15
        );

    -- Clock process for at generere en clock signal
    clock_process: process
    begin
        while true loop
            CLK <= '0';
            wait for CLK_PERIOD / 2;
            CLK <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    -- Stimulus process for at teste RegisterR16
    stimulus_process: process
    begin
        -- Test 1: Reset alle register
        RESET <= '1';
        wait for CLK_PERIOD*3;  
        
        --assert (R0 = (others => '0') and 
                --R1 = (others => '0') and 
                --R2 = (others => '0') and 
                --R3 = (others => '0') and 
                --R4 = (others => '0') and 
                --R5 = (others => '0') and 
                --R6 = (others => '0') and 
                --R7 = (others => '0') and 
                --R8 = (others => '0') and 
                --R9 = (others => '0') and 
                --R10 = (others => '0') and 
                --R11 = (others => '0') and 
                --R12 = (others => '0') and 
                --R13 = (others => '0') and 
                --R14 = (others => '0') and 
                --R15 = (others => '0')) report "Test 1 Failed: Not all registers were reset to 0" severity error;
        
        -- Test 2: Indlæse data i alle registrende
        RESET <= '0';
        D_Data <= "10101010";  
        LOAD <= "1111111111111111";  -- Indlæse data i alle registre
        wait for CLK_PERIOD;    
        assert (R0 = "10101010" and 
                R1 = "10101010" and 
                R2 = "10101010" and 
                R3 = "10101010" and 
                R4 = "10101010" and 
                R5 = "10101010" and 
                R6 = "10101010" and 
                R7 = "10101010" and 
                R8 = "10101010" and 
                R9 = "10101010" and 
                R10 = "10101010" and 
                R11 = "10101010" and 
                R12 = "10101010" and 
                R13 = "10101010" and 
                R14 = "10101010" and 
                R15 = "10101010") report "Test 2 Failed: Not all registers were loaded with the correct data" severity error;
                
                wait for CLK_PERIOD*3;
                
    end process;
end Behavioral;