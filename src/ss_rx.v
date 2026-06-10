`default_nettype none
// takes simpleserial data from uart and decodes cmd and data values
// https://chipwhisperer.readthedocs.io/en/latest/simpleserial.html#simpleserial-version-1-1
module ss_rx (
    input  wire       clk,
    input  wire       rst_n,    
    input  wire       in_valid,
    input  wire [7:0] in_data,
    output reg        out_valid,
    output reg  [7:0] out_cmd,
    output reg  [7:0] out_data
);

localparam WAIT_CMD  = 2'd0,
           WAIT_HEX1 = 2'd1,
           WAIT_HEX2 = 2'd2,
           WAIT_END  = 2'd3;

localparam CHAR_NEWLINE = 8'h0A; // '\n'

reg [1:0] state;
reg [7:0] cmd_buf;
reg [7:0] data_buf;

function [3:0] hex2nib;
    // converts ASCII encoded hex to nibble 
    input [7:0] hex;
    if (hex >= 8'h30 && hex <= 8'h39)      // '0'-'9'
        hex2nib = hex[3:0];
    else if (hex >= 8'h41 && hex <= 8'h46) // 'A'-'F'
        hex2nib = hex[3:0] + 4'h9;
    else if (hex >= 8'h61 && hex <= 8'h66) // 'a'-'f'
        hex2nib = hex[3:0] + 4'h9; 
    else
        hex2nib = 4'h0;
endfunction

always @(posedge clk) begin
    out_valid <= 1'b0;
    if (!rst_n)
        state <= WAIT_CMD;
    else case (state)
        WAIT_CMD:
            if (in_valid) begin
                cmd_buf <= in_data;
                state   <= WAIT_HEX1;
            end
        WAIT_HEX1:
            if (in_valid) begin
                data_buf[7:4] <= hex2nib(in_data);
                state         <= WAIT_HEX2;
            end
        WAIT_HEX2:
            if (in_valid) begin
                data_buf[3:0] <= hex2nib(in_data);
                state         <= WAIT_END;
            end
        WAIT_END:
            if (in_valid & (in_data == CHAR_NEWLINE)) begin
                out_valid <= 1'b1;
                out_cmd   <= cmd_buf;
                out_data  <= data_buf;
                state     <= WAIT_CMD;
            end
    endcase
end

endmodule
