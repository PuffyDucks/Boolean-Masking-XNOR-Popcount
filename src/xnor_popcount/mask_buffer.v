`default_nettype none

module mask_buffer #(
    parameter N = 8
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        trng_bit,
    input  wire        trng_valid,
    output reg [N-1:0] data,
    output reg         valid
);

    reg [$clog2(N)-1:0] bit_count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data      <= 0;
            bit_count <= 0;
            valid     <= 1'b0;
        end else begin
            valid <= 1'b0;
            if (trng_valid) begin
                data[bit_count] <= trng_bit;
                if (bit_count == N - 1) begin
                    bit_count <= 0;
                    valid <= 1'b1;
                end else begin
                    bit_count <= bit_count + 1;
                end
            end
        end
    end

endmodule
