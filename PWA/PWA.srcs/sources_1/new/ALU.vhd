library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ALU is
    Port (
        A, B     : in  STD_LOGIC_VECTOR(7 downto 0);
        JSel     : in  STD_LOGIC_VECTOR(3 downto 0);
        Cin      : in  STD_LOGIC;
        V, C     : out STD_LOGIC;
        J        : out STD_LOGIC_VECTOR(7 downto 0)
    );
end ALU;

architecture ALU_Structural of ALU is

signal ASig, BSig, JAdd, JLO: STD_LOGIC_VECTOR(7 downto 0);
begin
    
        full_adder: entity work.full_adder_8_bit
    port map(
            A    => ASig,
            B    => BSig,
            sum  => JAdd,
            Cin  => Cin,
            Cout =>  C,
            V => V
    );
    
    ASig <= A;
    Bsig(0) <= ((B(0) AND JSel(0)) OR ((NOT B(0)) AND JSel(1))) AND (NOT JSel(3));
    Bsig(1) <= ((B(1) AND JSel(0)) OR ((NOT B(1)) AND JSel(1))) AND (NOT JSel(3));
    Bsig(2) <= ((B(2) AND JSel(0)) OR ((NOT B(2)) AND JSel(1))) AND (NOT JSel(3));
    Bsig(3) <= ((B(3) AND JSel(0)) OR ((NOT B(3)) AND JSel(1))) AND (NOT JSel(3));
    Bsig(4) <= ((B(4) AND JSel(0)) OR ((NOT B(4)) AND JSel(1))) AND (NOT JSel(3));
    Bsig(5) <= ((B(5) AND JSel(0)) OR ((NOT B(5)) AND JSel(1))) AND (NOT JSel(3));
    Bsig(6) <= ((B(6) AND JSel(0)) OR ((NOT B(6)) AND JSel(1))) AND (NOT JSel(3));
    Bsig(7) <= ((B(7) AND JSel(0)) OR ((NOT B(7)) AND JSel(1))) AND (NOT JSel(3));



    JLO <= ((7 downto 0=>JSel(2) AND (NOT JSel(0) AND     Cin))   AND (A OR B))  OR
           ((7 downto 0=>JSel(2) AND (NOT JSel(0) AND NOT Cin))  AND (A AND B))  OR
           ((7 downto 0=>JSel(2) AND (    JSel(0) AND NOT Cin))  AND (A XOR B))  OR
           ((7 downto 0=>JSel(2) AND (    JSel(0) AND     Cin))  AND NOT(A));

    




J <= (JLo AND (7 downto 0 => JSel(3))) OR (JAdd AND (7 downto 0 => NOT JSel(3)));


end ALU_Structural;
