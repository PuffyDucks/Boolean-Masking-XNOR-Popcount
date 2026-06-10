module xnor_popcnt #(
    parameter N=8
)(
    input wire clk,
    input wire rstn,
    input wire [N-1:0] act,
    input wire [N-1:0] wt,
    output reg [$clog2(N+1)-1:0] out
);

//xnor
    wire [N-1:0] xnor_out;
    assign xnor_out = ~(act ^ wt);

//popcnt
    integer i;
    reg [$clog2(N+1)-1:0] popcnt;

    always @(*) begin
        popcnt = 0;
        for (i = 0; i < N; i = i + 1) begin
            popcnt = popcnt + xnor_out[i];
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
