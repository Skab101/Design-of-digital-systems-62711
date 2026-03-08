----------------------------------------------------------------------------------
-- Module Name: DestinationDecoder
-- Description: Decodes the 4-bit destination address DA(3:0) into a
--              one-hot 16-bit LOAD(15:0) signal, gated by WRITE.
--              When WRITE=1, exactly one bit of LOAD is set high
--              corresponding to the register addressed by DA.
--              When WRITE=0, all LOAD bits are 0 (no register written).
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity DestinationDecoder is
    Port (
        WRITE : in  STD_LOGIC;
        DA    : in  STD_LOGIC_VECTOR(3 downto 0);
        LOAD  : out STD_LOGIC_VECTOR(15 downto 0)
    );
end DestinationDecoder;

architecture dataflow of DestinationDecoder is
begin
    -- 4 til 16 bit decoder. udført simpelt ud fra sandhedstabel
    LOAD(0)  <= WRITE and (not DA(3) and not DA(2) and not DA(1) and not DA(0));
    LOAD(1)  <= WRITE and (not DA(3) and not DA(2) and not DA(1) and     DA(0));
    LOAD(2)  <= WRITE and (not DA(3) and not DA(2) and     DA(1) and not DA(0));
    LOAD(3)  <= WRITE and (not DA(3) and not DA(2) and     DA(1) and     DA(0));
    LOAD(4)  <= WRITE and (not DA(3) and     DA(2) and not DA(1) and not DA(0));
    LOAD(5)  <= WRITE and (not DA(3) and     DA(2) and not DA(1) and     DA(0));
    LOAD(6)  <= WRITE and (not DA(3) and     DA(2) and     DA(1) and not DA(0));
    LOAD(7)  <= WRITE and (not DA(3) and     DA(2) and     DA(1) and     DA(0));
    LOAD(8)  <= WRITE and (    DA(3) and not DA(2) and not DA(1) and not DA(0));
    LOAD(9)  <= WRITE and (    DA(3) and not DA(2) and not DA(1) and     DA(0));
    LOAD(10) <= WRITE and (    DA(3) and not DA(2) and     DA(1) and not DA(0));
    LOAD(11) <= WRITE and (    DA(3) and not DA(2) and     DA(1) and     DA(0));
    LOAD(12) <= WRITE and (    DA(3) and     DA(2) and not DA(1) and not DA(0));
    LOAD(13) <= WRITE and (    DA(3) and     DA(2) and not DA(1) and     DA(0));
    LOAD(14) <= WRITE and (    DA(3) and     DA(2) and     DA(1) and not DA(0));
    LOAD(15) <= WRITE and (    DA(3) and     DA(2) and     DA(1) and     DA(0));
end dataflow;
