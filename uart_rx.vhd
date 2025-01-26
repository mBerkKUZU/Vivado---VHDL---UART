-----------------------------------------------------------------------------
-- UART RX
-- Berk Muammer Kuzu
-----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
entity uart_rx is
    port (
        clk       : in std_logic;
        rst       : in std_logic;
        rx_serial : in std_logic;
        rx_data   : out std_logic_vector(7 downto 0); -- 8 bit
        rx_done   : out std_logic
    );
end uart_rx;
architecture Behavioral of uart_rx is
    constant clk_freq        : integer := 100_000_000;
    constant baud_rate       : integer := 115_200;
    constant bit_period      : integer := clk_freq / baud_rate;
    constant half_bit_period : integer := bit_period / 2;
    type rx_state_type is (IDLE, START, DATA, STOP);
    signal state     : rx_state_type                 := IDLE;
    signal bit_timer : integer                       := 0;
    signal bit_count : integer                       := 0;
    signal shift_reg : std_logic_vector(7 downto 0) := (others => '0');
begin
    process (clk, rst)
    begin
        if rst = '1' then
            state     <= IDLE;
            bit_timer <= 0;
            bit_count <= 0;
            shift_reg <= (others => '0');
            rx_done   <= '0';
            rx_data <=  (others => '0');

        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if rx_serial = '0' then
                        state     <= START;
                        bit_timer <= 0;
                    end if;
                    rx_done <= '0';
                    shift_reg <= (others => '0');

                when START =>
                    if bit_timer = half_bit_period then
                        if rx_serial = '0' then
                            state     <= DATA;
                            bit_timer <= 0;
                            bit_count <= 0;
                        else
                            state <= IDLE;
                        end if;
                    else
                        bit_timer <= bit_timer + 1;
                    end if;
                when DATA =>
                    if bit_timer = bit_period then
                        bit_timer            <= 0;
                        shift_reg(7)         <= rx_serial;
                        shift_reg(6 downto 0) <=  shift_reg(7 downto 1);
                        if bit_count = 7 then
                            state <= STOP;
                            bit_count <= 0;
                        else
                            bit_count            <= bit_count + 1;
                        end if;
                    else
                        bit_timer <= bit_timer + 1;
                    end if;

                when STOP =>
                    if bit_timer = bit_period then
                        bit_timer            <= 0;

                        if rx_serial = '1' then
                            rx_data <= shift_reg;
                            rx_done <= '1';
                        end if;
                        state   <= IDLE;
                    else
                        bit_timer <= bit_timer + 1;
                    end if;
            end case;
        end if;
    end process;
end Behavioral;
