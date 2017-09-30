library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity serial_tx is
  generic(CLK_PER_BIT : integer := 50; CTR_SIZE : integer := 6);
  port(clk, rst, tx_block, new_data : in std_logic; tx, busy : out std_logic;
       data : in std_logic_vector(7 downto 0));
end serial_tx;

architecture serial_tx_basic of serial_tx is
  constant STATE_SIZE : integer := 2;
  constant IDLE : std_logic_vector := "00";
  constant START_BIT : std_logic_vector := "01";
  constant DATA_STATE : std_logic_vector := "10";
  constant STOP_BIT : std_logic_vector := "11";
  signal ctr_d, ctr_q : std_logic_vector(CTR_SIZE-1 downto 0);
  signal bit_ctr_d, bit_ctr_q : std_logic_vector(2 downto 0);
  signal data_d, data_q : std_logic_vector(7 downto 0);
  signal tx_d, tx_q, busy_d, busy_q, tx_block_d, tx_block_q : std_logic;
  signal state_d : std_logic_vector(STATE_SIZE-1 downto 0);
  signal state_q : std_logic_vector(STATE_SIZE-1 downto 0) := IDLE;
begin
  tx <= tx_q;
  busy <= busy_q;

  process (tx_block, ctr_q, bit_ctr_q, data_q, state_q, busy_q, tx_block_q, data, new_data) is
  begin
    tx_block_d <= tx_block;
    ctr_d <= ctr_q;
    bit_ctr_d <= bit_ctr_q;
    data_d <= data_q;
    state_d <= state_q;
    busy_d <= busy_q;

    case state_q is
      when IDLE =>
	if tx_block_q = '1' then
	  busy_d <= '1';
	  tx_d <= '1';
	else
	  busy_d <= '0';
	  tx_d <= '1';
	  bit_ctr_d <= "000";
	  ctr_d <= "0000000";
	  if new_data = '1' then
	    data_d <= data;
	    state_d <= START_BIT;
	    busy_d <= '1';
	  end if;
	end if;
      when START_BIT =>
	busy_d <= '1';
	ctr_d <= std_logic_vector(unsigned(ctr_q) + 1);
	tx_d <= '0';
	if unsigned(ctr_q) = (CLK_PER_BIT-1) then
	  ctr_d <= "0000000";
	  state_d <= DATA_STATE;
	end if;
      when DATA_STATE =>
	busy_d <= '1';
	tx_d <= data_q(to_integer(unsigned(bit_ctr_q)));
	ctr_d <= std_logic_vector(unsigned(ctr_q) + 1);
	if unsigned(ctr_q) = (CLK_PER_BIT - 1) then
	  ctr_d <= "0000000";
	  bit_ctr_d <= std_logic_vector(unsigned(bit_ctr_q) + 1);
	  if bit_ctr_q = "111" then
	    state_d <= STOP_BIT;
	  end if;
	end if;
      when STOP_BIT =>
	busy_d <= '1';
	tx_d <= '1';
	ctr_d <= std_logic_vector(unsigned(ctr_q) + 1);
	if unsigned(ctr_q) = (CLK_PER_BIT - 1) then
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
      state_q <= IDLE;
      tx_q <= '1';
    else
      state_q <= state_d;
      tx_q <= tx_d;
    end if;

    tx_block_q <= tx_block_d;
    data_q <= data_d;
    bit_ctr_q <= bit_ctr_d;
    ctr_q <= ctr_d;
    busy_q <= busy_d;
  end process;
end architecture serial_tx_basic;

