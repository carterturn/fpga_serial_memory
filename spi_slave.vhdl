library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity spi_slave is
  port(clk, rst, ss, mosi, sck : in std_logic; miso, done : out std_logic;
       din : in std_logic_vector(7 downto 0); dout : out std_logic_vector(7 downto 0));
end spi_slave;

architecture spi_slave_basic of spi_slave is
  signal mosi_d, mosi_q, ss_d, ss_q, sck_d, sck_q, sck_old_d, sck_old_q,
    done_d, done_q, miso_d, miso_q : std_logic;
  signal data_d, data_q, dout_d, dout_q : std_logic_vector(7 downto 0);
  signal bit_ct_d, bit_ct_q : std_logic_vector(2 downto 0);
begin
  miso <= miso_q;
  done <= done_q;
  dout <= dout_q;

  process (ss, mosi, sck, sck_q, ss_q, din, data_q, dout_q, bit_ct_q, miso_q, sck_old_q, mosi_q) is
  begin
    ss_d <= ss;
    mosi_d <= mosi;
    sck_d <= sck;
    sck_old_d <= sck_q;

    if ss_q = '1' then
      bit_ct_d <= "000";
      data_d <= din;
      miso_d <= data_q(7);
      done_d <= '0';
      dout_d <= dout_q;
    else
      bit_ct_d <= bit_ct_q;
      miso_d <= miso_q;
      if not (sck_old_q = '1') and sck_q = '1' then
	data_d <= data_q(6 downto 0) & mosi_q;
	bit_ct_d <= std_logic_vector(unsigned(bit_ct_q) + 1);
	if bit_ct_q = "111" then
	  dout_d <= data_q(6 downto 0) & mosi_q;
	  done_d <= '1';
	  data_d <= din;
	end if;
      elsif sck_old_q = '1' and not (sck_q = '1') then
	miso_d <= data_q(7);
	data_d <= data_q;
	done_d <= '0';
	dout_d <= dout_q;
      else
	data_d <= data_q;
	done_d <= '0';
	dout_d <= dout_q;
      end if;
    end if;
  end process;

  process is
  begin
    wait until clk = '1';
    if rst = '1' then
      done_q <= '0';
      bit_ct_q <= "000";
      dout_q <= "00000000";
      miso_q <= '1';
    else
      done_q <= done_d;
      bit_ct_q <= bit_ct_d;
      dout_q <= dout_d;
      miso_q <= miso_d;
    end if;

    sck_q <= sck_d;
    mosi_q <= mosi_d;
    ss_q <= ss_d;
    data_q <= data_d;
    sck_old_q <= sck_old_d;
  end process;
end architecture spi_slave_basic;
