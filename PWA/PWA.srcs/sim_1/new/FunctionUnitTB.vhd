library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity FunctionUnitTB is
end FunctionUnitTB;

architecture Behavioral of FunctionUnitTB is

    signal A, B : STD_LOGIC_VECTOR(7 downto 0);
    signal FS3, FS2, FS1, FS0, Cin : STD_LOGIC;
    signal V, C, N, Z : STD_LOGIC;
    signal F : STD_LOGIC_VECTOR(7 downto 0);

begin

    uut: entity work.FunctionUnit
    port map (
        A   => A,
        B   => B,
        FS3 => FS3,
        FS2 => FS2,
        FS1 => FS1,
        FS0 => FS0,
        Cin => Cin,
        V   => V,
        C   => C,
        N   => N,
        Z   => Z,
        F   => F
    );

    stim: process
    begin
        A <= "00000101"; -- 5
        B <= "00000011"; -- 3

        -- =============================================
        -- ALU TEST 1: A + B  (FS=0010, Cin=0)
        -- Forventet: F = 5 + 3 = 8 = "00001000"
        -- =============================================
        FS3 <= '0'; FS2 <= '0'; FS1 <= '1'; FS0 <= '0'; Cin <= '0';
        wait for 50 ns;

        -- =============================================
        -- ALU TEST 2: A OR B  (FS=1000, Cin=0)
        -- Forventet: F = 0101 OR 0011 = "00000111" = 7
        -- =============================================
        FS3 <= '1'; FS2 <= '0'; FS1 <= '0'; FS0 <= '0'; Cin <= '0';
        wait for 50 ns;

        -- =============================================
        -- SHIFTER TEST 1: sr B  (FS=1101)
        -- Shift right: B=00000011 -> "00000001"
        -- =============================================
        FS3 <= '1'; FS2 <= '1'; FS1 <= '0'; FS0 <= '1'; Cin <= '0';
        wait for 50 ns;

        -- =============================================
        -- SHIFTER TEST 2: sl B  (FS=1110)
        -- Shift left: B=00000011 -> "00000110"
        -- =============================================
        FS3 <= '1'; FS2 <= '1'; FS1 <= '1'; FS0 <= '0'; Cin <= '0';
        wait for 50 ns;

        wait;
    end process;

end Behavioral;
