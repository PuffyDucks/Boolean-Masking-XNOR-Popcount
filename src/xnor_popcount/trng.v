// trng generators w/ two oscillators
// von neumann debiased
module trng (
    input  wire clk,
    input  wire rst_n,
    output reg  trng_bit,
    output reg  valid
);

// oscillators, built into ICE40UP5K 
wire lf_clk, hf_clk;

SB_LFOSC u_lf (
    .CLKLFEN (1'b1),
    .CLKLFPU (1'b1),
    .CLKLF   (lf_clk)
);

SB_HFOSC #(.CLKHF_DIV("0b11")) u_hf (
    .CLKHFEN (1'b1),
    .CLKHFPU (1'b1),
    .CLKHF   (hf_clk)
);

// sample by XORing both oscillators
reg sample;
always @(posedge clk or negedge rst_n)
    if (!rst_n) sample <= 1'b0;
    else sample <= lf_clk ^ hf_clk;

// von neumann debiasing
// sample pair. if equal, discard
// 01 -> 0, 10 -> 1
reg state, buf_bit;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state     <= 1'b0;
        buf_bit   <= 1'b0;
        trng_bit  <= 1'b0;
        valid     <= 1'b0;
    end else begin
        valid <= 1'b0;
        if (!state) begin
            buf_bit <= sample;
            state   <= 1'b1;
        end else begin
            state <= 1'b0;
            // discard if equal
            if (buf_bit != sample) begin
                trng_bit <= buf_bit;
                valid    <= 1'b1;
            end
        end
    end
end

endmodule
