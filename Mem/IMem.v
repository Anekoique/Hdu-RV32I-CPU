module IMem(
        input clk,
        input [7:2] addr,
        output [31:0] inst
    );

    ROM rom_inst (
            .clka(clk),
            .addra(addr),
            .douta(inst)
        );

endmodule
