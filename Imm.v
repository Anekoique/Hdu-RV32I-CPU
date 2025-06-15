module Imm (
        input [31:0] inst,
        input [2:0] ImmSel,
        output reg [31:0] imm
    );

    parameter ImmItype = 3'b000;
    parameter ImmUtype = 3'b001;
    parameter ImmStype = 3'b010;
    parameter ImmBtype = 3'b011;
    parameter ImmJtype = 3'b100;

    wire [31:0] immI, immU, immS, immB, immJ;

    assign immI = {{20{inst[31]}}, inst[31:20]};
    assign immU = {inst[31:12], 12'b0};
    assign immS = {{20{inst[31]}}, inst[31:25], inst[11:7]};
    assign immB = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
    assign immJ = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};

    always @(*) begin
        case(ImmSel)
            ImmItype: imm = immI;
            ImmUtype: imm = immU;
            ImmStype: imm = immS;
            ImmBtype: imm = immB;
            ImmJtype: imm = immJ;
            default:  imm = immI;
        endcase
    end

endmodule
