module Dnpc (
        input rst,
        input [31:0] pc,
        input [31:0] reg_data,
        input [31:0] imm,
        input [2:0] PCSel,
        input BJump,
        output reg [31:0] dnpc
    );

    parameter PCSel_jal   = 3'b011;
    parameter PCSel_jalr  = 3'b110;
    parameter PCSel_snpc  = 3'b111;

    wire [31:0] dnpc_branch;
    wire [31:0] dnpc_jalr;
    assign dnpc_branch = BJump ? pc + imm : pc + 4;
    assign dnpc_jalr = reg_data + imm;

    always @(*) begin
        if (rst)                        dnpc = 32'h00000000;
        else if (PCSel == PCSel_jal)    dnpc = pc + imm;
        else if (PCSel == PCSel_jalr)   dnpc = dnpc_jalr;
        else if (PCSel == PCSel_snpc)   dnpc = pc + 4;
        else                            dnpc = dnpc_branch;
    end

endmodule
