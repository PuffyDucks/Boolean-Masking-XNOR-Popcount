// 8-N-1 idle-high
// asserts valid for 1 cycle
module uart_rx #(
    parameter CLK_FREQ = 7_372_800,
    parameter BAUD     =    38_400
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx,
    output reg        valid,
    output reg  [7:0] data
);

localparam [15:0] CLKS_PER_BIT = CLK_FREQ / BAUD;

// sync rx to prevent metastability
reg [1:0] rx_buf;
wire rx_sync = rx_buf[1];
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        rx_buf <= 2'b11;
    else
        rx_buf <= {rx_buf[0], rx};
end

localparam IDLE  = 2'd0,
           START = 2'd1,
           DATA  = 2'd2,
           STOP  = 2'd3;

reg [1:0] state;
reg [8:0] down_timer;
reg [2:0] bit_count;
reg [7:0] data_fifo;
always @(posedge clk) begin
    valid <= 1'b0;
    if (!rst_n)
        state <= IDLE;
    else case (state)
        IDLE: 
            if (!rx_buf) begin
                // start when rx pulled low
                // offset by CLKS_PER_BIT / 2 to center sample 
                down_timer <= CLKS_PER_BIT / 2 - 1;
                state <= START;
            end
        START: 
            if (down_timer == 0) begin
                // sample center of start bit
                if (!rx_buf) begin
                    down_timer  <= CLKS_PER_BIT - 1;
                    bit_count   <= 3'd0;
                    state       <= DATA;
                end else
                    state       <= IDLE;  // false start
            end else
                down_timer <= down_timer - 1;
        DATA:  
            if (down_timer == 0) begin
                // take 8 samples of data bits
                down_timer <= CLKS_PER_BIT - 1;
                data_fifo  <= {rx_sync, data_fifo[7:1]};
                if (bit_count == 3'd7) 
                    state  <= STOP;
                else
                    bit_count <= bit_count + 1;
            end else
                down_timer <= down_timer - 1;
        STOP:  
            if (down_timer == 0) begin
                // set valid on stop bit 
                if (rx_buf) begin
                    data  <= data_fifo;
                    valid <= 1'b1;
                end
                state <= IDLE;
            end else
                down_timer <= down_timer - 1;
    endcase
end

endmodule
