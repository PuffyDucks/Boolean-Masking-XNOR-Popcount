module xnor_masked #(
    parameter N=8
)(
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire [N-1:0] act,
    input wire [N-1:0] wt,
    input wire [N-1:0] a_mask,
    input wire [N-1:0] w_mask,
    output reg valid_out,
    output reg [$clog2(N+1)-1:0] mac_out
);

// Pipeline valid shift register (2 cycles latency: xnor_reg + mac_out_reg)
    reg [1:0] valid_pipe;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_pipe <= 2'b0;
            valid_out  <= 1'b0;
        end else begin
            valid_pipe <= {valid_pipe[0], valid_in};
            valid_out  <= valid_pipe[1];
        end
    end

//masking
    wire [N-1:0] a1, a2, w1, w2;

    assign a1 = act ^ a_mask;
    assign w1 = wt ^ w_mask;

    assign a2 = a_mask;
    assign w2 = w_mask;

//xnor
    wire [N-1:0] xnor1, xnor2;

    assign xnor1 = ~(a1 ^ w1);
    assign xnor2 = (a2 ^ w2);
  //assign xnor_out = (xnor1 ^ xnor2);

//popcnt
reg [N-1:0] xnor_s0_reg, xnor_s1_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            xnor_s0_reg <= 0;
            xnor_s1_reg <= 0;
        end else if (valid_in) begin
            xnor_s0_reg <= xnor1;
            xnor_s1_reg <= xnor2;
        end
    end

    wire [N-1:0] xnor_out;
    assign xnor_out = xnor_s0_reg ^ xnor_s1_reg;

    integer i;
    reg [$clog2(N+1)-1:0] popcnt;

    always @(*) begin
        popcnt = 0;
        for (i = 0; i < N; i = i + 1) begin
            popcnt = popcnt + xnor_out[i];
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mac_out <= 0;
        end else begin
            mac_out <= popcnt;
        end
    end
endmodule
