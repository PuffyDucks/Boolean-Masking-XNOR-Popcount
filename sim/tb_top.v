`timescale 1ns/1ps
`default_nettype none

module tb_top;

localparam CLKS_PER_BIT = 192;

reg clk = 1'b0;
reg rx  = 1'b1;
wire tx;

top dut (
    .iCE40CW312_CLK (clk),
    .iCE40CW312_RX  (rx),
    .iCE40CW312_TX  (tx)
);

// Tap uart_tx output directly for receive monitoring

always #68 clk = ~clk;

initial begin
    $dumpfile("tb_top.vcd");
    $dumpvars(0, tb_top);
end

task uart_send;
    input [7:0] data;
    begin
        rx = 1'b0;
        repeat(CLKS_PER_BIT) @(posedge clk);
        for (integer i = 0; i < 8; i = i + 1) begin
            rx = data[i];
            repeat(CLKS_PER_BIT) @(posedge clk);
        end
        rx = 1'b1;
        repeat(CLKS_PER_BIT) @(posedge clk);
    end
endtask

function [7:0] nib2hex;
    input [3:0] nib;
    if (nib >= 4'h0 && nib <= 4'h9) // 0-9
        nib2hex = {4'h3, nib};
    else // A-F
        nib2hex = {4'h4, nib - 4'h9};
endfunction

task ss_write;
    input [7:0] cmd;
    input [7:0] data;
    begin
        uart_send(cmd);
        uart_send(nib2hex(data[7:4]));
        uart_send(nib2hex(data[3:0]));
        uart_send(8'h0A);
    end
endtask

initial begin
    repeat(20) @(posedge clk);
    ss_write(8'h6e, 8'h0F);
    repeat(CLKS_PER_BIT * 20) @(posedge clk);
    // test_n(8'hFF);
    // test_n(8'hAA);
    // test_n(8'h12);
    $finish;
end

endmodule
