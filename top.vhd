-----------------------------------------------------------------------------
-- UART_TOP
-- Berk Muammer Kuzu
-----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity top is
    port (
        clk       : in std_logic;
        rst       : in std_logic;
        rx_serial : in std_logic;
        tx_serial : out std_logic
    );
end top;
architecture Behavioral of top is

    signal rx_data        : std_logic_vector(7 downto 0);
    signal rx_done        : std_logic;
    signal tx_data        : std_logic_vector(7 downto 0);
    signal tx_start       : std_logic;
    signal tx_done_int    : std_logic;
    constant HEADER       : std_logic_vector(15 downto 0) := x"BACD";
    constant RESPONSE_HDR : std_logic_vector(15 downto 0) := x"ABCD";
    signal num1           : signed(15 downto 0);
    signal num2           : signed(15 downto 0);
    signal opcode         : std_logic_vector(7 downto 0);
    signal checksum       : std_logic_vector(7 downto 0);
    signal result         : signed(15 downto 0);
    signal checksum_calc  : unsigned(7 downto 0);
    signal msb_flag       : std_logic;
    type t_state is (GET_HEADER, GET_NUM_1, GET_NUM_2, GET_OPCODE, GET_CHECKSUM, CHECK_CHECKSUM, CALC_DATA, SEND_RESPONSE, WAIT_TRANSMIT);
    signal state : t_state := GET_HEADER;
    type arr_type is array (0 to 4) of std_logic_vector(7 downto 0);
    signal tx_packet : arr_type;
    signal cnt : integer range 0 to 7;

begin
    tx_packet(0) <= RESPONSE_HDR(15 downto 8);
    tx_packet(1) <= RESPONSE_HDR(7 downto 0);
    tx_packet(2) <= std_logic_vector(result(15 downto 8));
    tx_packet(3) <= std_logic_vector(result(7 downto 0));
    tx_packet(4) <= std_logic_vector(unsigned(RESPONSE_HDR(15 downto 8)) + unsigned(RESPONSE_HDR(7 downto 0)) + unsigned(result(15 downto 8)) + unsigned(result(7 downto 0)));



    uart_rx_inst : entity work.uart_rx
        port map(
            clk       => clk,
            rst       => rst,
            rx_serial => rx_serial,
            rx_data   => rx_data,
            rx_done   => rx_done
        );

    uart_tx_inst : entity work.uart_tx
        port map(
            clk       => clk,
            rst       => rst,
            tx_start  => tx_start,
            tx_data   => tx_data,
            tx_serial => tx_serial,
            tx_done   => tx_done_int
        );

    process (clk)
    begin
        if (rst = '1') then
            state         <= GET_HEADER;
            msb_flag      <= '0';
            tx_start      <= '0';
            checksum_calc <= (others => '0');
            cnt          <= 0;
        elsif rising_edge(clk) then
            case state is
                when GET_HEADER =>
                    if rx_done = '1' then
                        if msb_flag = '0' then
                            if rx_data = HEADER(15 downto 8) then
                                msb_flag      <= '1';
                                checksum_calc <= checksum_calc + unsigned(rx_data);
                            else
                                state         <= GET_HEADER;
                                msb_flag      <= '0';
                                checksum_calc <= (others => '0');

                            end if;
                        else
                            if rx_data = HEADER(7 downto 0) then
                                msb_flag      <= '0';
                                state         <= GET_NUM_1;
                                checksum_calc <= checksum_calc + unsigned(rx_data);
                            else
                                msb_flag      <= '0';
                                state         <= GET_HEADER;
                                checksum_calc <= (others => '0');
                            end if;
                        end if;
                    end if;

                when GET_NUM_1 =>

                    if rx_done = '1' then
                        checksum_calc <= checksum_calc + unsigned(rx_data);
                        if msb_flag = '0' then
                            num1(15 downto 8) <= signed(rx_data);
                            msb_flag          <= '1';
                        else
                            num1(7 downto 0) <= signed(rx_data);
                            msb_flag         <= '0';
                            state            <= GET_NUM_2;
                        end if;
                    end if;

                when GET_NUM_2 =>

                    if rx_done = '1' then
                        checksum_calc <= checksum_calc + unsigned(rx_data);
                        if msb_flag = '0' then
                            num2(15 downto 8) <= signed(rx_data);
                            msb_flag          <= '1';
                        else
                            num2(7 downto 0) <= signed(rx_data);
                            msb_flag         <= '0';
                            state            <= GET_OPCODE;
                        end if;
                    end if;

                when GET_OPCODE =>
                    if rx_done = '1' then
                        checksum_calc <= checksum_calc + unsigned(rx_data);
                        opcode <= rx_data;
                        state  <= GET_CHECKSUM;
                    end if;
                when GET_CHECKSUM =>
                    if rx_done = '1' then
                        checksum <= rx_data;
                        state    <= CHECK_CHECKSUM;
                    end if;

                when CHECK_CHECKSUM =>
                    if checksum_calc = unsigned(checksum) then
                        state <= CALC_DATA;
                    else
                        state <= GET_HEADER;
                    end if;

                when CALC_DATA =>
                    if opcode = x"01" then
                        result <= num1 + num2;
                        state    <= SEND_RESPONSE;

                    elsif opcode = x"02" then
                        result <= num1 + num2;
                        state    <= SEND_RESPONSE;

                    else
                        state <= GET_HEADER;
                    end if;
                
                when SEND_RESPONSE =>
                    tx_start <= '1';
                    tx_data  <= tx_packet(cnt);
                    cnt      <= cnt + 1;
                    state    <= WAIT_TRANSMIT;


                when WAIT_TRANSMIT =>
                    tx_start <= '0';

                    if tx_done_int = '1' then
                        if cnt = 5 then
                            state <= GET_HEADER;
                        else
                            state <= SEND_RESPONSE;
                        end if;
                    end if;
                when others => state <= GET_HEADER;
            end case;
        end if;
    end process;
end Behavioral;
