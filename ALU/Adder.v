module Adder(
        input [31:0] a,
        input [31:0] b,
        input Cin,
        output wire [31:0] r,
        output wire cf, of
    );

    wire c32;
    wire [31:0] neg_b = {32{Cin}} ^ b;
    assign {c32, r} = a + neg_b + {31'd0, Cin};
    assign cf = c32 ^ Cin;
    assign of = (a[31] == neg_b[31]) & (a[31] != r[31]);

endmodule
