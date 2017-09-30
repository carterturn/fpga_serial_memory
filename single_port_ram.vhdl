library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity single_port_ram is
  port(we : in std_logic; address : in std_logic_vector(7 downto 0);
       data_in : in std_logic_vector(7 downto 0); data_out : out std_logic_vector(7 downto 0));
end single_port_ram;

architecture arch_dist_ram of single_port_ram is
  signal address_int : integer := 0;

  type ram_t is array (0 to 255) of std_logic_vector(7 downto 0);
  signal ram : ram_t := (others => (others => '0'));
  
  attribute ram_style: string;
  attribute ram_style of ram : signal is "distributed";
begin
  address_int <= to_integer(unsigned(address));
  
  process (we, address_int, ram) is
  begin
    if rising_edge(we) then
      ram(address_int) <= data_in;
    end if;
    data_out <= ram(address_int);
  end process;
  
end architecture arch_dist_ram;

