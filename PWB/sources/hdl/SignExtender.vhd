library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity SignExtender is
    port (
        IR         : in  std_logic_vector(15 downto 0);
        Extended_8 : out std_logic_vector(7 downto 0)
    );
end SignExtender;

architecture SE_Behavorial of SignExtender is
begin

    -- TODO: Implement combinatorial (concurrent) logic
    -- IR(8)=0: Extended_8 = 0.0.0.IR7.IR6.IR2.IR1.IR0
    -- IR(8)=1: Extended_8 = 1.1.1.IR7.IR6.IR2.IR1.IR0

end SE_Behavorial;
