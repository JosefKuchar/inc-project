-- uart_fsm.vhd: UART controller - finite state machine
-- Author(s): Josef Kuchař - xkucha28
--
library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------
entity UART_FSM is
   port (
      CLK : in std_logic;
      RST : in std_logic;
      DIN : in std_logic;
      CNT_BITS : in std_logic_vector(3 downto 0);
      CNT_CLK : in std_logic_vector(3 downto 0);
      RST_CNT : out std_logic;
      WAITING : out std_logic;
      READING : out std_logic;
      DOUT_VLD : out std_logic
   );
end entity UART_FSM;

-------------------------------------------------
architecture behavioral of UART_FSM is
   type states is (AWAIT, START, RECIEVE, STOP, VALID);
   signal current_state : states := AWAIT;
   signal next_state : states := AWAIT;
begin
   -- State switching logic
   p_state_switch : process (CLK, RST)
   begin
      if RST = '1' then
         current_state <= AWAIT;
      elsif rising_edge(CLK) then
         current_state <= next_state;
      end if;
   end process;

   -- Get next state
   p_state_decision : process (current_state, DIN, CNT_CLK, CNT_BITS)
   begin
      case current_state is
         when AWAIT =>
            -- We found the start of start bit
            if DIN = '0' then
               next_state <= START;
            end if;
         when START =>
            -- We are in middle of start bit
            if CNT_CLK = "0111" then
               -- Start bit is invalid
               if DIN = '1' then
                  next_state <= AWAIT;
                  -- Start bit is valid
               else
                  next_state <= RECIEVE;
               end if;
            end if;
         when RECIEVE =>
            -- We read all bits
            if CNT_BITS = "1000" then
               next_state <= STOP;
            end if;
         when STOP =>
            -- We are at the middle of stop bit
            if CNT_CLK = "1111" then
               -- Stop bit is valid
               if DIN = '1' then
                  next_state <= VALID;
                  -- Stop bit is invalid
               else
                  next_state <= AWAIT;
               end if;
            end if;
         when VALID =>
            -- This is just for one clock
            next_state <= AWAIT;
         when others => null;
      end case;
   end process;

   -- Output
   p_output : process (current_state)
   begin
      case current_state is
         when AWAIT =>
            RST_CNT <= '1';
            WAITING <= '0';
            READING <= '0';
            DOUT_VLD <= '0';
         when START =>
            RST_CNT <= '0';
            WAITING <= '1';
            READING <= '0';
            DOUT_VLD <= '0';
         when RECIEVE =>
            RST_CNT <= '0';
            WAITING <= '0';
            READING <= '1';
            DOUT_VLD <= '0';
         when STOP =>
            RST_CNT <= '0';
            WAITING <= '0';
            READING <= '0';
            DOUT_VLD <= '0';
         when VALID =>
            RST_CNT <= '0';
            WAITING <= '0';
            READING <= '0';
            DOUT_VLD <= '1';
      end case;
   end process;
end behavioral;
