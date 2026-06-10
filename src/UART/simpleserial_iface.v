`default_nettype none

module simpleserial_iface #(
    parameter CLK_FREQ = 7_372_800,
    parameter BAUD     =    38_400
) (
    input  wire clk,
    input  wire rst_n,
    input  wire rx,
    output wire tx,
    // RX
    output wire        rx_valid,
    output wire  [7:0] rx_cmd,
    output wire  [7:0] rx_data,
    // TX
    input  wire        tx_valid,
    input  wire  [7:0] tx_cmd,
    input  wire  [7:0] tx_data,
    output wire        tx_busy
);

// uart_rx -> ss_rx
wire        ss_rx_valid;
wire  [7:0] ss_rx_data;

// ss_tx -> uart_tx
wire        ss_tx_valid;
wire  [7:0] ss_tx_data;
wire        uart_tx_busy;
uart_rx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD    (BAUD)
) u_uart_rx (
    .clk  (clk),
    .rst_n(rst_n),
    .rx   (rx),
    .valid(ss_rx_valid),
    .data (ss_rx_data)
);

ss_rx u_ss_rx (
    .clk      (clk),
    .rst_n    (rst_n),
    .in_valid (ss_rx_valid),
    .in_data  (ss_rx_data),
    .out_valid(rx_valid),
    .out_cmd  (rx_cmd),
    .out_data (rx_data)
);

uart_tx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD    (BAUD)
) u_uart_tx (
    .clk  (clk),
    .rst_n(rst_n),
    .valid(ss_tx_valid),
    .data (ss_tx_data),
    .tx   (tx),
    .busy (uart_tx_busy)
);

ss_tx u_ss_tx (
    .clk      (clk),
    .rst_n    (rst_n),
    .in_valid (tx_valid),
    .in_cmd   (tx_cmd),
    .in_data  (tx_data),
    .in_busy  (uart_tx_busy),
    .out_valid(ss_tx_valid),
    .out_data (ss_tx_data),
    .out_busy (tx_busy)
);

endmodule
