module mac_unmasked #(
    parameter N=8
)(
    input wire clk,
    input wire rst,
    input wire [N-1:0] act,
    input wire [N-1:0] wt,
    output reg [$clog2(N+1)-1:0] mac_out
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

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mac_out <= 0;
        end else begin
            mac_out <= popcnt;
        end
    end
endmodule
