-- -- -- misr.vhd
-- -- library ieee;
-- -- use ieee.std_logic_1164.all;
-- -- use ieee.numeric_std.all;

-- -- entity misr is
-- --   generic (
-- --     WIDTH : integer := 32
-- --   );
-- --   port (
-- --     clk    : in  std_logic;
-- --     reset  : in  std_logic;
-- --     en     : in  std_logic;
-- --     data_in: in  std_logic;
-- --     signature : out std_logic_vector(WIDTH-1 downto 0);
-- --     misr_enable : in std_logic := '1'  -- Added enable for debug
-- --   );
-- -- end entity;

-- -- architecture rtl of misr is
-- --   signal regsig : std_logic_vector(WIDTH-1 downto 0);
-- -- begin
-- --   process(clk, reset)
-- --   variable feedback : std_logic;
-- --   begin
-- --     if reset = '1' then
-- --       regsig <= (others => '0');
-- --     elsif rising_edge(clk) then
-- --       if en = '1' and misr_enable = '1' then  -- Added enable condition
-- --         feedback := regsig(WIDTH-1) xor data_in;
-- --         regsig <= regsig(WIDTH-2 downto 0) & feedback;
-- --       end if;
-- --     end if;
-- --   end process;
-- --   signature <= regsig;
-- -- end architecture;


-- -- simpler version:
-- -- misr.vhd
-- library ieee;
-- use ieee.std_logic_1164.all;

-- entity misr is
--   generic (
--     WIDTH : integer := 32
--   );
--   port (
--     clk    : in  std_logic;
--     reset  : in  std_logic;
--     en     : in  std_logic;
--     data_in: in  std_logic;
--     signature : out std_logic_vector(WIDTH-1 downto 0)
--   );
-- end entity;

-- architecture rtl of misr is
--   signal regsig : std_logic_vector(WIDTH-1 downto 0);
-- begin
--   process(clk, reset)
--   variable feedback : std_logic;
--   begin
--     if reset = '1' then
--       regsig <= (others => '0');
--     elsif rising_edge(clk) then
--       if en = '1' then
--         feedback := regsig(WIDTH-1) xor data_in;
--         regsig <= regsig(WIDTH-2 downto 0) & feedback;
--       end if;
--     end if;
--   end process;
--   signature <= regsig;
-- end architecture;

-- library ieee;
-- use ieee.std_logic_1164.all;
-- use ieee.numeric_std.all;

-- entity misr is
--   generic (
--     WIDTH : integer := 32
--   );
--   port (
--     clk    : in  std_logic;
--     reset  : in  std_logic;
--     en     : in  std_logic;
--     data_in: in  std_logic;
--     signature : out std_logic_vector(WIDTH-1 downto 0)
--   );
-- end entity;

-- architecture rtl of misr is
--   signal regsig : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
-- begin
--   process(clk)
--     variable fb : std_logic;
--   begin
--     if rising_edge(clk) then
--       if reset = '1' then
--         regsig <= (others => '0');
--       elsif en = '1' then
--         fb := regsig(WIDTH-1) xor data_in xor regsig(WIDTH-3) xor regsig(WIDTH-4) xor regsig(WIDTH-6);
--         regsig <= regsig(WIDTH-2 downto 0) & fb;
--       end if;
--     end if;
--   end process;

--   signature <= regsig;
-- end architecture;


--simple but generalized:
library ieee;
use ieee.std_logic_1164.all;

entity misr is
  generic (
    WIDTH : integer := 32
  );
  port (
    clk    : in  std_logic;
    reset  : in  std_logic;               -- synchronous reset
    en     : in  std_logic;
    data_in: in  std_logic;
    signature : out std_logic_vector(WIDTH-1 downto 0)
  );
end entity;

architecture rtl of misr is
  signal regsig : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
begin
  process(clk)
    variable feedback : std_logic;
  begin
    if rising_edge(clk) then
      if reset = '1' then
        regsig <= (others => '0');
      elsif en = '1' then
        feedback := regsig(WIDTH-1) xor data_in;
        regsig <= regsig(WIDTH-2 downto 0) & feedback;
      end if;
    end if;
  end process;

  signature <= regsig;
end architecture;
