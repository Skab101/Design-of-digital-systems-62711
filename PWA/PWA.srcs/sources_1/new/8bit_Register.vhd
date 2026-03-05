----------------------------------------------------------------------------------
-- Module Name: 8bit_register
-- Description: 8bit register with asynchronous reset and Enable enable
--              Reset is active-high, asynchronous (immediate)  
--              Enable enables data capture on rising clock edge
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Register8bit is
    Port (
        D     : in  STD_LOGIC_VECTOR(7 downto 0);
        Reset : in  STD_LOGIC;
        Load  : in  STD_LOGIC;
        clk   : in  STD_LOGIC;
        Q     : out STD_LOGIC_VECTOR(7 downto 0)
    );
end Register8bit;

-- Denne arkitektur implementerer et 8-bit register i sin simpleste form via structual
architecture Structural of Register8bit is

    -- Komponent deklarationer for D flip-flop
    component flip_flop is
        Port (
            D     : in  STD_LOGIC;
            Reset : in  STD_LOGIC;
            clk   : in  STD_LOGIC;
            Q     : out STD_LOGIC
        );
    end component;

    -- Komponent deklaration for 2-til-1 multiplexer
    component MUX2x1 is
        Port (
            D, Q       : in  STD_LOGIC;
            Enable     : in  STD_LOGIC;
            Y          : out STD_LOGIC
        );
    end component;

    
    signal Q_reg : STD_LOGIC_VECTOR(7 downto 0);  -- <‑‑ Her
    -- Signal mellem MUX og flip-flop
    signal Ys : STD_LOGIC_VECTOR(7 downto 0);

    begin

    -- Genere 8 bit flip-flops og 8 bit MUX2x1 for at implementere det 8-bit register
    gen_register: for i in 0 to 7 generate
        
        MUX_inst: MUX2x1 port map (
            D => D(i),
            Q => Q_reg(i),
            Enable => Load,
            Y => Ys(i)
        );

        Dflip_inst: flip_flop port map (
            D => Ys(i),
            Reset => Reset,
            clk => clk,
            Q => Q_reg(i)
        );

        Q <= Q_reg; -- Output port for registerets værdi

    end generate;
end Structural;
