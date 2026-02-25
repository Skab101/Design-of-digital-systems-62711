----------------------------------------------------------------------------------
-- Module Name: DestinationDecoder
-- Description: Decodes DA(3:0) + WRITE into one-hot LOAD(15:0)
--              When WRITE=1, sets LOAD(DA) = 1, all others = 0
--              When WRITE=0, all LOAD bits = 0 (no register write)
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

end dataflow;
