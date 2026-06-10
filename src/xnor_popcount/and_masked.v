module and_masked (
    input  wire clk,
    input  wire a0, a1,
    input  wire b0, b1,
    input  wire r,
    input  wire rst_n,
    output reg  c0,
    output reg  c1
);

    wire and00, and01, and10, and11;
    assign and00 = a0 & b0;
    assign and01 = a0 & b1;
    assign and10 = a1 & b0;
    assign and11 = a1 & b1;

    wire xor1 = r ^ and00;

    //1
    reg r1, and001, and011, and101, and111;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r1 <= 0;
            and001 <= 0;
            and011 <= 0;
            and101 <= 0;
            and111 <= 0;
        end else begin
            r1 <= r;
            and001 <= xor1;
            and011 <= and01;
            and101 <= and10;
            and111 <= and11;
        end
    end

    wire xor2 = and001 ^ and011;

    //2
    reg r2, and002, and102, and112;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r2 <= 0;
            and002 <= 0;
            and102 <= 0;
            and112 <= 0;
        end else begin
            r2 <= r1;
            and002 <= xor2;
            and102 <= and101;
            and112 <= and111;
        end
    end

    wire xor3 = and002 ^ and102;

    //3
    reg r3, and003, and113;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r3 <= 0;
            and003 <= 0;
            and113 <= 0;
        end else begin
            r3 <= r2;
            and003 <= xor3;
            and113 <= and112;
        end
    end

    wire xor4 = and003 ^ and113;

    //4
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            c0 <= 0;
            c1 <= 0;
        end else begin
            c0 <= r3;
            c1 <= xor4;
        end
    end

endmodule
