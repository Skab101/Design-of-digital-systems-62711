library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity Shifter_tb is
end;

architecture bench of Shifter_tb is

  component Shifter
      Port (
          B        : in  STD_LOGIC_VECTOR(7 downto 0);
          HSel     : in  STD_LOGIC_VECTOR(1 downto 0);
          H        : out STD_LOGIC_VECTOR(7 downto 0)
      );
  end component;

  signal B: STD_LOGIC_VECTOR(7 downto 0);
  signal HSel: STD_LOGIC_VECTOR(1 downto 0);
  signal H: STD_LOGIC_VECTOR(7 downto 0) ;

begin

  uut: Shifter port map ( B    => B,
                          HSel => HSel,
                          H    => H );

  stimulus: process
  begin

    -- Put initialisation code here
    B <= "11111111";
    HSel <= "00";

    wait for 200 ns; 
    B <= "11111111";
    HSel <= "01";
    
    wait for 200 ns; 
    B <= "11111111";
    HSel <= "10";
        
    wait for 200 ns; 
    B <= "11111111";
    HSel <= "00";    
    
    -- Put test bench stimulus code here

    wait;
  end process;


end;