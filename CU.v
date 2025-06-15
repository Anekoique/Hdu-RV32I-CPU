module CU (
        input [6:0] opcode,
        input [2:0] funct3,
        input [6:0] funct7,
        output reg [3:0] ALUSel,
        output reg ASel,
        output reg [1:0] BSel,
        output reg [2:0] PCSel,
        output reg [2:0] ImmSel,
        output reg WBSel,
        output reg MemWr,
        output reg RegWr
    );

    /*============ Define ============*/

    parameter EN = 1'b1;
    parameter NOT = 1'b0;

    /*======= Opcode =======*/

    // R-type
    parameter Rtype         = 7'b0110011;
    // I-type
    parameter Itype_compute = 7'b0010011;
    parameter jalr          = 7'b1100111;
    parameter load          = 7'b0000011;
    // B-type
    parameter Btype         = 7'b1100011;
    // J-type
    parameter jal           = 7'b1101111;
    // S-type
    parameter store         = 7'b0100011;
    // U-type
    parameter lui           = 7'b0110111;
    parameter auipc         = 7'b0010111;

    /*======= ImmSel =======*/

    parameter ImmItype = 3'b000;
    parameter ImmUtype = 3'b001;
    parameter ImmStype = 3'b010;
    parameter ImmBtype = 3'b011;
    parameter ImmJtype = 3'b100;

    /*======= ASel =======*/

    parameter ASel_pc  = 1'b0;
    parameter ASel_rs1 = 1'b1;

    /*======= BSel =======*/

    parameter BSel_rs2 = 2'b00;
    parameter BSel_imm = 2'b01;
    parameter BSel_4   = 2'b10;
    
    /*======= ALUSel =======*/

    parameter ALUSel_add = 4'b0000;
    parameter ALUSel_B   = 4'b1111;

    /*======= PCSel =======*/

    parameter PCSel_jal     = 3'b011;
    parameter PCSel_jalr    = 3'b110;
    parameter PCSel_snpc    = 3'b111;

    /*======= WBSel =======*/

    parameter WBSel_ALU = 1'b0;
    parameter WBSel_MEM = 1'b1;

    /*============ Control ============*/

    always @(*) begin
        case(opcode)
            lui:            ImmSel   = ImmUtype;
            auipc:          ImmSel   = ImmUtype;
            Itype_compute:  ImmSel   = ImmItype;
            Rtype:          ImmSel   = ImmItype;
            jal:            ImmSel   = ImmJtype;
            jalr:           ImmSel   = ImmItype;
            Btype:          ImmSel   = ImmBtype;
            load:           ImmSel   = ImmItype;
            store:          ImmSel   = ImmStype;
            default:        ImmSel   = ImmItype;
        endcase
    
        case(opcode)
            lui:            RegWr   = EN;
            auipc:          RegWr   = EN;
            Itype_compute:  RegWr   = EN;
            Rtype:          RegWr   = EN;
            jal:            RegWr   = EN;
            jalr:           RegWr   = EN;
            Btype:          RegWr   = NOT;
            load:           RegWr   = EN;
            store:          RegWr   = NOT;
            default:        RegWr   = NOT;
        endcase
    
        case(opcode)
            lui:            ASel = ASel_rs1;
            auipc:          ASel = ASel_pc;
            Itype_compute:  ASel = ASel_rs1;
            Rtype:          ASel = ASel_rs1;
            jal:            ASel = ASel_pc;
            jalr:           ASel = ASel_pc;
            Btype:          ASel = ASel_rs1;
            load:           ASel = ASel_rs1;
            store:          ASel = ASel_rs1;
            default:        ASel = ASel_rs1;
        endcase
    
        case(opcode)
            lui:            BSel = BSel_imm;
            auipc:          BSel = BSel_imm;
            Itype_compute:  BSel = BSel_imm;
            Rtype:          BSel = BSel_rs2;
            jal:            BSel = BSel_4;
            jalr:           BSel = BSel_4;
            Btype:          BSel = BSel_rs2;
            load:           BSel = BSel_imm;
            store:          BSel = BSel_imm;
            default:        BSel = BSel_rs2;
        endcase
    
        case(opcode)
            lui:            ALUSel  = ALUSel_B;
            auipc:          ALUSel  = ALUSel_add;
            Itype_compute:  ALUSel  = {funct3 == 3'b101 & funct7[5], funct3};
            Rtype:          ALUSel  = {funct7[5], funct3};
            jal:            ALUSel  = ALUSel_add;
            jalr:           ALUSel  = ALUSel_add;
            Btype:          ALUSel  = {funct3[2:1] == 2'b00, 1'b0, funct3[2:1]};
            load:           ALUSel  = ALUSel_add;
            store:          ALUSel  = ALUSel_add;
            default:        ALUSel  = ALUSel_add;
        endcase
    
        case(opcode)
            lui:            PCSel  = PCSel_snpc;
            auipc:          PCSel  = PCSel_snpc;
            Itype_compute:  PCSel  = PCSel_snpc;
            Rtype:          PCSel  = PCSel_snpc;
            jal:            PCSel  = PCSel_jal;
            jalr:           PCSel  = PCSel_jalr;
            Btype:          PCSel  = funct3;
            load:           PCSel  = PCSel_snpc;
            store:          PCSel  = PCSel_snpc;
            default:        PCSel  = PCSel_snpc;
        endcase
    
        case(opcode)
            lui:            WBSel = WBSel_ALU;
            auipc:          WBSel = WBSel_ALU;
            Itype_compute:  WBSel = WBSel_ALU;
            Rtype:          WBSel = WBSel_ALU;
            jal:            WBSel = WBSel_ALU;
            jalr:           WBSel = WBSel_ALU;
            Btype:          WBSel = WBSel_ALU;
            load:           WBSel = WBSel_MEM;
            store:          WBSel = WBSel_ALU;
            default:        WBSel = WBSel_ALU;
        endcase
    
        case(opcode)
            lui:            MemWr    = NOT;
            auipc:          MemWr    = NOT;
            Itype_compute:  MemWr    = NOT;
            Rtype:          MemWr    = NOT;
            jal:            MemWr    = NOT;
            jalr:           MemWr    = NOT;
            Btype:          MemWr    = NOT;
            load:           MemWr    = NOT;
            store:          MemWr    = EN;
            default:        MemWr    = NOT;
        endcase
    end

endmodule
