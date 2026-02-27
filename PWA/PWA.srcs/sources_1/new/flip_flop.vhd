----------------------------------------------------------------------------------
-- Module Name: flip_flop
-- Description: D flip-flop with asynchronous reset and load enable
--              Reset is active-high, asynchronous (immediate)
--              Load enables data capture on rising clock edge
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity flip_flop is
    Port (
        D     : in  STD_LOGIC;
        Reset : in  STD_LOGIC;
        load  : in  STD_LOGIC;
        clk   : in  STD_LOGIC;
        Q     : out STD_LOGIC
    );
end flip_flop;

architecture Behavioral of flip_flop is
begin
    process(clk, Reset)
    begin
        if Reset = '1' then
            Q <= '0';
        elsif rising_edge(clk) then
            if load = '1' then
                Q <= D;
            end if;
        end if;
    end process;
end Behavioral;
