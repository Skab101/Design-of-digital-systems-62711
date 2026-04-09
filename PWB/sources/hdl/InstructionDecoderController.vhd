
--Note: Kommentarer er gjort flotte og inline vha. AI
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity InstructionDecoderController is
    port (
        RESET              : in  std_logic;
        CLK                : in  std_logic;
        IR                 : in  std_logic_vector(15 downto 0);
        V, C, N, Z         : in  std_logic;
        PS                 : out std_logic_vector(1 downto 0);
        IL                 : out std_logic;
        DX, AX, BX, FS    : out std_logic_vector(3 downto 0);
        MB, MD, RW, MM, MW : out std_logic
    );
end InstructionDecoderController;

architecture IDC_Behavorial of InstructionDecoderController is

    type state_type is (INF, EX0, EX1, EX2, EX3, EX4);
    signal current_state, next_state : state_type;

begin

    -- Process 1: State register (sekventiel)
    state_reg: process(CLK, RESET)
    begin
        if RESET = '1' then
            current_state <= INF;
        elsif rising_edge(CLK) then
            current_state <= next_state;
        end if;
    end process;

    -- Process 2: Next-state logik + output logik (kombinatorisk)
    control_logic: process(current_state, IR, V, C, N, Z)
    begin
        -- Standardværdier (undgår latches)
        next_state <= INF;
        PS  <= "00";
        IL  <= '0';
        DX  <= '0' & IR(8 downto 6);
        AX  <= '0' & IR(5 downto 3);
        BX  <= '0' & IR(2 downto 0);
        MB  <= '0';
        FS  <= "0000";
        MD  <= '0';
        RW  <= '0';
        MM  <= '0';
        MW  <= '0';

        case current_state is

            ----------------------------------------------------------------
            -- INF: Instruction Fetch — IR <- M[PC]
            ----------------------------------------------------------------
            when INF =>
                next_state <= EX0;
                IL  <= '1';
                MM  <= '1';

            ----------------------------------------------------------------
            -- EX0: Decode opcode, udfør instruktion
            ----------------------------------------------------------------
            when EX0 =>
                case IR(15 downto 9) is

                    -- ALU register-register operationer (2-cyklus)
                    -- FS = IR(12:9) giver den korrekte funktionskode direkte
                    when "0000000" |  -- MOVA: R[DR] <- R[SA]
                         "0000001" |  -- INC:  R[DR] <- R[SA] + 1
                         "0000010" |  -- ADD:  R[DR] <- R[SA] + R[SB]
                         "0000101" |  -- SUB:  R[DR] <- R[SA] - R[SB]
                         "0000110" |  -- DEC:  R[DR] <- R[SA] - 1
                         "0001000" |  -- OR:   R[DR] <- R[SA] v R[SB]
                         "0001001" |  -- AND:  R[DR] <- R[SA] ^ R[SB]
                         "0001010" |  -- XOR:  R[DR] <- R[SA] xor R[SB]
                         "0001011" |  -- NOT:  R[DR] <- R[SA]'
                         "0001100" => -- MOVB: R[DR] <- R[SB]
                        next_state <= INF;
                        PS  <= "01";
                        FS  <= IR(12 downto 9);
                        RW  <= '1';

                    -- SRM: Shift right multiple (flercyklus)
                    -- EX0: R8 <- R[SA], tjek Z
                    when "0001101" =>
                        DX  <= "1000";
                        RW  <= '1';
                        if Z = '1' then
                            next_state <= INF;
                            PS <= "01";
                        else
                            next_state <= EX1;
                        end if;

                    -- SLM: Shift left multiple (flercyklus)
                    -- EX0: R8 <- R[SA], tjek Z
                    when "0001110" =>
                        DX  <= "1000";
                        RW  <= '1';
                        if Z = '1' then
                            next_state <= INF;
                            PS <= "01";
                        else
                            next_state <= EX1;
                        end if;

                    -- LD: R[DR] <- M[R[SA]]
                    when "0010000" =>
                        next_state <= INF;
                        PS  <= "01";
                        MD  <= '1';
                        RW  <= '1';

                    -- LRI: Load register immediate (3-cyklus)
                    -- EX0: R8 <- M[R[SA]]
                    when "0010001" =>
                        next_state <= EX1;
                        DX  <= "1000";
                        MD  <= '1';
                        RW  <= '1';

                    -- ST: M[R[SA]] <- R[SB]
                    when "0100000" =>
                        next_state <= INF;
                        PS  <= "01";
                        MW  <= '1';

                    -- ADI: R[DR] <- R[SA] + zf OP
                    when "1000010" =>
                        next_state <= INF;
                        PS  <= "01";
                        FS  <= "0010";
                        MB  <= '1';
                        RW  <= '1';

                    -- LDI: R[DR] <- zf OP
                    when "1001100" =>
                        next_state <= INF;
                        PS  <= "01";
                        FS  <= "1100";
                        MB  <= '1';
                        RW  <= '1';

                    -- BRZ: Branch on zero
                    when "1100000" =>
                        next_state <= INF;
                        if Z = '1' then
                            PS <= "10";
                        else
                            PS <= "01";
                        end if;

                    -- BRN: Branch on negative
                    when "1100001" =>
                        next_state <= INF;
                        if N = '1' then
                            PS <= "10";
                        else
                            PS <= "01";
                        end if;

                    -- JMP: PC <- R[SA]
                    when "1110000" =>
                        next_state <= INF;
                        PS  <= "11";

                    when others =>
                        next_state <= INF;
                        PS <= "01";

                end case;

            ----------------------------------------------------------------
            -- EX1: Anden eksekveringscyklus
            ----------------------------------------------------------------
            when EX1 =>
                case IR(15 downto 9) is

                    -- LRI: R[DR] <- M[R8]
                    when "0010001" =>
                        next_state <= INF;
                        PS  <= "01";
                        AX  <= "1000";
                        MD  <= '1';
                        RW  <= '1';

                    -- SRM/SLM: R9 <- zf OP
                    when "0001101" | "0001110" =>
                        next_state <= EX2;
                        DX  <= "1001";
                        FS  <= "1100";
                        MB  <= '1';
                        RW  <= '1';

                    when others =>
                        next_state <= INF;

                end case;

            ----------------------------------------------------------------
            -- EX2: SRM/SLM — R8 <- sr/sl R8
            ----------------------------------------------------------------
            when EX2 =>
                next_state <= EX3;
                DX  <= "1000";
                AX  <= "1000";
                FS  <= IR(12 downto 9);  -- 1101=sr, 1110=sl
                RW  <= '1';

            ----------------------------------------------------------------
            -- EX3: SRM/SLM — R9 <- R9 - 1, tjek om færdig
            ----------------------------------------------------------------
            when EX3 =>
                DX  <= "1001";
                AX  <= "1001";
                FS  <= "0110";
                RW  <= '1';
                if Z = '1' then
                    next_state <= EX4;
                else
                    next_state <= EX2;
                end if;

            ----------------------------------------------------------------
            -- EX4: SRM/SLM — R[DR] <- R8, færdig
            ----------------------------------------------------------------
            when EX4 =>
                next_state <= INF;
                PS  <= "01";
                AX  <= "1000";
                RW  <= '1';

        end case;
    end process;

end IDC_Behavorial;
