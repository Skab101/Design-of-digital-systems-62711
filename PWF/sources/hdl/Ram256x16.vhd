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

begin

    ADDR_full <= "00" & Address_in;
    WE_sig    <= (others => MW);

    BRAM_SINGLE_MACRO_inst : BRAM_SINGLE_MACRO
    generic map (
        BRAM_SIZE   => "18Kb",       -- 18Kb is smallest mode supporting 16-bit width
        DEVICE      => "7SERIES",    -- Artix-7
        DO_REG      => 0,            -- No output register (synchronous read)
        INIT        => X"0000",      -- Initial value on output port
        INIT_FILE   => "NONE",
        WRITE_WIDTH => 16,
        READ_WIDTH  => 16,
        SRVAL       => X"0000",      -- Set/Reset value for output
        WRITE_MODE  => "WRITE_FIRST" -- On simultaneous read+write, output = new data
    )
    port map (
        DO    => Data_out,     -- 16-bit output data
        ADDR  => ADDR_full,    -- 10-bit address
        CLK   => clk,
        DI    => Data_in,      -- 16-bit input data
        EN    => '1',          -- RAM always enabled
        REGCE => '1',          -- Output register clock enable (unused since DO_REG=0)
        RST   => Reset,        -- Synchronous reset of output latch
        WE    => WE_sig        -- Write enable vector (both bits tied to MW)
    );

end RAM_Structural;
