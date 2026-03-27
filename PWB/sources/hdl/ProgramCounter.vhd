library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ProgramCounter is
    port (
        RESET      : in  STD_LOGIC;
        CLK        : in  STD_LOGIC;
        Load       : in  STD_LOGIC;
        Count      : in  STD_LOGIC;
        Address_In : in  STD_LOGIC_VECTOR(7 downto 0);
        PS         : in  STD_LOGIC_VECTOR(1 downto 0);
        Offset     : in  STD_LOGIC_VECTOR(7 downto 0);
        D          : in  STD_LOGIC_VECTOR(7 downto 0);
        CarryO     : out STD_LOGIC;
        Q          : out STD_LOGIC_VECTOR(7 downto 0);
        PC         : out STD_LOGIC_VECTOR(7 downto 0)
    );
end ProgramCounter;

architecture PC_Structural of ProgramCounter is

signal MUXP, CO, Cin, sum: STD_LOGIC_VECTOR(7 downto 0);
    begin

    --------------------------------------------------------------------------
    -- Gammelt kombinatorisk design (WIP fra Andreas/Jonas)
    -- Beholdt som reference — skal rettes før det kan bruges
    --------------------------------------------------------------------------

    full_adder: entity work.full_adder_8_bit
    port map(
             A    => PC,
             B    => Offset,
             sum  => sum,
             Cin  => '0'
     );

    Counterlogic0: entity work.CounterLogic
    port map(
    Count   => Count,
    Reset   => Reset,
    CLK     => CLK,
    Load    => Load,
    LoadIn  => NOT Load,
    D       => D(0),
    Cin     => NOT Load AND Count, 
    Q       => Q(0),
    CO      => CO(0)
    );
    
    Counterlogic1: entity work.CounterLogic
    port map(
    Count   => Count,
    Reset   => Reset,
    CLK     => CLK,
    Load    => Load,
    LoadIn  => NOT Load,
    D       => D(1),
    Cin     => Cin(1),
    Q       => Q(1),
    CO      => CO(1)
    );
    
    Counterlogic2: entity work.CounterLogic
    port map(
    Count   => Count,
    Reset   => Reset,
    CLK     => CLK,
    Load    => Load,
    LoadIn  => NOT Load,
    D       => D(2),
    Cin     => Cin(2),
    Q       => Q(2),
    CO      => CO(2)
    );
    
    Counterlogic3: entity work.CounterLogic
    port map(
    Count   => Count,
    Reset   => Reset,
    CLK     => CLK,
    Load    => Load,
    LoadIn  => NOT Load,
    D       => D(3),
    Cin     => Cin(3),
    Q       => Q(3),
    CO      => CO(3)
    );

    Counterlogic4: entity work.CounterLogic
    port map(
    Count   => Count,
    Reset   => Reset,
    CLK     => CLK,
    Load    => Load,
    LoadIn  => NOT Load,
    D       => D(4),
    Cin     => Cin(4),
    Q       => Q(4),
    CO      => CO(4)
    );
    
    Counterlogic5: entity work.CounterLogic
    port map(
    Count   => Count,
    Reset   => Reset,
    CLK     => CLK,
    Load    => Load,
    LoadIn  => NOT Load,
    D       => D(5),
    Cin     => Cin(5),
    Q       => Q(5),
    CO      => CO(5)
    );
    
Counterlogic6: entity work.CounterLogic
    port map(
    Count   => Count,
    Reset   => Reset,
    CLK     => CLK,
    Load    => Load,
    LoadIn  => NOT Load,
    D       => D(6),
    Cin     => Cin(6),
    Q       => Q(6),
    CO      => CO(6)
    );

Counterlogic7: entity work.CounterLogic
    port map(
    Count   => Count,
    Reset   => Reset,
    CLK     => CLK,
    Load    => Load,
    LoadIn  => NOT Load,
    D       => D(7),
    Cin     => Cin(7),
    Q       => Q(7),
    CO      => CarryO
    );

    
   -- MUXP <=   NOT PS(1)=>(7 downto 0)   AND      PS(0)=>(7 downto 0) AND "0x01"  OR
     --             PS(1)=>(7 downto 0)   AND  NOT PS(0)=>(7 downto 0) AND Offset;
    

    PC  <=          ((NOT PS(1) AND NOT PS(0)) AND PC)         OR
                    ((NOT PS(1) AND     PS(0)) AND sum)        OR
                    ((    PS(1) AND NOT PS(0)) AND sum)        OR
                    ((    PS(1) AND     PS(0)) AND Address_In);


            

end PC_Structural;
