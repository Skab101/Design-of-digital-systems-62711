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

signal MUXP, CO, sumOffset, PCsig: STD_LOGIC_VECTOR(7 downto 0); 
signal Load, LoadIn, Cin0, Count: STD_LOGIC;
    begin


    full_adder: entity work.full_adder_8_bit
    port map(
             A    => PCsig,
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
    LoadIn  => Loadin,
    D       => MUXP(0),
    Cin     => Cin0, 
    Q       => PCsig(0),
    CO      => CO(0)
    );
    
    Counterlogic1: entity work.CounterLogic
    port map(
    Count   => Count,
    Reset   => Reset,
    CLK     => CLK,
    Load    => Load,
    LoadIn  => Loadin,
    D       => MUXP(1),
    Cin     => CO(0),
    Q       => PCsig(1),
    CO      => CO(1)
    );
    
    Counterlogic2: entity work.CounterLogic
    port map(
    Count   => Count,
    Reset   => Reset,
    CLK     => CLK,
    Load    => Load,
    LoadIn  => Loadin,
    D       => MUXP(2),
    Cin     => CO(1),
    Q       => PCsig(2),
    CO      => CO(2)
    );
    
    Counterlogic3: entity work.CounterLogic
    port map(
    Count   => Count,
    Reset   => Reset,
    CLK     => CLK,
    Load    => Load,
    LoadIn  => Loadin,
    D       => MUXP(3),
    Cin     => CO(2),
    Q       => PCsig(3),
    CO      => CO(3)
    );

    Counterlogic4: entity work.CounterLogic
    port map(
    Count   => Count,
    Reset   => Reset,
    CLK     => CLK,
    Load    => Load,
    LoadIn  => Loadin,
    D       => MUXP(4),
    Cin     => CO(3),
    Q       => PCsig(4),
    CO      => CO(4)
    );
    
    Counterlogic5: entity work.CounterLogic
    port map(
    Count   => Count,
    Reset   => Reset,
    CLK     => CLK,
    Load    => Load,
    LoadIn  => Loadin,
    D       => MUXP(5),
    Cin     => CO(4),
    Q       => PCsig(5),
    CO      => CO(5)
    );
    
Counterlogic6: entity work.CounterLogic
    port map(
    Count   => Count,
    Reset   => Reset,
    CLK     => CLK,
    Load    => Load,
    LoadIn  => Loadin,
    D       => MUXP(6),
    Cin     => CO(5),
    Q       => PCsig(6),
    CO      => CO(6)
    );

Counterlogic7: entity work.CounterLogic
    port map(
    Count   => Count,
    Reset   => Reset,
    CLK     => CLK,
    Load    => Load,
    LoadIn  => Loadin,
    D       => MUXP(7),
    Cin     => CO(6),
    Q       => PCsig(7),
    CO      => CarryO
    );


    Load  <=     (PS(1) AND PS(0)) OR (PS(1) AND NOT PS(0)); 
    Count <= NOT  PS(1) AND PS(0); 
    
    PC     <= PCsig;
    Loadin <= NOT Load;
    Cin0   <= NOT Load AND Count;
    
   
    MUXP <= ((7 downto 0 => PS(1)) AND ((NOT (7 downto 0 => PS(0))) AND sumOffset))
         OR ((7 downto 0 => PS(1)) AND      ((7 downto 0 => PS(0)) AND Address_In));

    

  


end PC_Structural; 