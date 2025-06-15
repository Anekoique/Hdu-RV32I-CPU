module Alu(
        input [31:0] a,
        input [31:0] b,
        input [3:0] ALUSel,
        output wire less, zero,
        output reg [31:0] r
    );

    wire cin;
    wire cf, of, sf;
    wire [31:0] adder_r;
    Adder adder(
            .a(a),
            .b(b),
            .Cin(cin),
            .r(adder_r),
            .cf(cf),
            .of(of)
        );

    wire lr, al;
    wire [31:0] barrel_r;
    Barrel barrel(
            .din(a),
            .shamt(b[4:0]),
            .lr(lr),
            .al(al),
            .dout(barrel_r)
        );

    assign cin = ALUSel[3] | ALUSel[1];
    assign lr = ~ALUSel[2];
    assign al = ALUSel[3];
    assign sf = adder_r[31];
    assign less = ALUSel[0] ? cf : sf ^ of;
    assign zero = ~|r;

    always @(*) begin
        casez(ALUSel)
            4'b?000: r = adder_r;
            4'b??01: r = barrel_r;
            4'b001?: r = {31'd0, less};
            4'b?100: r = a ^ b;
            4'b?110: r = a | b;
            4'b0111: r = a & b;
            4'b1111: r = b;
            default: r = adder_r;
        endcase
    end

endmodule
