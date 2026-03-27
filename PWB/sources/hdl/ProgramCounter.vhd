library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ProgramCounter is
    port (
        RESET      : in  STD_LOGIC;
        CLK        : in  STD_LOGIC;
        Address_In : in  STD_LOGIC_VECTOR(7 downto 0);
        PS         : in  STD_LOGIC_VECTOR(1 downto 0);
        Offset     : in  STD_LOGIC_VECTOR(7 downto 0);
        CarryO     : out STD_LOGIC;
        PC         : out STD_LOGIC_VECTOR(7 downto 0)
    );
end ProgramCounter;

architecture PC_Structural of ProgramCounter is

signal MUXP, CO, sumOffset: STD_LOGIC_VECTOR(7 downto 0); 
signal Load, Count: STD_LOGIC;
    begin


    full_adder: entity work.full_adder_8_bit
    port map(
             A    => PC,
             B    => Offset,
             sum  => sumOffset,
             Cin  => '0'
     );

    Counterlogic0: entity work.CounterLogic
    port map(
    Count   => Count,
    Reset   => Reset,
    CLK     => CLK,
    Load    => Load,
    LoadIn  => NOT Load,
    D       => MUXP(0),
    Cin     => NOT Load AND Count, 
    Q       => PC(0),
    CO      => CO(0)
    );
    
    Counterlogic1: entity work.CounterLogic
    port map(
    Count   => Count,
    Reset   => Reset,
    CLK     => CLK,
    Load    => Load,
    LoadIn  => NOT Load,
    D       => MUXP(1),
    Cin     => CO(0),
    Q       => PC(1),
    CO      => CO(1)
    );
    
    Counterlogic2: entity work.CounterLogic
    port map(
    Count   => Count,
    Reset   => Reset,
    CLK     => CLK,
    Load    => Load,
    LoadIn  => NOT Load,
    D       => MUXP(2),
    Cin     => CO(1),
    Q       => PC(2),
    CO      => CO(2)
    );
    
    Counterlogic3: entity work.CounterLogic
    port map(
    Count   => Count,
    Reset   => Reset,
    CLK     => CLK,
    Load    => Load,
    LoadIn  => NOT Load,
    D       => MUXP(3),
    Cin     => CO(2),
    Q       => PC(3),
    CO      => CO(3)
    );

    Counterlogic4: entity work.CounterLogic
    port map(
    Count   => Count,
    Reset   => Reset,
    CLK     => CLK,
    Load    => Load,
    LoadIn  => NOT Load,
    D       => MUXP(4),
    Cin     => CO(3),
    Q       => PC(4),
    CO      => CO(4)
    );
    
    Counterlogic5: entity work.CounterLogic
    port map(
    Count   => Count,
    Reset   => Reset,
    CLK     => CLK,
    Load    => Load,
    LoadIn  => NOT Load,
    D       => MUXP(5),
    Cin     => CO(4),
    Q       => PC(5),
    CO      => CO(5)
    );
    
Counterlogic6: entity work.CounterLogic
    port map(
    Count   => Count,
    Reset   => Reset,
    CLK     => CLK,
    Load    => Load,
    LoadIn  => NOT Load,
    D       => MUXP(6),
    Cin     => CO(5),
    Q       => PC(6),
    CO      => CO(6)
    );

Counterlogic7: entity work.CounterLogic
    port map(
    Count   => Count,
    Reset   => Reset,
    CLK     => CLK,
    Load    => Load,
    LoadIn  => NOT Load,
    D       => MUXP(7),
    Cin     => CO(6),
    Q       => PC(7),
    CO      => CarryO
    );

    
    MUXP <=       PS(1)=>(7 downto 0)   AND  NOT PS(0)=>(7 downto 0) AND Address_In  OR
                  PS(1)=>(7 downto 0)   AND      PS(0)=>(7 downto 0) AND sumOffset;
    

    Load  <=     (PS(1) AND PS(0)) OR (PS(1) AND NOT PS(0)); 
    Count <= NOT  PS(1) AND PS(0); 


end PC_Structural; 