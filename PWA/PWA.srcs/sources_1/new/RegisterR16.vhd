----------------------------------------------------------------------------------
-- Module Name: RegisterR16
-- Description: 16 x 8-bit register block
--              LOAD(15:0) selects which register captures D_Data on CLK edge
--              All 16 register outputs exposed (R0..R15)
--              Built structurally from flip_flop using for...generate
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity RegisterR16 is
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
end RegisterR16;

architecture RR16_Behavioral of RegisterR16 is
    signal R0s, R1s, R2s, R3s     : STD_LOGIC_VECTOR(7 downto 0);
    signal R4s, R5s, R6s, R7s     : STD_LOGIC_VECTOR(7 downto 0);
    signal R8s, R9s, R10s, R11s   : STD_LOGIC_VECTOR(7 downto 0);
    signal R12s, R13s, R14s, R15s : STD_LOGIC_VECTOR(7 downto 0);
begin

    process(CLK, RESET) -- Registre R0 til R15
    begin
        if RESET = '1' then
            R0s  <= (others => '0');
            R1s  <= (others => '0');
            R2s  <= (others => '0');
            R3s  <= (others => '0');
            R4s  <= (others => '0');
            R5s  <= (others => '0');
            R6s  <= (others => '0');
            R7s  <= (others => '0');
            R8s  <= (others => '0');
            R9s  <= (others => '0');
            R10s <= (others => '0');
            R11s <= (others => '0');
            R12s <= (others => '0');
            R13s <= (others => '0');
            R14s <= (others => '0');
            R15s <= (others => '0');
        elsif rising_edge(CLK) then
            if LOAD(0)  = '1' then R0s  <= D_Data; end if;
            if LOAD(1)  = '1' then R1s  <= D_Data; end if;
            if LOAD(2)  = '1' then R2s  <= D_Data; end if;
            if LOAD(3)  = '1' then R3s  <= D_Data; end if;
            if LOAD(4)  = '1' then R4s  <= D_Data; end if;
            if LOAD(5)  = '1' then R5s  <= D_Data; end if;
            if LOAD(6)  = '1' then R6s  <= D_Data; end if;
            if LOAD(7)  = '1' then R7s  <= D_Data; end if;
            if LOAD(8)  = '1' then R8s  <= D_Data; end if;
            if LOAD(9)  = '1' then R9s  <= D_Data; end if;
            if LOAD(10) = '1' then R10s <= D_Data; end if;
            if LOAD(11) = '1' then R11s <= D_Data; end if;
            if LOAD(12) = '1' then R12s <= D_Data; end if;
            if LOAD(13) = '1' then R13s <= D_Data; end if;
            if LOAD(14) = '1' then R14s <= D_Data; end if;
            if LOAD(15) = '1' then R15s <= D_Data; end if;
        end if;
    end process;

    -- Map internal signals to output ports
    R0  <= R0s;   R1  <= R1s;   R2  <= R2s;   R3  <= R3s;
    R4  <= R4s;   R5  <= R5s;   R6  <= R6s;   R7  <= R7s;
    R8  <= R8s;   R9  <= R9s;   R10 <= R10s;  R11 <= R11s;
    R12 <= R12s;  R13 <= R13s;  R14 <= R14s;  R15 <= R15s;

end RR16_Behavioral;
