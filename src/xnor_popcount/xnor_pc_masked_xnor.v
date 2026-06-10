module xnor_pc_masked_xnor #(
    parameter N=8
)(
    input wire clk,
    input wire rstn,
    input wire [N-1:0] act,
    input wire [N-1:0] wt,
    input wire [N-1:0] a_mask,
    input wire [N-1:0] w_mask,
    output reg [$clog2(N+1)-1:0] out
);

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

//popcnt
    integer i;
    reg [$clog2(N+1)-1:0] popcnt;

    always @(*) begin
        popcnt = 0;
        for (i = 0; i < N; i = i + 1) begin
            popcnt = popcnt + (xnor1[i] ^ xnor2[i]);
        end
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            out <= 0;
        end else begin
            out <= popcnt;
        end
    end
endmodule
