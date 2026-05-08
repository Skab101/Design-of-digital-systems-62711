library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Xilinx primitive libraries for the BRAM_SINGLE_MACRO instantiation
library UNISIM;
use UNISIM.vcomponents.all;

library UNIMACRO;
use UNIMACRO.vcomponents.all;

-- 256 x 16-bit Single Port Block RAM
-- Uses Artix-7 BRAM_SINGLE_MACRO primitive (18Kb, 16-bit width)
-- The primitive has 10-bit address (1024 entries); we only use 256 of them
-- by padding the 8-bit Address_in with two zeros.
--
-- BRAM'en clockes på NEGATIV flank så data er stabil i tide til at
-- IR'en (i MPC) kan indlæse den på næste positive flank. PWB's IDC
-- sætter MM=1 og IL=1 i samme INF-cyklus, hvilket forudsætter ~0-cycle
-- memory read. BRAM er synkron, men ved at drive den en halv cyklus i
-- modfase får læsningen tid til at sætte sig.
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

architecture RAM_Structural of Ram256x16 is

    -- Padded 10-bit address for the BRAM primitive
    signal ADDR_full : STD_LOGIC_VECTOR(9 downto 0);
    -- Byte write enable: 2 bits for 16-bit width in 18Kb mode
    signal WE_sig    : STD_LOGIC_VECTOR(1 downto 0);
    -- Inverteret klok til negativ-flank BRAM (se header)
    signal clk_n     : STD_LOGIC;

begin

    ADDR_full <= "00" & Address_in;
    WE_sig    <= (others => MW);
    clk_n     <= not clk;

    BRAM_SINGLE_MACRO_inst : BRAM_SINGLE_MACRO
    generic map (
        BRAM_SIZE   => "18Kb",       -- 18Kb is smallest mode supporting 16-bit width
        DEVICE      => "7SERIES",    -- Artix-7
        DO_REG      => 0,            -- No output register (synchronous read)
        INIT        => X"0000",      -- Initial value on output port
        -- PROGRAM_INIT_BEGIN (managed by dsdasm.py -- do not edit by hand)
        INIT_00 => X"40192068214098042100980320C0980221C09805000E00FF00F800FAE03899C6",
        INIT_01 => X"00000000000000000000000000000000000000000000000000000000E0384021",
        INIT_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_08 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_09 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_0A => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_0B => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_0C => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_0D => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_0E => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_0F => X"0000000000000000000000000000000000000000000000000000000000000000",
        -- PROGRAM_INIT_END
        INIT_FILE   => "NONE",
        WRITE_WIDTH => 16,
        READ_WIDTH  => 16,
        SRVAL       => X"0000",      -- Set/Reset value for output
        WRITE_MODE  => "WRITE_FIRST" -- On simultaneous read+write, output = new data
    )
    port map (
        DO    => Data_out,     -- 16-bit output data
        ADDR  => ADDR_full,    -- 10-bit address
        CLK   => clk_n,        -- negativ-flank, se header
        DI    => Data_in,      -- 16-bit input data
        EN    => '1',          -- RAM always enabled
        REGCE => '1',          -- Output register clock enable (unused since DO_REG=0)
        RST   => Reset,        -- Synchronous reset of output latch
        WE    => WE_sig        -- Write enable vector (both bits tied to MW)
    );

end RAM_Structural;
