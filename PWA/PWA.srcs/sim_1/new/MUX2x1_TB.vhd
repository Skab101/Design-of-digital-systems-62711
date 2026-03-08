----------------------------------------------------------------------------------
-- Module Name: MUX2x1_TB.vhd
-- Description: Dette program er en kort testbench som validerer funktionaliteten af MUX2x1.vhd
--
--              Tests:
--                1)  tester at MUX'en kan vidersende Q hvis Enable er 0
--                2)  tester at MUX'en kan vidersende D hvis Enable er 1
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MUX2x1_TB is
end MUX2x1_TB;

architecture Behavioral of MUX2x1_TB is

    -- Deklareing af Unit Under Test (UUT)
    component MUX2x1
        Port (
            D       : in  std_logic;
            Q       : in  std_logic;
            Enable  : in  std_logic;
            Y       : out std_logic
        );
    end component;

    -- nødvændige signaler for UUT
    signal D       : std_logic := '0';
    signal Q       : std_logic := '0';
    signal Enable  : std_logic := '0';
    signal Y       : std_logic;

begin
    -- Instantiere Unit Under Test (UUT)
    uut: MUX2x1
        Port map (
            D => D,
            Q => Q,
            Enable => Enable,
            Y => Y
        );

    -- Stimulus process for at teste MUX2x1
    stimulus_process: process
    begin
        -- Test 1: Enable = 0, Y skal følge Q
        D <= '0';  
        Q <= '0';
        Enable <= '0';
        wait for 10 ns;  
        
        assert (Y = '0') report "Test 1 Failed: Y did not follow Q when Enable is 0" severity error;
        
        q <= '1';
        wait for 10 ns;

        -- Test 2: Enable = 1, Y skal følge D
        Enable <= '1';
        wait for 10 ns;  
        
        assert (Y = '1') report "Test 2 Failed: Y did not follow D when Enable is 1" severity error;
        
        D <= '1';
        Q <= '0';
        
        wait;
    end process;

end Behavioral;