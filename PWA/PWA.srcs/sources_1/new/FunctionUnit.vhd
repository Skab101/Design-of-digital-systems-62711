

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity FunctionUnit is
    Port (
        A, B                   : in  STD_LOGIC_VECTOR(7 downto 0);
        FS3, FS2, FS1, FS0     : in  STD_LOGIC;
        V, C, N, Z             : out STD_LOGIC;
        F                      : out STD_LOGIC_VECTOR(7 downto 0)
    );
end FunctionUnit;

architecture structural of FunctionUnit is

    component ALU is
        Port (A, B     : in  STD_LOGIC_VECTOR(7 downto 0);
              JSel : in  STD_LOGIC_VECTOR(3 downto 0);
              V, C     : out STD_LOGIC;
              J        : out STD_LOGIC_VECTOR(7 downto 0));
    end component;

    component Shifter is
        Port (B        : in  STD_LOGIC_VECTOR(7 downto 0);
              HSel : in  STD_LOGIC_VECTOR(1 downto 0);
              H        : out STD_LOGIC_VECTOR(7 downto 0));
    end component;

    component FunctionSelect is
        Port (FS   : in  STD_LOGIC_vector(3 downto 0);
              JSel : out STD_LOGIC_VECTOR(3 downto 0);
              HSel : out STD_LOGIC_VECTOR(3 downto 0);
              MF   : out STD_LOGIC);
    end component;

    component MUXF is
        Port (J, H       : in  STD_LOGIC_VECTOR(7 downto 0);
              MF : in  STD_LOGIC;
              Y          : out STD_LOGIC_VECTOR(7 downto 0));
    end component;
-- mangler 
    component NegZero is
        Port (MUXF : in  STD_LOGIC_VECTOR(7 downto 0);
              N, Z : out STD_LOGIC);
    end component;

begin

end structural;
