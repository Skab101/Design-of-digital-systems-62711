library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity full_adder_8_bit is
    Port ( A : in STD_LOGIC_VECTOR (7 downto 0);
           B : in STD_LOGIC_VECTOR (7 downto 0);
           sum : out STD_LOGIC_VECTOR (7 downto 0);
           Cout : out STD_LOGIC
           );
end full_adder_8_bit;

architecture Structural of full_adder_8_bit is
    
    signal carry : STD_LOGIC_VECTOR(8 downto 0);
    
    component full_adder_1_bit
        Port (
            A : in STD_LOGIC;
            B : in STD_LOGIC;
            Ci : in STD_LOGIC;
            res : out STD_LOGIC;
            Co : out STD_LOGIC
        );
    end component;
    
    begin

carry(0) <= '0';

bit_0: full_adder_1_bit
port map(
    A => A(0),
    B => B(0),
    Ci => carry(0), 
    res => sum(0),
    Co => carry(1)
); 

bit_1: full_adder_1_bit
port map(
    A => A(1),
    B => B(1),
    Ci => carry(1), 
    res => sum(1),
    Co => carry(2)
);    

bit_2: full_adder_1_bit
port map(
    A => A(2),
    B => B(2),
    Ci => carry(2), 
    res => sum(2),
    Co => carry(3)
);

bit_3: full_adder_1_bit
port map(
    A => A(3),
    B => B(3),
    Ci => carry(3), 
    res => sum(3),
    Co => carry(4)
);

bit_4: full_adder_1_bit
port map(
    A => A(4),
    B => B(4),
    Ci => carry(4), 
    res => sum(4),
    Co => carry(5)
);

bit_5: full_adder_1_bit
port map(
    A => A(5),
    B => B(5),
    Ci => carry(5), 
    res => sum(5),
    Co => carry(6)
);

bit_6: full_adder_1_bit
port map(
    A => A(6),
    B => B(6),
    Ci => carry(6), 
    res => sum(6),
    Co => carry(7)
);    

bit_7: full_adder_1_bit
port map(
    A => A(7),
    B => B(7),
    Ci => carry(7), 
    res => sum(7),
    Co => carry(8)
);

Cout <= carry(8);
end Structural; 
