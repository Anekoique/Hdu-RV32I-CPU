module Barrel(
        input [31:0] din,
        input [4:0] shamt,
        input lr,
        input al,
        output reg [31:0] dout
    );

    reg [31:0] sh_data [4:0];
    wire in;

    assign in = al ? din[31] : 1'b0;

    always @(*) begin
        if(lr) begin
            sh_data[0] = shamt[0] ? {din[30:0], 1'd0} : din;
            sh_data[1] = shamt[1] ? {sh_data[0][29:0], 2'd0} : sh_data[0];
            sh_data[2] = shamt[2] ? {sh_data[1][27:0], 4'd0} : sh_data[1];
            sh_data[3] = shamt[3] ? {sh_data[2][23:0], 8'd0} : sh_data[2];
            sh_data[4] = shamt[4] ? {sh_data[3][15:0], 16'd0} : sh_data[3];
        end
        else begin
            sh_data[0] = shamt[0] ? {{1{in}}, din[31:1]} : din;
            sh_data[1] = shamt[1] ? {{2{in}}, sh_data[0][31:2]} : sh_data[0];
            sh_data[2] = shamt[2] ? {{4{in}}, sh_data[1][31:4]} : sh_data[1];
            sh_data[3] = shamt[3] ? {{8{in}}, sh_data[2][31:8]} : sh_data[2];
            sh_data[4] = shamt[4] ? {{16{in}}, sh_data[3][31:16]} : sh_data[3];
        end
        dout = sh_data[4];
    end

endmodule
