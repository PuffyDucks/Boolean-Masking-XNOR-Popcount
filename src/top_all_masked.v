`default_nettype none

module top_all_masked (
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

wire trng_bit, trng_valid;
trng u_trng (
    .clk      (iCE40CW312_CLK),
    .rst_n    (1'b1),
    .trng_bit (trng_bit),
    .valid    (trng_valid)
);

wire [31:0] mask_buf;
wire mask_buf_valid;
mask_buffer #(
    .N(32)
) u_mask_buf (
    .clk(iCE40CW312_CLK),
    .rst_n   (1'b1),
    .trng_bit(trng_bit),
    .trng_valid(trng_valid),
    .data(mask_buf),
    .valid(mask_buf_valid)
);

localparam CHAR_a = 8'h61,
           CHAR_w = 8'h77,
           CHAR_o = 8'h6F;

localparam RECV_A    = 3'd0,
           RECV_W    = 3'd1,
           GET_MASKS = 3'd2,
           CALC_O    = 3'd3,
           WAIT_O    = 3'd4,
           SEND_O    = 3'd5;

reg  [2:0] state = 3'd0;
reg  [7:0] a_buf;
reg  [7:0] w_buf;
reg  [7:0] a_mask, w_mask, r_xnor, r_add;
wire [$clog2(8+1)-1:0] out;
wire valid_out;

reg TIO4 = 1'b0;
assign iCE40CW312_GPIO_O = {TIO4, 1'b0};

xnor_pc_all_masked #(
    .N(8)
) u_xnor_popcnt (
    .clk      (iCE40CW312_CLK),
    .rst_n    (1'b1),
    .valid_in (state == CALC_O),
    .act      (a_buf),
    .wt       (w_buf),
    .a_mask   (a_mask),
    .w_mask   (w_mask),
    .r_xnor   (r_xnor),
    .r_add    (r_add),
    .valid_out(valid_out),
    .out      (out)
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
                state <= GET_MASKS;
            end
        GET_MASKS:
            if (mask_buf_valid) begin
                TIO4   <= 1'b1;
                state  <= CALC_O;
                a_mask <= mask_buf[7:0];
                w_mask <= mask_buf[15:8];
                r_xnor <= mask_buf[23:16];
                r_add  <= mask_buf[31:24];
            end
        CALC_O: begin
            state <= WAIT_O;
            TIO4  <= 1'b0;
        end
        WAIT_O:
            if (valid_out) begin
                state <= SEND_O;
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
