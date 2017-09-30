library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity serial_memory is
  port(clk, rst_n, cclk : in std_logic;
       spi_ss, spi_mosi, spi_sck : in std_logic; spi_miso : out std_logic;
       spi_channel : out std_logic_vector(3 downto 0);
       avr_tx, avr_rx_busy : in std_logic; avr_rx : out std_logic;
       led : out std_logic_vector(7 downto 0);
       cube_ground : out std_logic_vector(3 downto 0); blue, red, green : out std_logic_vector(15 downto 0));  
end serial_memory;

architecture arch_sm of serial_memory is
  component avr_interface
    port(clk, rst, cclk : in std_logic;
	 spi_ss, spi_mosi, spi_sck : in std_logic; spi_miso : out std_logic;
	 spi_channel : out std_logic_vector(3 downto 0);
	 tx : out std_logic; rx : in std_logic;
	 channel : in std_logic_vector(3 downto 0); -- new_sample : out std_logic;
	 -- sample : out std_logic_vector (9 downto 0); sample_channel : out std_logic_vector (3 downto 0);
	 tx_data : in std_logic_vector(7 downto 0); new_tx_data, tx_block : in std_logic; tx_busy : out std_logic;
	 rx_data : out std_logic_vector(7 downto 0); new_rx_data : out std_logic);
  end component;
  component single_port_ram
    port(we : in std_logic; address : in std_logic_vector(7 downto 0);
	 data_in : in std_logic_vector(7 downto 0); data_out : out std_logic_vector(7 downto 0));
  end component;
  signal rst : std_logic;
  signal rx_data, tx_data : std_logic_vector(7 downto 0);
  signal tx_busy, new_rx_data, new_tx_data_d, new_tx_data_q : std_logic;

  signal ram_idx : std_logic_vector(7 downto 0);
  signal ram_write : std_logic_vector(7 downto 0);
  signal key_enter, key_backspace, write_rx_data_d, write_rx_data_q: std_logic;
  signal address_loaded, write_next_byte, write_this_byte, read_this_byte : boolean;
begin
  rst <= not rst_n;
  
  spi_miso <= 'Z';
  spi_channel <= "ZZZZ";
  avr_rx <= 'Z';
  cube_ground <= "0000";
  blue(15 downto 8) <= tx_data;
  blue(7 downto 0) <= ram_idx;
  red <= "0000000000000000";
  green <= "0000000000000000";

  led(3 downto 0) <= ram_idx (3 downto 0);

  process (rx_data) is
  begin
    if rx_data = "00001101" then
      key_enter <= '1';
    else
      key_enter <= '0';
    end if;
  end process;
  
  process (rx_data) is
  begin
    if rx_data = "00001000" then
      key_backspace <= '1';
    else
      key_backspace <= '0';
    end if;
  end process;

  led(5 downto 4) <= "00";
  led(6) <= key_backspace;
  led(7) <= key_enter;

  process (new_tx_data_q, address_loaded, read_this_byte) is
    variable done : boolean := false;
  begin
    new_tx_data_d <= '0';
    
    if new_tx_data_q = '1' then
      done := true;
    end if;
    
    if read_this_byte and not done then
      new_tx_data_d <= '1';
    end if;
    
    if address_loaded then
      done := false;
    end if;
  end process;

  process (write_rx_data_q, address_loaded, write_this_byte) is
    variable done : boolean := false;
  begin
    write_rx_data_d <= '0';

    if write_rx_data_q = '1' then
      done := true;
    end if;
    
    if write_this_byte and not done then
      write_rx_data_d <= '1';
    end if;
    
    if address_loaded then
      done := false;
    end if;
  end process;

  process (new_rx_data) is
  begin    
    if falling_edge(new_rx_data) then
      if not address_loaded then
	ram_idx <= rx_data;
	read_this_byte <= false;
	write_this_byte <= false;
	address_loaded <= true;
      else
	if not write_next_byte then
	  if key_enter = '1' then
	    write_next_byte <= true;
	  elsif key_backspace = '1' then
	    read_this_byte <= true;
	    address_loaded <= false;
	  end if;
	else
	  write_next_byte <= false;
	  ram_write <= rx_data;
	  address_loaded <= false;
	  write_this_byte <= true;
	end if;
      end if;
    end if;
  end process;

  process is
  begin
    wait until clk = '1';
    write_rx_data_q <= write_rx_data_d;
    new_tx_data_q <= new_tx_data_d;
  end process;

  avr_interface0: avr_interface port map(clk, rst, cclk, spi_ss, spi_mosi, spi_sck, spi_miso, spi_channel,
					 avr_rx, avr_tx, "1111", tx_data, new_tx_data_q,
					 avr_rx_busy, tx_busy, rx_data, new_rx_data);
  single_port_ram0 : single_port_ram port map(write_rx_data_q, ram_idx, ram_write, tx_data);
end architecture arch_sm;
