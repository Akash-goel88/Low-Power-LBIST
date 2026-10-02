-- library ieee;
-- use ieee.std_logic_1164.all;

-- entity dut is
--   generic (
--     NUM_ADDERS : integer := 40  -- Changed to 40 for clean division
--   );
--   port (
--     a    : in  std_logic_vector(NUM_ADDERS-1 downto 0);
--     b    : in  std_logic_vector(NUM_ADDERS-1 downto 0);
--     cin  : in  std_logic;
--     sum  : out std_logic_vector(NUM_ADDERS-1 downto 0);
--     cout : out std_logic_vector(NUM_ADDERS/8-1 downto 0)  -- Now 40/8=5 bits
--   );
-- end entity;

-- architecture rtl of dut is
--   signal carry_chain : std_logic_vector(NUM_ADDERS downto 0);
-- begin
--   carry_chain(0) <= cin;
  
--   gen_adders: for i in 0 to NUM_ADDERS-1 generate
--     sum(i) <= a(i) xor b(i) xor carry_chain(i);
--     carry_chain(i+1) <= (a(i) and b(i)) or (a(i) and carry_chain(i)) or (b(i) and carry_chain(i));
--   end generate;
  
--   -- Generate carry outputs
--   gen_carries: for i in 0 to NUM_ADDERS/8-1 generate
--     cout(i) <= carry_chain((i+1)*8);
--   end generate;
-- end architecture;

-- --simple 8 bit version:
-- -- dut.vhd
-- library ieee;
-- use ieee.std_logic_1164.all;

-- entity dut is
--   port (
--     a    : in  std_logic_vector(7 downto 0);
--     b    : in  std_logic_vector(7 downto 0);
--     cin  : in  std_logic;
--     sum  : out std_logic_vector(7 downto 0);
--     cout : out std_logic
--   );
-- end entity;

-- architecture rtl of dut is
--   signal carry_chain : std_logic_vector(8 downto 0);
-- begin
--   carry_chain(0) <= cin;
  
--   gen_adders: for i in 0 to 7 generate
--     sum(i) <= a(i) xor b(i) xor carry_chain(i);
--     carry_chain(i+1) <= (a(i) and b(i)) or (a(i) and carry_chain(i)) or (b(i) and carry_chain(i));
--   end generate;
  
--   cout <= carry_chain(8);
-- end architecture;


--DUT
-- library ieee;
-- use ieee.std_logic_1164.all;

-- entity dut_32bit is
--   port (
--     a    : in  std_logic_vector(31 downto 0);
--     b    : in  std_logic_vector(31 downto 0);
--     cin  : in  std_logic := '0';
--     sum  : out std_logic_vector(31 downto 0);
--     cout : out std_logic
--   );
-- end entity;

-- architecture rtl of dut_32bit is
--   signal carry : std_logic_vector(32 downto 0);
-- begin
--   carry(0) <= cin;

--   gen_add: for i in 0 to 31 generate
--   begin
--     sum(i) <= a(i) xor b(i) xor carry(i);
--     carry(i+1) <= (a(i) and b(i)) or 
--                   (a(i) and carry(i)) or 
--                   (b(i) and carry(i));
--   end generate;

--   cout <= carry(32);
-- end architecture;


--simple, again:
library ieee;
use ieee.std_logic_1164.all;

entity dut is
  port (
    a    : in  std_logic_vector(7 downto 0);
    b    : in  std_logic_vector(7 downto 0);
    cin  : in  std_logic;
    sum  : out std_logic_vector(7 downto 0);
    cout : out std_logic
  );
end entity;

architecture rtl of dut is
  signal carry_chain : std_logic_vector(8 downto 0);
begin
  carry_chain(0) <= cin;
  gen_adders: for i in 0 to 7 generate
    sum(i) <= a(i) xor b(i) xor carry_chain(i);
    carry_chain(i+1) <= (a(i) and b(i)) or (a(i) and carry_chain(i)) or (b(i) and carry_chain(i));
  end generate;
  cout <= carry_chain(8);
end architecture;

