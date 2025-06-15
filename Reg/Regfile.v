module Regfile (
        input rst,
        input clk,
        input [4:0] Ra,
        input [4:0] Rb,
        input [4:0] Rw,
        input [31:0] busW,
        input RegWr,
        output wire [31:0] busA,
        output wire [31:0] busB
    );

    reg [31:0] regs [31:0];

    assign busA = (Ra == 5'd0) ? 32'd0 : regs[Ra];
    assign busB = (Rb == 5'd0) ? 32'd0 : regs[Rb];

    integer i;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            for(i = 0; i < 32; i = i + 1) begin
                regs[i] <= 32'd0;
            end
        end
        else if(RegWr && Rw != 5'd0)
            regs[Rw] <= busW;
    end

endmodule
