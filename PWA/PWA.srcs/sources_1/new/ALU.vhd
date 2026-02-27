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
        Cin      : in  STD_LOGIC;
        V, C     : out STD_LOGIC;
        J        : out STD_LOGIC_VECTOR(7 downto 0)
    );
end ALU;

architecture ALU_Structural of ALU is


signal ASig, BSig: STD_LOGIC_VECTOR(7 downto 0);
begin

    full_adder: entity work.full_adder_8_bit
    port map(
            A    => ASig,
            B    => BSig,
            sum  => J,
            Cin  => Cin,
            Cout =>  C
    );






end ALU_Structural;
