----------------------------------------------------------------------------------
-- Module Name: MUX16x1x8
-- Description: 16-to-1 multiplexer, 8-bit wide
--              D_Select(3:0) chooses which register output appears at Y_Data
--              Used for A_Data and B_Data output muxes in the Register File
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MUX16x1x8 is
    Port (
        R0, R1, R2, R3     : in  STD_LOGIC_VECTOR(7 downto 0);
        R4, R5, R6, R7     : in  STD_LOGIC_VECTOR(7 downto 0);
        R8, R9, R10, R11   : in  STD_LOGIC_VECTOR(7 downto 0);
        R12, R13, R14, R15 : in  STD_LOGIC_VECTOR(7 downto 0);
        D_Select            : in  STD_LOGIC_VECTOR(3 downto 0);
        Y_Data              : out STD_LOGIC_VECTOR(7 downto 0)
    );
end MUX16x1x8;
architecture dataflow of MUX16x1x8 is
begin
gen_mux: for i in 0 to 7 generate -- dette loop generer en et bit mux for alle 8 bit data registre
    Y_Data(i) <=
       (R0(i)  and (not D_Select(3)) and (not D_Select(2)) and (not D_Select(1)) and (not D_Select(0))) or
       (R1(i)  and (not D_Select(3)) and (not D_Select(2)) and (not D_Select(1)) and     D_Select(0)) or
       (R2(i)  and (not D_Select(3)) and (not D_Select(2)) and     D_Select(1) and (not D_Select(0))) or
       (R3(i)  and (not D_Select(3)) and (not D_Select(2)) and     D_Select(1) and     D_Select(0)) or
       (R4(i)  and (not D_Select(3)) and     D_Select(2) and (not D_Select(1)) and (not D_Select(0))) or
       (R5(i)  and (not D_Select(3)) and     D_Select(2) and (not D_Select(1)) and     D_Select(0)) or
       (R6(i)  and (not D_Select(3)) and     D_Select(2) and     D_Select(1) and (not D_Select(0))) or
       (R7(i)  and (not D_Select(3)) and     D_Select(2) and     D_Select(1) and     D_Select(0)) or
       (R8(i)  and     D_Select(3)  and (not D_Select(2)) and (not D_Select(1)) and (not D_Select(0))) or
       (R9(i)  and     D_Select(3)  and (not D_Select(2)) and (not D_Select(1)) and     D_Select(0)) or
       (R10(i) and     D_Select(3)  and (not D_Select(2)) and     D_Select(1) and (not D_Select(0))) or
       (R11(i) and     D_Select(3)  and (not D_Select(2)) and     D_Select(1) and     D_Select(0)) or
       (R12(i) and     D_Select(3)  and     D_Select(2) and (not D_Select(1)) and (not D_Select(0))) or
       (R13(i) and     D_Select(3)  and     D_Select(2) and (not D_Select(1)) and     D_Select(0)) or
       (R14(i) and     D_Select(3)  and     D_Select(2) and     D_Select(1) and (not D_Select(0))) or
       (R15(i) and     D_Select(3)  and     D_Select(2) and     D_Select(1) and     D_Select(0));
end generate;
end dataflow;
