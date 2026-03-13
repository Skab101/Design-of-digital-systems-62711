library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ZeroFiller is
    port (
        IR           : in  std_logic_vector(15 downto 0);
        ZeroFilled_8 : out std_logic_vector(7 downto 0)
    );
end ZeroFiller;

architecture ZF_Behavorial of ZeroFiller is
begin

    -- TODO: Implement combinatorial (concurrent) logic
    -- ZeroFilled_8 = 0.0.0.0.0.IR2.IR1.IR0

end ZF_Behavorial;
