-- -- lfsr.vhd (updated)
-- library ieee;
-- use ieee.std_logic_1164.all;
-- use ieee.numeric_std.all;

-- entity lfsr is
--   generic (
--     WIDTH : integer := 32
--   );
--   port (
--     clk     : in  std_logic;
--     reset   : in  std_logic;
--     load    : in  std_logic;
--     seed    : in  std_logic_vector(WIDTH-1 downto 0);
--     out_bit : out std_logic;
--     state   : out std_logic_vector(WIDTH-1 downto 0);
--     advance : in  std_logic  -- Added: control when to advance
--   );
-- end entity;

-- architecture rtl of lfsr is
--   signal internal_state : std_logic_vector(WIDTH-1 downto 0);
-- begin
--   process(clk, reset)
--   variable newbit : std_logic;
--   begin
--     if reset = '1' then
--       internal_state <= (others => '1');
--     elsif rising_edge(clk) then
--       if load = '1' then
--         internal_state <= seed;
--       elsif advance = '1' then  -- Only advance when commanded
--         newbit := internal_state(31) xor internal_state(21) xor internal_state(1) xor internal_state(0);
--         internal_state <= newbit & internal_state(WIDTH-1 downto 1);
--       end if;
--     end if;
--   end process;
  
--   out_bit <= internal_state(0);
--   state <= internal_state;
-- end architecture;



--simple:
-- lfsr.vhd
-- library ieee;
-- use ieee.std_logic_1164.all;

-- entity lfsr is
--   generic (
--     WIDTH : integer := 32
--   );
--   port (
--     clk     : in  std_logic;
--     reset   : in  std_logic;
--     load    : in  std_logic;
--     seed    : in  std_logic_vector(WIDTH-1 downto 0);
--     out_bit : out std_logic;
--     state   : out std_logic_vector(WIDTH-1 downto 0);
--     advance : in  std_logic
--   );
-- end entity;

-- architecture rtl of lfsr is
--   signal internal_state : std_logic_vector(WIDTH-1 downto 0) := (others => '1');
-- begin
--   process(clk, reset)
--   variable newbit : std_logic;
--   begin
--     if reset = '1' then
--       internal_state <= (others => '1');
--     elsif rising_edge(clk) then
--       if load = '1' then
--         internal_state <= seed;
--       elsif advance = '1' then
--         newbit := internal_state(31) xor internal_state(21) xor internal_state(1) xor internal_state(0);
--         internal_state <= newbit & internal_state(WIDTH-1 downto 1);
--       end if;
--     end if;
--   end process;
  
--   out_bit <= internal_state(0);
--   state <= internal_state;
-- end architecture;


-- library ieee;
-- use ieee.std_logic_1164.all;
-- use ieee.numeric_std.all;

-- entity lfsr is
--   generic (
--     WIDTH : integer := 32
--   );
--   port (
--     clk     : in  std_logic;                       -- clock used to shift the LFSR
--     reset   : in  std_logic;                       -- synchronous active-high reset
--     load    : in  std_logic;                       -- load seed when '1'
--     seed    : in  std_logic_vector(WIDTH-1 downto 0);
--     out_bit : out std_logic;                       -- serial output bit (LSB)
--     state   : out std_logic_vector(WIDTH-1 downto 0);
--     advance : in  std_logic                        -- shift when '1' on rising edge
--   );
-- end entity;

-- architecture rtl of lfsr is
--   signal internal_state : std_logic_vector(WIDTH-1 downto 0) := (others => '1');
-- begin
--   process(clk)
--     variable newbit : std_logic;
--   begin
--     if rising_edge(clk) then
--       if reset = '1' then
--         -- initialize to a non-zero pattern to avoid all-zero lock
--         internal_state <= (others => '1');
--       elsif load = '1' then
--         internal_state <= seed;
--       elsif advance = '1' then
--         -- taps chosen for 32-bit (example polynomial): x^32 + x^22 + x^2 + x + 1
--         newbit := internal_state(WIDTH-1) xor internal_state(21) xor internal_state(1) xor internal_state(0);
--         internal_state <= newbit & internal_state(WIDTH-1 downto 1);
--       end if;
--     end if;
--   end process;

--   out_bit <= internal_state(0);
--   state   <= internal_state;
-- end architecture;


--simple but generalized :
library ieee;
use ieee.std_logic_1164.all;

entity lfsr is
  generic (
    WIDTH : integer := 32
  );
  port (
    clk     : in  std_logic;
    reset   : in  std_logic;             -- synchronous active-high reset
    load    : in  std_logic;             -- synchronous load pulse (1 cycle)
    seed    : in  std_logic_vector(WIDTH-1 downto 0);
    out_bit : out std_logic;
    state   : out std_logic_vector(WIDTH-1 downto 0);
    advance : in  std_logic              -- when '1' on rising edge, LFSR advances
  );
end entity;

architecture rtl of lfsr is
  signal internal_state : std_logic_vector(WIDTH-1 downto 0) := (others => '1');

begin
  process(clk)
    variable newbit : std_logic;
  begin
    if rising_edge(clk) then
      if reset = '1' then
        -- Seed LFSR once at global reset
        internal_state <= seed;
      elsif load = '1' then
        -- Optional manual reload (normally '0' in LBIST)
        internal_state <= seed;
      elsif advance = '1' then
        newbit := internal_state(WIDTH-1) xor
                  internal_state(21 mod WIDTH) xor
                  internal_state(1) xor
                  internal_state(0);
        internal_state <= newbit & internal_state(WIDTH-1 downto 1);
      end if;
    end if;
  end process;

  out_bit <= internal_state(0);
  state <= internal_state;
end architecture;
