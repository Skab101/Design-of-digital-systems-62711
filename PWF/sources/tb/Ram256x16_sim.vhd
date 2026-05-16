library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- ===================================================================
-- Ram256x16  -- ADFAERDS-MODEL KUN TIL GHDL-SIMULERING
-- ===================================================================
-- Samme entity-navn og port-interface som den syntese-baserede
-- PWF/sources/hdl/Ram256x16.vhd (BRAM_SINGLE_MACRO), men uden Xilinx-
-- primitiver saa GHDL kan koere den. Replikerer den relevante timing:
--   * BRAM clockes paa NEGATIV flank af clk (clk_n = not clk)
--   * DO_REG=0 -> synkron laesning (Data_out gyldig efter klokkant)
--   * WRITE_MODE = WRITE_FIRST (samtidig R+W -> Data_out = Data_in)
--   * RST synkron nulstilling af output-latch til 0x0000
--   * EN = '1' altid
-- Memory initialiseres med addsub_calc-programmet (21 ord), resten 0.
-- HOLD INIT I SYNK MED PWF/tools/asm/examples/addsub_calc.asm.
-- ===================================================================

entity Ram256x16 is
    port (
        clk        : in  STD_LOGIC;
        Reset      : in  STD_LOGIC;
        Data_in    : in  STD_LOGIC_VECTOR(15 downto 0);
        Address_in : in  STD_LOGIC_VECTOR(7 downto 0);
        MW         : in  STD_LOGIC;
        Data_out   : out STD_LOGIC_VECTOR(15 downto 0)
    );
end Ram256x16;

architecture Sim_Behavioral of Ram256x16 is

    type mem_t is array (0 to 255) of STD_LOGIC_VECTOR(15 downto 0);

    -- addsub_calc.asm assembleret (dsdasm). Adresse 0..20 = program.
    signal mem : mem_t := (
        0  => x"16A0",  1  => x"9904",  2  => x"0AD4",  3  => x"2058",
        4  => x"9903",  5  => x"0AD4",  6  => x"2158",  7  => x"9902",
        8  => x"0AD4",  9  => x"2118",  10 => x"0B8D",  11 => x"C022",
        12 => x"058D",  13 => x"9907",  14 => x"0AD4",  15 => x"401E",
        16 => x"9906",  17 => x"0AD4",  18 => x"4018",  19 => x"99C1",
        20 => x"E038",
        others => x"0000"
    );

    signal clk_n : STD_LOGIC;

begin

    clk_n <= not clk;

    -- Synkron port paa clk_n's stigende flank (= clk's faldende flank)
    process(clk_n)
        variable a : integer range 0 to 255;
    begin
        if rising_edge(clk_n) then
            a := to_integer(unsigned(Address_in));
            if Reset = '1' then
                Data_out <= x"0000";
            elsif MW = '1' then
                mem(a)   <= Data_in;
                Data_out <= Data_in;          -- WRITE_FIRST
            else
                Data_out <= mem(a);
            end if;
        end if;
    end process;

end Sim_Behavioral;
