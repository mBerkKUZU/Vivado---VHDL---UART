----------------------------------------------------------------------------
-- UART_TB
-----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
entity tb_uart is
end tb_uart;
architecture Behavioral of tb_uart is
    signal clk          : std_logic := '0';
    signal rst          : std_logic := '0';
    signal rx_serial    : std_logic := '1';
    signal tx_serial    : std_logic;
    constant clk_period : time := 10 ns;
    component top
        port (
            clk       : in std_logic;
            rst       : in std_logic;
            rx_serial : in std_logic;
            tx_serial : out std_logic
        );
    end component;

    constant uartPeriod : time := 8.68 us;

begin
    dut : top
    port map(
        clk       => clk,
        rst       => rst,
        rx_serial => rx_serial,
        tx_serial => tx_serial
    );
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;
        end loop;
    end process;

    stimulus_process : process
        procedure send_uart_message(message : in std_logic_vector) is
        begin
            rx_serial <= '0'; -- start
            wait for uartPeriod;
            for i in 7 downto 0 loop
                rx_serial <= message(i);
                wait for uartPeriod;
            end loop;
            rx_serial <= '1'; -- Stop
            wait for uartPeriod;
        end procedure;
    begin
        -- Reset the system
        rst <= '1';
        wait for clk_period * 10;
        rst <= '0';
        wait for clk_period * 1000;

        send_uart_message(x"BA");
        send_uart_message(x"CD");
        --num1
        send_uart_message(x"00");
        send_uart_message(x"01");
        --num1
        send_uart_message(x"00");
        send_uart_message(x"02");
        --num1
        send_uart_message(x"01");
        --checksum
        send_uart_message(x"8b");

        wait;
    end process;
end Behavioral;
