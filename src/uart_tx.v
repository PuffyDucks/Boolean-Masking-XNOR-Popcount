module uart_tx #(
    parameter CLK_FREQ = 7_372_800,
    parameter BAUD     =    38_400
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       valid,
    input  wire [7:0] data,
    output reg        tx,
    output wire       busy
);
localparam [15:0] CLKS_PER_BIT = CLK_FREQ / BAUD;

localparam IDLE  = 2'd0,
           START = 2'd1,
           DATA  = 2'd2,
           STOP  = 2'd3;

reg [1:0] state = 2'd0;
reg [9:0] down_timer;
reg [2:0] bit_count;
reg [7:0] data_buf;


assign busy = (state != IDLE);

always @(posedge clk) begin
    if (!rst_n) begin
        state <= IDLE;
        tx    <= 1'b1;
    end else case (state)
        IDLE: begin
            tx <= 1'b1;
            if (valid) begin
                state      <= START;
                down_timer <= CLKS_PER_BIT - 1;
                data_buf   <= data;
            end
        end
        START: begin 
            tx <= 1'b0;
            if (down_timer == 0) begin
                state      <= DATA;
                down_timer <= CLKS_PER_BIT - 1;
                bit_count  <= 3'd0;
            end else
                down_timer <= down_timer - 1;
        end
        DATA: begin
            tx <= data_buf[0];
            if (down_timer == 0) begin
                down_timer <= CLKS_PER_BIT - 1;
                data_buf   <= (data_buf >> 1);
                if (bit_count == 3'd7) state <= STOP;
                else bit_count <= bit_count + 1;
            end else
                down_timer <= down_timer - 1;
        end
        STOP: begin
            tx <= 1'b1;
            if (down_timer == 0) begin
                state <= IDLE;
            end else
                down_timer <= down_timer - 1;
        end
        
    endcase
end
           
endmodule
