library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ProgramCounter is
    port (
        RESET      : in  STD_LOGIC;
        CLK        : in  STD_LOGIC;
        Address_In : in  STD_LOGIC_VECTOR(7 downto 0);
        PS         : in  STD_LOGIC_VECTOR(1 downto 0);
        Offset     : in  STD_LOGIC_VECTOR(7 downto 0);
        PC         : out STD_LOGIC_VECTOR(7 downto 0)
    );
end ProgramCounter;

architecture PC_Behavorial of ProgramCounter is
signal QCLK: STD_LOGIC;
signal PScontrol: STD_LOGIC_VECTER(1 downto 0);
signal MUXF, sum: STD_LOGIC_VECTOR(7 downto 0); 
begin
     

    Egde_detector: entity work.Edge_Detector

    port map(
        PSsig => PScontrol,
        Clk => Clk,
        PS => PS
);


        full_adder: entity work.full_adder_8_bit
    port map(
            A    => PC 
            B    => MUXP,
            sum  => sum,
            Cin  => Cin,  -- fjernes.
            Cout => , -- fjernes. 
            V => V  -- fjernes.
    );
    
    MUXP <=   NOT PS(1) AND         PS(0) AND "0x01"  OR 
                  PS(1) AND   NOT   PS(0) AND Offset;
    

    Address_Out <= ((NOT PS(1) AND NOT PS(0)) AND PC)         OR 
                   ((NOT PS(1) AND     PS(0)) AND sum)        OR 
                   ((    PS(1) AND NOT PS(0)) AND sum)        OR 
                   ((    PS(1) AND     PS(0)) AND Address_in) OR 


end PC_Behavorial;
