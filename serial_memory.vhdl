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
  component pulse
    port(clk, trigger : in std_logic; output : out std_logic);
  end component;
  
  signal rst : std_logic;
  signal rx_data, tx_data : std_logic_vector(7 downto 0);
  signal tx_busy, new_rx_data, new_tx_data : std_logic;

  signal ram_idx : std_logic_vector(7 downto 0);
  signal ram_write : std_logic_vector(7 downto 0);
  signal key_enter, key_backspace, write_to_ram: std_logic;

  constant IDLE : std_logic_vector := "00";
  constant ADDRESS_LOADED : std_logic_vector := "01";
  constant WRITE_NEXT_BYTE : std_logic_vector := "10";
  signal state : std_logic_vector(1 downto 0) := IDLE;
  signal write_this_byte, read_this_byte : std_logic;
  signal new_tx_done, write_rx_done : std_logic;
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

  process (new_rx_data) is
  begin    
    if falling_edge(new_rx_data) then
      case state is
	when IDLE =>
	  ram_idx <= rx_data;
	  read_this_byte <= '0';
	  write_this_byte <= '0';
	  state <= ADDRESS_LOADED;
	when ADDRESS_LOADED =>
	  if key_enter = '1' then
	    state <= WRITE_NEXT_BYTE;
	  elsif key_backspace = '1' then
	    read_this_byte <= '1';
	    state <= IDLE;
	  end if;
	when WRITE_NEXT_BYTE =>
	  ram_write <= rx_data;
	  write_this_byte <= '1';
	  state <= IDLE;
	when others =>
	  state <= IDLE;
      end case;
    end if;
  end process;

  avr_interface0: avr_interface port map(clk => clk, rst => rst, cclk => cclk,
					 spi_ss => spi_ss, spi_mosi => spi_mosi, spi_sck => spi_sck,
					 spi_miso => spi_miso, spi_channel => spi_channel, sample => open,
					 sample_channel => open, new_sample => open, channel => "1111",
					 rx => avr_tx, tx => avr_rx,
					 tx_data => tx_data, new_tx_data => new_tx_data, tx_block => avr_rx_busy,
					 tx_busy => tx_busy, rx_data => rx_data, new_rx_data => new_rx_data);
  single_port_ram0 : single_port_ram port map(write_to_ram, ram_idx, ram_write, tx_data);
  ram_write_pulse : pulse port map(clk, write_this_byte, write_to_ram);
  new_tx_pulse : pulse port map(clk, read_this_byte, new_tx_data);
end architecture arch_sm;
