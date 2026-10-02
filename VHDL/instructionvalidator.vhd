library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity InstructionValidator is
    port (
        Instr_in   : in  std_logic_vector(31 downto 0);  -- from Instruction Memory
        Instr_out  : out std_logic_vector(31 downto 0);  -- to Control + Register File
        Valid      : out std_logic                       -- '1' = instruction ok
    );
end entity InstructionValidator;

architecture Behavioral of InstructionValidator is

    signal opcode : std_logic_vector(5 downto 0);
    signal funct  : std_logic_vector(5 downto 0);

begin

    opcode <= Instr_in(31 downto 26);
    funct  <= Instr_in(5 downto 0);

    process(opcode, funct, Instr_in)
        variable is_valid : std_logic;
    begin
        is_valid := '0';

        -- ***** SUPPORTED OPCODES / FUNCTIONS *****
        case opcode is

            when "000000" =>  -- R-type
                case funct is
                    -- add, addu, sub, subu, and, or, xor, nor, slt
                    when "100000" | "100001" | "100010" | "100011" |
                         "100100" | "100101" | "100110" | "100111" |
                         "101010" =>
                        is_valid := '1';
                    when others =>
                        is_valid := '0';
                end case;

            when "100011" =>  -- lw
                is_valid := '1';

            when "101011" =>  -- sw
                is_valid := '1';

            when "000100" =>  -- beq
                is_valid := '1';

            when "000101" =>  -- bne
                is_valid := '1';

            when "001000" =>  -- addi
                is_valid := '1';

            when "001100" =>  -- andi
                is_valid := '1';

            when "001101" =>  -- ori
                is_valid := '1';

            when "000010" =>  -- j
                is_valid := '1';

            when others =>
                is_valid := '0';
        end case;

        Valid <= is_valid;

        if is_valid = '1' then
            Instr_out <= Instr_in;          -- pass through
        else
            Instr_out <= (others => '0');   -- invalid → NOP / all zeros
        end if;
    end process;

end architecture Behavioral;