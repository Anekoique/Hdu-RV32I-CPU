`timescale 1ns / 1ps
module Seg(
        input clk,
        input rst,
        input [31:0] data,
        output reg [2:0] which,
        output reg [7:0] code
    );

    reg [14:0] count = 0;
    always @(posedge rst  or posedge clk) begin
        if(rst)
            count <= 0;
        else
            count <= count + 1'b1;
    end

    always @(posedge rst  or posedge count[14]) begin
        if(rst)
            which <= 0;
        else
            which <= which + 1'b1;
    end

    reg [3:0] data_x;
    always @* case (which)
        0: data_x = data[31:28];
        1: data_x = data[27:24];
        2: data_x = data[23:20];
        3: data_x = data[19:16];
        4: data_x = data[15:12];
        5: data_x = data[11:8];
        6: data_x = data[7:4];
        7: data_x = data[3:0];
    endcase

    always @* case (data_x)
        4'h0: code = 8'b0000_0011;
        4'h1: code = 8'b1001_1111;
        4'h2: code = 8'b0010_0101;
        4'h3: code = 8'b0000_1101;
        4'h4: code = 8'b1001_1001;
        4'h5: code = 8'b0100_1001;
        4'h6: code = 8'b0100_0001;
        4'h7: code = 8'b0001_1111;
        4'h8: code = 8'b0000_0001;
        4'h9: code = 8'b0000_1001;
        4'hA: code = 8'b0001_0001;
        4'hB: code = 8'b1100_0001;
        4'hC: code = 8'b0110_0011;
        4'hD: code = 8'b1000_0101;
        4'hE: code = 8'b0110_0001;
        4'hF: code = 8'b0111_0001;
    endcase

endmodule
