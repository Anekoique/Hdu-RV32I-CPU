`timescale 1ns / 1ps
module CPU (
        input clk,
        input clk_on,
        input rst,
        input [3:0] SegSel,
        output enable,
        output [2:0] which,
        output [7:0] code
    );

    assign enable = 1'b1;

    /*================ Define ================*/

    parameter Branch_eq   = 3'b000;
    parameter Branch_ne   = 3'b001;
    parameter Branch_lt   = 3'b100;
    parameter Branch_ge   = 3'b101;

    parameter WBSel_ALU = 1'b0;
    parameter WBSel_MEM = 1'b1;

    /*============ IF ============*/

    wire [31:0] pc;
    wire [31:0] dnpc;
    wire [31:0] inst;
    wire [31:0] imem_inst;

    /*============ ID ============*/

    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;
    wire [4:0] rs1, rs2, rd;

    wire [3:0] ALUSel;
    wire ASel;
    wire [1:0] BSel;
    wire [2:0] ImmSel;
    wire WBSel;
    wire [2:0] PCSel;
    wire MemWr;
    wire RegWr;

    wire [31:0] imm;
    wire [31:0] reg_data1, reg_data2;
    wire [31:0] a, b;
    wire [31:0] ALU_A, ALU_B;

    /*============ EX ============*/

    wire [31:0] r, ALU_R;
    wire less, zero;
    reg  BJump;

    /*============ MEM ============*/

    wire [31:0] mem_data;

    /*============ WB ============*/

    wire [31:0] wb_data;
    reg [31:0] SegData;

    /*================ Execute ================*/

    /*============ IF ============*/

    Dnpc dnpc_gen (
            .rst(rst),
            .pc(pc),
            .reg_data(reg_data1),
            .imm(imm),
            .PCSel(PCSel),
            .BJump(BJump),
            .dnpc(dnpc)
        );

    Reg PC (
            .clk(clk_on),
            .rst(rst),
            .data_in(dnpc),
            .data_out(pc)
        );

    IMem imem (
            .clk(clk),
            .addr(pc[7:2]),
            .inst(imem_inst)
        );

    Reg IR (
            .clk(clk),
            .rst(rst),
            .data_in(imem_inst),
            .data_out(inst)
        );

    /*============ ID ============*/

    assign {funct7, rs2, rs1, funct3, rd, opcode} = inst;

    CU control_gen (
           .opcode(opcode),
           .funct3(funct3),
           .funct7(funct7),
           .ALUSel(ALUSel),
           .ASel(ASel),
           .BSel(BSel),
           .ImmSel(ImmSel),
           .PCSel(PCSel),
           .MemWr(MemWr),
           .RegWr(RegWr),
           .WBSel(WBSel)
       );

    Imm imm_gen (
            .inst(inst),
            .ImmSel(ImmSel),
            .imm(imm)
        );

    Regfile Regs(
            .clk(clk_on),
            .rst(rst),
            .Ra(rs1),
            .Rb(rs2),
            .Rw(rd),
            .busW(wb_data),
            .RegWr(RegWr),
            .busA(reg_data1),
            .busB(reg_data2)
        );

    Reg A (
            .clk(clk),
            .rst(rst),
            .data_in(reg_data1),
            .data_out(a)
        );
    Reg B (
            .clk(clk),
            .rst(rst),
            .data_in(reg_data2),
            .data_out(b)
        );

    assign ALU_A = ASel    ? a : pc;
    assign ALU_B = BSel[1] ? 32'd4 : (BSel[0] ? imm : b);

    /*============ EX ============*/

    Alu alu (
            .a(ALU_A),
            .b(ALU_B),
            .ALUSel(ALUSel),
            .less(less),
            .zero(zero),
            .r(r)
        );

    Reg F (
            .clk(clk),
            .rst(rst),
            .data_in(r),
            .data_out(ALU_R)
        );

    always @(*) begin
        case (PCSel)
            Branch_eq:    BJump = zero;
            Branch_ne:    BJump = ~zero;
            Branch_lt:    BJump = less;
            Branch_ge:    BJump = ~less;
            default:      BJump = 1'b0;
        endcase
    end

    /*============ MEM ============*/

    DMem dmem (
            .clk(~clk_on),
            .addr(ALU_R[7:2]),
            .din(reg_data2),
            .MemWr(MemWr),
            .dout(mem_data)
        );

    /*============ WB ============*/

    assign wb_data = WBSel == WBSel_ALU ? ALU_R : mem_data;

    /*================ Show ================*/

    always @(*) begin
        case (SegSel)
            0: SegData = inst;
            1: SegData = pc;
            2: SegData = mem_data;
            3: SegData = ALU_R;
            4: SegData = reg_data1;
            5: SegData = reg_data2;
            6: SegData = imm;
            7: SegData = wb_data;
        endcase
    end

    Seg seg (
            .clk(clk),
            .rst(rst),
            .data(SegData),
            .which(which),
            .code(code)
        );

endmodule
