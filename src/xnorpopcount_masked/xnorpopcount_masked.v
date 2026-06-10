module xnorpopcount_masked #(
    parameter N = 8
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  valid_in,
    input  wire [N-1:0]          act,
    input  wire [N-1:0]          wt,
    input  wire [N-1:0]          a_mask,
    input  wire [N-1:0]          w_mask,
    input  wire [N-1:0]          r_xnor,
    input  wire [7:0]            r_add,
    output reg                   valid_out,
    output reg  [$clog2(N+1)-1:0] mac_out
);

// Pipeline valid shift register
    reg [4:0] valid_pipe;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_pipe <= 5'b0;
            valid_out  <= 1'b0;
        end else begin
            valid_pipe <= {valid_pipe[3:0], valid_in};
            valid_out  <= valid_pipe[4];
        end
    end

//multiply masked
    wire [N-1:0] a1, a2, w1, w2;

    assign a1 = act ^ a_mask;
    assign a2 = a_mask;

    assign w1 = wt ^ w_mask;
    assign w2 = w_mask;

    wire [N-1:0] xnor1, xnor2;

    assign xnor1    = ~(a1 ^ w1);
    assign xnor2    =  (a2 ^ w2);

//register shares for timing separation (improves security)
    reg [N-1:0] xnor1_reg, xnor2_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            xnor1_reg <= 0;
            xnor2_reg <= 0;
        end else if (valid_in) begin
            xnor1_reg <= xnor1;
            xnor2_reg <= xnor2;
        end
    end

    wire [N-1:0] xnor_out;
    assign xnor_out = xnor1_reg ^ xnor2_reg;

//popcount
//mask the xnor used in popcount as well
    wire [N-1:0] xnor_s0, xnor_s1;
    assign xnor_s0 = xnor_out ^ r_xnor;
    assign xnor_s1 = r_xnor;

    wire sum0_s0 = xnor_s0[0] ^ xnor_s0[1];
    wire sum0_s1 = xnor_s1[0] ^ xnor_s1[1];

    wire sum1_s0 = xnor_s0[2] ^ xnor_s0[3];
    wire sum1_s1 = xnor_s1[2] ^ xnor_s1[3];

    wire sum2_s0 = xnor_s0[4] ^ xnor_s0[5];
    wire sum2_s1 = xnor_s1[4] ^ xnor_s1[5];

    wire sum3_s0 = xnor_s0[6] ^ xnor_s0[7];
    wire sum3_s1 = xnor_s1[6] ^ xnor_s1[7];

    wire [3:0] sums0 = {sum3_s0, sum2_s0, sum1_s0, sum0_s0};
    wire [3:0] sums1 = {sum3_s1, sum2_s1, sum1_s1, sum0_s1};

    wire car0_s0, car0_s1;
    and_masked ha0_carry (
        .clk(clk), .rst(rst),
        .a0(xnor_s0[0]), .a1(xnor_s1[0]), .b0(xnor_s0[1]), .b1(xnor_s1[1]),
        .r(r_add[0]), .c0(car0_s0), .c1(car0_s1)
    );

    wire car1_s0, car1_s1;
    and_masked ha1_carry (
        .clk(clk), .rst(rst),
        .a0(xnor_s0[2]), .a1(xnor_s1[2]), .b0(xnor_s0[3]), .b1(xnor_s1[3]),
        .r(r_add[1]), .c0(car1_s0), .c1(car1_s1)
    );

    wire car2_s0, car2_s1;
    and_masked ha2_carry (
        .clk(clk), .rst(rst),
        .a0(xnor_s0[4]), .a1(xnor_s1[4]), .b0(xnor_s0[5]), .b1(xnor_s1[5]),
        .r(r_add[2]), .c0(car2_s0), .c1(car2_s1)
    );

    wire car3_s0, car3_s1;
    and_masked ha3_carry (
        .clk(clk), .rst(rst),
        .a0(xnor_s0[6]), .a1(xnor_s1[6]), .b0(xnor_s0[7]), .b1(xnor_s1[7]),
        .r(r_add[3]), .c0(car3_s0), .c1(car3_s1)
    );

//and gates have a latency of 4 cycles which needs to be matched
    reg [3:0] sum0 [0:3];
    reg [3:0] sum1 [0:3];
    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 4; i = i + 1) begin
                sum0[i] <= 4'b0;
                sum1[i] <= 4'b0;
            end
        end else begin
            sum0[3] <= sum0[2];
            sum1[3] <= sum1[2];

            sum0[2] <= sum0[1];
            sum1[2] <= sum1[1];

            sum0[1] <= sum0[0];
            sum1[1] <= sum1[0];

            sum0[0] <= sums0;
            sum1[0] <= sums1;
        end
    end

    wire [3:0] sum_unmasked, car_unmasked;
    assign sum_unmasked = sum0[3] ^ sum1[3];
    assign car_unmasked = {car3_s0 ^ car3_s1,
                     car2_s0 ^ car2_s1,
                     car1_s0 ^ car1_s1,
                     car0_s0 ^ car0_s1};

    wire [$clog2(N+1)-1:0] final_sum;
    assign final_sum = sum_unmasked[0] + sum_unmasked[1] + sum_unmasked[2] + sum_unmasked[3]
                     + (car_unmasked[0] << 1) + (car_unmasked[1] << 1)
                     + (car_unmasked[2] << 1) + (car_unmasked[3] << 1);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mac_out <= 0;
        end else begin
            mac_out <= final_sum;
        end
    end
endmodule
