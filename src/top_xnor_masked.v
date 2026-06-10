`default_nettype none

module top_xnor_masked (
    input  wire       iCE40CW312_CLK,
    input  wire       iCE40CW312_RX,
    output wire       iCE40CW312_TX,
    output wire [1:0] iCE40CW312_GPIO_O
);

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

localparam CHAR_a = 8'h61,
           CHAR_w = 8'h77,
           CHAR_o = 8'h6F;

localparam RECV_A  = 2'd0,
           RECV_W  = 2'd1,
           CALC_O  = 2'd2,
           SEND_O  = 2'd3;

reg  [1:0] state = 2'd0;
reg  [7:0] a_buf;
reg  [7:0] w_buf;
wire [3:0] out;

reg TIO4 = 1'b0;
assign iCE40CW312_GPIO_O = {TIO4, 1'b0};

xnor_pc_masked_xnor #(
    .N(8)
) u_xnor_popcnt (
    .clk    (iCE40CW312_CLK),
    .rstn   (1'b1),
    .act    (a_buf),
    .wt     (w_buf),
    .a_mask (8'h55),
    .w_mask (8'hAA),
    .out    (out)
);

always @(posedge iCE40CW312_CLK) begin
    tx_valid <= 1'b0;
    TIO4  <= 1'b0;
    case (state)
        RECV_A:
            if (rx_valid && rx_cmd == CHAR_a) begin
                a_buf <= rx_data;
                state <= RECV_W;
            end
        RECV_W:
            if (rx_valid && rx_cmd == CHAR_w) begin
                w_buf <= rx_data;
                state <= CALC_O;
                TIO4  <= 1'b1;
            end
        CALC_O: begin
            state <= SEND_O;
            TIO4  <= 1'b0;
        end
        SEND_O: 
            if (!tx_busy) begin
                tx_cmd   <= CHAR_o;
                tx_data  <= {4'd0, out};
                tx_valid <= 1'b1;
                state <= RECV_A;
            end
    endcase
end

endmodule
