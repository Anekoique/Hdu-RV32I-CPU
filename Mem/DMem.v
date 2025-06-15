module DMem (
        input clk,
        input [7:2] addr,
        input [31:0] din,
        input MemWr,
        output [31:0] dout
    );

    RAM ram_data (
            .clka(clk),
            .wea(MemWr),
            .addra(addr),
            .dina(din),
            .douta(dout)
        );

endmodule
