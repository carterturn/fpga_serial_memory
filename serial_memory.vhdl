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
	 channel : in std_logic_vector(3 downto 0); new_sample : out std_logic;
	 sample : out std_logic_vector (9 downto 0); sample_channel : out std_logic_vector (3 downto 0);
	 tx_data : in std_logic_vector(7 downto 0); new_tx_data, tx_block : in std_logic; tx_busy : out std_logic;
	 rx_data : out std_logic_vector(7 downto 0); new_rx_data : out std_logic);
  end component;
  component single_port_ram
    port(we : in std_logic; address : in std_logic_vector(7 downto 0);
	 data_in : in std_logic_vector(7 downto 0); data_out : out std_logic_vector(7 downto 0));
  end component;
  component serial_router
  port(new_rx_data : in std_logic; serial_rx_data : in std_logic_vector(7 downto 0);
       ram_idx, ram_data : out std_logic_vector(7 downto 0);
       write_to_ram, new_tx_data : out std_logic);
  end component;
  component pulse
    port(clk, trigger : in std_logic; output : out std_logic);
  end component;
  
  signal rst : std_logic;
  signal rx_data, tx_data : std_logic_vector(7 downto 0);
  signal tx_busy, new_rx_data : std_logic;

  signal ram_idx, ram_data : std_logic_vector(7 downto 0);
  signal new_tx_data, new_tx_data_p : std_logic;
  signal write_to_ram, write_to_ram_p : std_logic;
begin
  rst <= not rst_n;
  
  spi_miso <= 'Z';
  spi_channel <= "ZZZZ";
  avr_rx <= 'Z';
  cube_ground <= "0000";
  red <= "0000000000000000";
  green <= "0000000000000000";
  led <= "00000000";

  blue(15 downto 8) <= tx_data;
  blue(7 downto 0) <= ram_idx;

  avr_interface0: avr_interface port map(clk => clk, rst => rst, cclk => cclk,
					 spi_ss => spi_ss, spi_mosi => spi_mosi, spi_sck => spi_sck,
					 spi_miso => spi_miso, spi_channel => spi_channel, sample => open,
					 sample_channel => open, new_sample => open, channel => "1111",
					 rx => avr_tx, tx => avr_rx,
					 tx_data => tx_data, new_tx_data => new_tx_data_p, tx_block => avr_rx_busy,
					 tx_busy => tx_busy, rx_data => rx_data, new_rx_data => new_rx_data);
  single_port_ram0 : single_port_ram port map(we => write_to_ram_p, address => ram_idx,
					      data_in => ram_data, data_out => tx_data);
  ram_write_pulse : pulse port map(clk => clk, trigger => write_to_ram, output => write_to_ram_p);
  new_tx_pulse : pulse port map(clk => clk, trigger => new_tx_data, output => new_tx_data_p);
  serial_router0 : serial_router port map(new_rx_data => new_rx_data, serial_rx_data => rx_data,
					  ram_idx => ram_idx, ram_data => ram_data,
					  write_to_ram => write_to_ram, new_tx_data => new_tx_data);
end architecture arch_sm;
