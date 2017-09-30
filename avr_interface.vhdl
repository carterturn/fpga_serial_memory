library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity avr_interface is
  port(clk, rst, cclk : in std_logic;
       spi_ss, spi_mosi, spi_sck : in std_logic; spi_miso : out std_logic;
       spi_channel : out std_logic_vector(3 downto 0);
       tx : out std_logic; rx : in std_logic;
       channel : in std_logic_vector(3 downto 0); new_sample : out std_logic;
       sample : out std_logic_vector(9 downto 0); sample_channel : out std_logic_vector(3 downto 0);
       tx_data : in std_logic_vector(7 downto 0); new_tx_data, tx_block : in std_logic; tx_busy : out std_logic;
       rx_data : out std_logic_vector(7 downto 0); new_rx_data : out std_logic);
end avr_interface;

architecture avr_interface_basic of avr_interface is
  component cclk_detector
    port(clk, rst, cclk : in std_logic; ready : out std_logic);
  end component;
  component spi_slave
    port(clk, rst, ss, mosi, sck : in std_logic; miso, done : out std_logic;
	 din : in std_logic_vector (7 downto 0); dout : out std_logic_vector(7 downto 0));
  end component;
  component serial_rx
    generic(CLK_PER_BIT : integer := 100; CTR_SIZE : integer := 7);
    port(clk, rst, rx : in std_logic; new_data : out std_logic; data : out std_logic_vector(7 downto 0));
  end component;
  component serial_tx
    generic(CLK_PER_BIT : integer := 100; CTR_SIZE : integer := 7);
    port(clk, rst, tx_block, new_data : in std_logic; tx, busy : out std_logic;
	 data : in std_logic_vector(7 downto 0));
  end component;
  signal ready, n_rdy, spi_done : std_logic;
  signal spi_dout : std_logic_vector(7 downto 0);
  signal tx_m, spi_miso_m : std_logic;
  signal byte_ct_d, byte_ct_q, new_sample_d, new_sample_q : std_logic;
  signal sample_d, sample_q : std_logic_vector(9 downto 0);
  signal sample_channel_d, sample_channel_q : std_logic_vector(3 downto 0);
begin

  n_rdy <= not ready;

  new_sample <= new_sample_q;
  sample <= sample_q;
  sample_channel <= sample_channel_q;
  
  spi_channel <= channel when(ready = '1') else "ZZZZ";
  tx <= tx_m when(ready = '1') else 'Z';
  spi_miso <= spi_miso_m when((ready = '1') and not (spi_ss = '1')) else 'Z';
  
  process (sample_q, sample_channel_q, byte_ct_q, spi_ss, spi_done, spi_dout) is
  begin
    byte_ct_d <= byte_ct_q;
    sample_d <= sample_q;
    new_sample_d <= '0';
    sample_channel_d <= sample_channel_q;

    if spi_ss = '1' then
      byte_ct_d <= '0';
    end if;

    if spi_done = '1' then
      if byte_ct_q = '0' then
	sample_d(7 downto 0) <= spi_dout;
	byte_ct_d <= '1';
      else
	sample_d(9 downto 8) <= spi_dout(1 downto 0);
	sample_channel_d <= spi_dout(7 downto 4);
	byte_ct_d <= '1';
	new_sample_d <= '1';
      end if;
    end if;
  end process;

  process is
  begin
    wait until clk = '1';
    if n_rdy = '1' then
      byte_ct_q <= '0';
      sample_q <= "0000000000";
      new_sample_q <= '0';
    else
      byte_ct_q <= byte_ct_d;
      sample_q <= sample_d;
       new_sample_q <= new_sample_d;
    end if;
    sample_channel_q <= sample_channel_d;
  end process;

  cclk_detector0: cclk_detector port map (clk, rst, cclk, ready);
  spi_slave0: spi_slave port map(clk, rst, spi_ss, spi_mosi, spi_sck, spi_miso_m, spi_done, "11111111", spi_dout);
  serial_rx0: serial_rx port map(clk, n_rdy, rx, new_rx_data, rx_data);
  serial_tx0: serial_tx port map(clk, n_rdy, tx_block, new_tx_data, tx_m, tx_busy, tx_data);
end architecture avr_interface_basic;
       
