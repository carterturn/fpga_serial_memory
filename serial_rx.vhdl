library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity serial_rx is
  generic(CLK_PER_BIT : integer := 50; CTR_SIZE : integer := 6);
  port(clk, rst, rx : in std_logic; new_data : out std_logic; data : out std_logic_vector(7 downto 0));
end serial_rx;

architecture serial_rx_basic of serial_rx is
  constant STATE_SIZE : integer := 2;
  constant IDLE : std_logic_vector := "00";
  constant WAIT_HALF : std_logic_vector := "01";
  constant WAIT_FULL : std_logic_vector := "10";
  constant WAIT_HIGH : std_logic_vector := "11";
  signal ctr_d, ctr_q : std_logic_vector(CTR_SIZE-1 downto 0);
  signal bit_ctr_d, bit_ctr_q : std_logic_vector(2 downto 0);
  signal data_d, data_q : std_logic_vector(7 downto 0);
  signal new_data_d, new_data_q, rx_d, rx_q : std_logic;
  signal state_d : std_logic_vector(STATE_SIZE-1 downto 0);
  signal state_q : std_logic_vector(STATE_SIZE-1 downto 0) := IDLE;
begin
  new_data <= new_data_q;
  data <= data_q;

  process (rx, state_q, ctr_q, bit_ctr_q, rx_q, data_q) is
  begin
    rx_d <= rx;
    state_d <= state_q;
    ctr_d <= ctr_q;
    bit_ctr_d <= bit_ctr_q;
    data_d <= data_q;
    new_data_d <= '0';

    case state_q is
      when IDLE =>
	bit_ctr_d <= "000";
	ctr_d <= "0000000";
	if rx_q = '0' then
	  state_d <= WAIT_HALF;
	end if;
      when WAIT_HALF =>
	ctr_d <= std_logic_vector(unsigned(ctr_q) + 1);
	if unsigned(ctr_q) = (CLK_PER_BIT / 2) then
	  ctr_d <= "0000000";
	  state_d <= WAIT_FULL;
	end if;
      when WAIT_FULL =>
	ctr_d <= std_logic_vector(unsigned(ctr_q) + 1);
	if unsigned(ctr_q) = (CLK_PER_BIT - 1) then
	  data_d <= rx_q & data_q(7 downto 1);
	  bit_ctr_d <= std_logic_vector(unsigned(bit_ctr_q) + 1);
	  ctr_d <= "0000000";
	  if bit_ctr_q = "111" then
	    state_d <= WAIT_HIGH;
	    new_data_d <= '1';
	  end if;
	end if;
      when WAIT_HIGH =>
	if rx_q = '1' then
	  state_d <= IDLE;
	end if;
      when others =>
	state_d <= IDLE;
    end case;    
  end process;

  process is
  begin
    wait until clk = '1';
    if rst = '1' then
      ctr_q <= "0000000";
      bit_ctr_q <= "000";
      new_data_q <= '0';
      state_q <= IDLE;
    else
      ctr_q <= ctr_d;
      bit_ctr_q <= bit_ctr_d;
      new_data_q <= new_data_d;
      state_q <= state_d;
    end if;

    rx_q <= rx_d;
    data_q <= data_d;
  end process;
end architecture serial_rx_basic;
