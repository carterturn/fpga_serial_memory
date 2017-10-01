library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity test_bench is
end test_bench;

architecture main_test of test_bench is
  component serial_memory
      port(clk, rst_n, cclk : in std_logic;
       spi_ss, spi_mosi, spi_sck : in std_logic; spi_miso : out std_logic;
       spi_channel : out std_logic_vector(3 downto 0);
       avr_tx, avr_rx_busy : in std_logic; avr_rx : out std_logic;
       led : out std_logic_vector(7 downto 0);
       cube_ground : out std_logic_vector(3 downto 0); blue, red, green : out std_logic_vector(15 downto 0));
  end component;

  constant clk_period : time := 20 ns;

  signal clk, cclk, rst_n : std_logic := '0';
  signal usb_tx : std_logic := '1';
  signal data : std_logic_vector(319 downto 0) :=
    "00001000" & "00000000" &
    "00001000" & "00000001" &
    "00001000" & "00000010" &
    "00001000" & "00000011" &
    "00001000" & "00000100" &
    "00001000" & "00000101" &
    "00001000" & "00000110" &
    "00001000" & "00000111" &
    "00000001" & "00001101" & "00000000" &
    "00000010" & "00001101" & "00000001" &
    "00000011" & "00001101" & "00000010" &
    "00000100" & "00001101" & "00000011" &
    "00000101" & "00001101" & "00000100" &
    "00000110" & "00001101" & "00000101" &
    "00000111" & "00001101" & "00000110" &
    "00001000" & "00001101" & "00000111";
begin
  serial_memory0 : serial_memory port map(clk => clk, rst_n => rst_n, cclk => cclk, avr_tx => usb_tx,
					  avr_rx_busy => '0',
					  spi_ss => 'Z', spi_mosi => 'Z', spi_sck => 'Z');

  rst_n <= '1' after 20ns;
  cclk <= '1' after 20ns;
  
  clk_process : process
  begin
    clk <= '0';
    wait for clk_period / 2;
    clk <= '1';
    wait for clk_period / 2;
  end process;

  data_process : process
  begin
    wait for 20us;
    usb_tx <= '0';

    -- Lowest bit first
    for I in 0 to 7 loop
      wait for 2us;
      usb_tx <= data(0);
      data <= '0' & data(319 downto 1);
    end loop;
    
    -- End transmission
    wait for 2us;
    usb_tx <= '1';
  end process;

end architecture;
