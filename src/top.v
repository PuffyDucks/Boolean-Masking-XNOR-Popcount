`default_nettype none

// Receive 'n' command, NOT the data byte, respond with 'o'
module top (
    input  wire iCE40CW312_CLK,
    input  wire iCE40CW312_RX,
    output wire iCE40CW312_TX
);

localparam CHAR_n = 8'h6E;
localparam CHAR_o = 8'h6F;

wire        rx_valid;
wire [7:0]  rx_cmd;
wire [7:0]  rx_data;

reg         tx_valid;
reg  [7:0]  tx_cmd;
reg  [7:0]  tx_data;
wire        tx_busy;

simpleserial_iface #(
    .CLK_FREQ(7_372_800),
    .BAUD    (38_400)
) u_ss (
    .clk     (iCE40CW312_CLK),
    .rst_n   (1'b1),
    .rx      (iCE40CW312_RX),
    .tx      (iCE40CW312_TX),
    .rx_valid(rx_valid),
    .rx_cmd  (rx_cmd),
    .rx_data (rx_data),
    .tx_valid(tx_valid),
    .tx_cmd  (tx_cmd),
    .tx_data (tx_data),
    .tx_busy (tx_busy)
);


always @(posedge iCE40CW312_CLK) begin
    tx_valid <= 1'b0;
    if (rx_valid && rx_cmd == CHAR_n && !tx_busy) begin
        tx_cmd   <= CHAR_o;
        tx_data  <= ~rx_data;
        tx_valid <= 1'b1;
    end
end

endmodule
