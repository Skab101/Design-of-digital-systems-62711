library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity CounterLogic is
Port (
    Count  :   in  STD_LOGIC;
    Reset  :   in  STD_LOGIC; 
    CLK    :   in  STD_LOGIC;
    Load   :   in  STD_LOGIC;
    LoadIn :   in  STD_LOGIC; 
    D      :   in  STD_LOGIC;
    Cin    :   in  STD_LOGIC;
    Q      :   out STD_LOGIC;  
    Co     :   out STD_LOGIC
 );
end CounterLogic;

architecture Behavioral of CounterLogic is
signal Qsig, DLogic : STD_LOGIC;
begin


DFlipflop: entity work.flip_flop
     port map(
             CLK   => CLK,
             Reset => Reset,
             D     => DLogic,
             Q     => Qsig
        );

Q <= Qsig;

DLogic <= (D AND Load) OR (LoadIn AND (Cin XOR QSig)); 
Co <= QSig AND Cin;


end Behavioral;
