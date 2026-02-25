----------------------------------------------------------------------------------
-- Module Name: ALU
-- Description: Arithmetic Logic Unit (PWA spec)
--              J_Select(3:0) controls the operation:
--                J3=0: arithmetic (J2=S1, J1=S0, J0=Cin)
--                  0000: F=A       0001: F=A+1
--                  0010: F=A+B     0011: F=A+B+1
--                  0100: F=A+B'    0101: F=A-B
--                  0110: F=A-1     0111: F=A
--                J3=1: logic (J1,J0 select)
--                  1X00: F=A or B    (NOTE: swapped vs textbook!)
--                  1X01: F=A and B   (NOTE: swapped vs textbook!)
--                  1X10: F=A xor B
--                  1X11: F=not A
--              Flags: V (overflow), C (carry-out)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ALU is
    Port (
        A, B     : in  STD_LOGIC_VECTOR(7 downto 0); 
        J_Select : in  STD_LOGIC_VECTOR(3 downto 0);
        V, C     : out STD_LOGIC;
        J        : out STD_LOGIC_VECTOR(7 downto 0)
    );
end ALU;

architecture ALU_Behavorial of ALU is

    component arithmetic is
        generic (n : integer := 8);
        Port (A, B     : in  STD_LOGIC_VECTOR(n-1 downto 0);
              S0, S1   : in  STD_LOGIC;
              Cin      : in  STD_LOGIC;
              G        : out STD_LOGIC_VECTOR(n-1 downto 0);
              Cout     : out STD_LOGIC;
              overflow : out STD_LOGIC);
    end component;

    component logic_unit is
        generic (n : integer := 8);
        Port (A, B   : in  STD_LOGIC_VECTOR(n-1 downto 0);
              J1, J0 : in  STD_LOGIC;
              G      : out STD_LOGIC_VECTOR(n-1 downto 0));
    end component;

    


begin

end ALU_Behavorial;
