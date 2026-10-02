-- -- phase_shifter.vhd
-- library ieee;
-- use ieee.std_logic_1164.all;
-- use ieee.numeric_std.all;

-- entity phase_shifter is
--   generic (
--     NUM_OUTPUTS : integer := 128;
--     LFSR_WIDTH  : integer := 32
--   );
--   port (
--     lfsr_state  : in  std_logic_vector(LFSR_WIDTH-1 downto 0);
--     scan_inputs : out std_logic_vector(NUM_OUTPUTS-1 downto 0)
--   );
-- end entity;

-- architecture rtl of phase_shifter is
-- begin
--   process(lfsr_state)
--     variable temp : std_logic_vector(NUM_OUTPUTS-1 downto 0);
--   begin
--     -- Simple XOR-based phase shifter to create multiple scan chain inputs
--     -- from the LFSR state, ensuring low correlation between bits
--     for i in 0 to NUM_OUTPUTS-1 loop
--       -- Use different XOR combinations of LFSR bits for each output
--       -- This creates pseudo-independent scan chain inputs
--       temp(i) := lfsr_state(i mod LFSR_WIDTH) xor 
--                  lfsr_state((i + 7) mod LFSR_WIDTH) xor 
--                  lfsr_state((i + 19) mod LFSR_WIDTH);
--     end loop;
--     scan_inputs <= temp;
--   end process;
-- end architecture;

-- library ieee;
-- use ieee.std_logic_1164.all;

-- entity phase_shifter_64 is
--   port (
--     lfsr_state : in  std_logic_vector(31 downto 0);
--     a_out      : out std_logic_vector(31 downto 0);
--     b_out      : out std_logic_vector(31 downto 0)
--   );
-- end entity;

-- architecture rtl of phase_shifter_64 is
-- begin
--   process(lfsr_state)
--   begin
--     for i in 0 to 31 loop
--       a_out(i) <= lfsr_state(i) xor lfsr_state((i + 5) mod 32) xor lfsr_state((i + 13) mod 32);
--       b_out(i) <= lfsr_state((i + 3) mod 32) xor lfsr_state((i + 11) mod 32) xor lfsr_state((i + 23) mod 32);
--     end loop;
--   end process;
-- end architecture;


--simple but generalized:
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity phase_shifter is
  generic (
    NUM_OUTPUTS : integer := 32;
    LFSR_WIDTH  : integer := 32
  );
  port (
    lfsr_state  : in  std_logic_vector(LFSR_WIDTH-1 downto 0);
    scan_inputs : out std_logic_vector(NUM_OUTPUTS-1 downto 0)
  );
end entity;

architecture rtl of phase_shifter is
begin
  process(lfsr_state)
    variable temp : std_logic_vector(NUM_OUTPUTS-1 downto 0);
  begin
    for i in 0 to NUM_OUTPUTS-1 loop
      temp(i) := lfsr_state(i mod LFSR_WIDTH) xor
                 lfsr_state((i + 7) mod LFSR_WIDTH) xor
                 lfsr_state((i + 19) mod LFSR_WIDTH);
    end loop;
    scan_inputs <= temp;
  end process;
end architecture;
