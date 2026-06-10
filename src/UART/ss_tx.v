`default_nettype none
// takes cmd and data and encodes into simpleserial uart 
// https://chipwhisperer.readthedocs.io/en/latest/simpleserial.html#simpleserial-version-1-1

module ss_tx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       in_valid,
    input  wire [7:0] in_cmd,
    input  wire [7:0] in_data,
    input  wire       in_busy,
    output reg        out_valid,
    output reg  [7:0] out_data,
    output wire       out_busy
);

localparam IDLE       = 3'd0,
           START_CMD  = 3'd1,
           WAIT_CMD   = 3'd2,
           START_HEX1 = 3'd3,
           WAIT_HEX1  = 3'd4,
           START_HEX2 = 3'd5,
           WAIT_HEX2  = 3'd6,
           START_LF   = 3'd7;

localparam CHAR_NEWLINE = 8'h0A;// '\n'

reg [2:0] state = 3'd0;
reg [7:0] cmd_buf;
reg [7:0] data_buf;

function [7:0] nib2hex;
    // converts nibble to ascii encoded hex character
    input [3:0] nib;
    if (nib >= 4'h0 && nib <= 4'h9) // 0-9
        nib2hex = {4'h3, nib};
    else // A-F
        nib2hex = {4'h4, nib - 4'h9};
endfunction

assign out_busy = (state != IDLE);

always @(posedge clk) begin
    out_valid <= 1'b0;
    if (!rst_n)
        state <= IDLE;
    else case (state)
        IDLE:
            if (in_valid) begin
                cmd_buf  <= in_cmd;
                data_buf <= in_data;
                state    <= START_CMD;
            end
        START_CMD:
            if (~in_busy) begin
                out_valid <= 1'b1;
                out_data  <= cmd_buf;
                state     <= WAIT_CMD;
            end
        WAIT_CMD:
            if (in_busy) state <= START_HEX1;
        START_HEX1:
            if (~in_busy) begin
                out_valid <= 1'b1;
                out_data  <= nib2hex(data_buf[7:4]);
                state     <= WAIT_HEX1;
            end
        WAIT_HEX1:
            if (in_busy) state <= START_HEX2;
        START_HEX2:
            if (~in_busy) begin
                out_valid <= 1'b1;
                out_data  <= nib2hex(data_buf[3:0]);
                state     <= WAIT_HEX2;
            end
        WAIT_HEX2:
            if (in_busy) state <= START_LF;
        START_LF:
            if (~in_busy) begin
                out_valid <= 1'b1;
                out_data  <= CHAR_NEWLINE;
                state     <= IDLE;
            end
    endcase
end

endmodule
