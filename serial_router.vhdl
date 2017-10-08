library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity serial_router is
  port(new_rx_data : in std_logic; serial_rx_data : in std_logic_vector(7 downto 0);
       ram_idx, ram_data : out std_logic_vector(7 downto 0);
       write_to_ram, new_tx_data : out std_logic);
end serial_router;

architecture serial_router_basic of serial_router is
  constant IDLE : std_logic_vector := "00";
  constant ADDRESS_LOADED : std_logic_vector := "01";
  constant WRITE_NEXT_BYTE : std_logic_vector := "10";
  signal state : std_logic_vector(1 downto 0) := IDLE;
  signal key_enter, key_backspace: std_logic;
begin
  process (serial_rx_data) is
  begin
    if serial_rx_data = "00001101" then
      key_enter <= '1';
    else
      key_enter <= '0';
    end if;
  end process;
  
  process (serial_rx_data) is
  begin
    if serial_rx_data = "00001000" then
      key_backspace <= '1';
    else
      key_backspace <= '0';
    end if;
  end process;

  process (new_rx_data) is
  begin    
    if falling_edge(new_rx_data) then
      case state is
	when IDLE =>
	  ram_idx <= serial_rx_data;
	  new_tx_data <= '0';
	  write_to_ram <= '0';
	  state <= ADDRESS_LOADED;
	when ADDRESS_LOADED =>
	  if key_enter = '1' then
	    state <= WRITE_NEXT_BYTE;
	  elsif key_backspace = '1' then
	    new_tx_data <= '1';
	    state <= IDLE;
	  end if;
	when WRITE_NEXT_BYTE =>
	  ram_data <= serial_rx_data;
	  write_to_ram <= '1';
	  state <= IDLE;
	when others =>
	  state <= IDLE;
      end case;
    end if;
  end process;
end architecture serial_router_basic;

