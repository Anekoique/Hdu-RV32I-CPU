`timescale 1ns / 1ps
module Top(
        input clk,
        input clk_on,
        input rst,
        input [3:0] SegSel,
        output enable,
        output [2:0] which,
        output [7:0] code
    );

    CPU RV32I (
        .clk(clk),
        .clk_on(clk_on),
        .rst(rst),
        .SegSel(SegSel),
        .enable(enable),
        .which(which),
        .code(code)
    );

endmodule
