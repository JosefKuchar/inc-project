-- uart.vhd: UART controller - receiving part
-- Author(s): Josef Kuchař xkucha28
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-------------------------------------------------
entity UART_RX is
	port (
		CLK : in std_logic;
		RST : in std_logic;
		DIN : in std_logic;
		DOUT : out std_logic_vector(7 downto 0);
		DOUT_VLD : out std_logic
	);
end UART_RX;

-------------------------------------------------
architecture behavioral of UART_RX is
	signal cnt_bits : std_logic_vector(3 downto 0) := "0000";
	signal cnt_clk : std_logic_vector(3 downto 0) := "0000";
	signal rst_cnt_fsm : std_logic;
	signal rst_cnt : std_logic;
	signal mid_bit : std_logic;
	signal waiting : std_logic;
	signal reading : std_logic;
begin
	-- Finite state machine port mapping
	fsm : entity work.UART_FSM(behavioral)
		port map(
			CLK => CLK,
			RST => RST,
			DIN => DIN,
			DOUT_VLD => DOUT_VLD,
			CNT_BITS => cnt_bits,
			CNT_CLK => cnt_clk,
			RST_CNT => rst_cnt_fsm,
			WAITING => waiting,
			READING => reading
		);

	-- Clock counter
	p_clk_cnt : process (CLK)
	begin
		if rising_edge(CLK) then
			if rst_cnt = '1' then
				cnt_clk <= "0000";
			else
				cnt_clk <= cnt_clk + 1;
			end if;
		end if;
	end process;

	-- Bit counter
	p_clk_bits : process (CLK)
	begin
		if rising_edge(CLK) then
			if rst_cnt = '1' then
				cnt_bits <= "0000";
			else
				if cnt_clk = "1111" then
					cnt_bits <= cnt_bits + 1;
				end if;
			end if;
		end if;
	end process;

	-- Reset comparator
	p_rst_cmp : process (rst_cnt_fsm, waiting, cnt_clk)
	begin
		if rst_cnt_fsm = '1' or (waiting = '1' and cnt_clk = "1000") then
			rst_cnt <= '1';
		else
			rst_cnt <= '0';
		end if;
	end process;

	-- Mid bit comparator
	p_mid_cmp : process (cnt_clk)
	begin
		if cnt_clk = "1111" then
			mid_bit <= '1';
		else
			mid_bit <= '0';
		end if;
	end process;

	-- Shift ouput register
	p_shift_register : process (CLK)
		variable dout_tmp : std_logic_vector(7 downto 0);
	begin
		if rising_edge(CLK) then
			if reading = '1' and mid_bit = '1' then
				dout_tmp := DIN & dout_tmp(7 downto 1);
				DOUT <= dout_tmp;
			end if;
		end if;
	end process;

end behavioral;
