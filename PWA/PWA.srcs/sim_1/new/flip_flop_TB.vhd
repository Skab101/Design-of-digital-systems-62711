----------------------------------------------------------------------------------
-- Module Name: flip_flop_TB.vhd
-- Description: Dette program er en kort testbench som validerer funktionaliteten af flip_flop.vhd
--
--              Tests:
--                1)  Test at værdien (D) overførers korrekt til output (Q) ved en stigende clock (CLK).
--                2)  Test at reset (RST) sætter output (Q) til 0, uanset værdien af D og CLK.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity flip_flop_TB is
end flip_flop_TB;

architecture Behavioral of flip_flop_TB is

    -- Component declaration for the Unit Under Test (UUT)
    component flip_flop
        Port (
            D   : in  std_logic;
            CLK : in  std_logic;
            Reset : in  std_logic;
            Q   : out std_logic
        );
    end component;

    -- Signal declarations to connect to the UUT
    signal D   : std_logic := '0';
    signal CLK : std_logic := '0';
    signal RST : std_logic := '0';
    signal Q   : std_logic;

    constant CLK_PERIOD : time := 20 ns;  -- Clock period of 20 ns (50 MHz)
begin
    -- Instantiate the Unit Under Test (UUT)
    uut: flip_flop
        Port map (
            D => D,
            CLK => CLK,
            Reset => RST,
            Q => Q
        );

    -- Clock generation process: toggles every 10 ns (20 ns period)
    clock_process: process
    begin
        while true loop
            CLK <= '0';
            wait for CLK_PERIOD / 2;
            CLK <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    -- Stimulus process to apply test vectors to the UUT
    stimulus_process: process
    begin
        -- Test 1:
        D <= '0';  
        wait for CLK_PERIOD;  
        
        assert (Q = '0') report "Test 1 Failed: Q did not follow D on rising edge of CLK" severity error;

        -- Test 2: 
        D <= '1';  
        wait for CLK_PERIOD + 1ns;  -- venter en clk plus et ns for at værificere at reset er asynkron
        
        assert (Q = '1') report "Test 2 Failed: Q did not reset to 0 when RST is active" severity error;

        RST <= '1';  
        
        wait for CLK_PERIOD; 

        assert (Q = '0') report "Test 2 Failed: Q did not reset to 0 when RST is active" severity error;
        wait;
    end process;

end Behavioral;