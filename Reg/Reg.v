module Reg(
        input clk,
        input rst,
        input [31:0] data_in,
        output reg [31:0] data_out
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out <= 32'b0;
        end
        else begin
            data_out <= data_in;
        end
    end

endmodule
