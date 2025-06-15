`timescale 1ns / 1ps

module CPU_vivado_tb();

    // 测试台信号定义
    reg clk;
    reg clk_on;
    reg rst;
    wire enable;
    wire [2:0] which;
    wire [7:0] code;
    
    // PC相关信号
    wire [31:0] pc_value;
    wire [31:0] dnpc_value;
    
    // 指令相关信号
    wire [31:0] current_inst;
    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;
    wire [4:0] rs1, rs2, rd;
    
    // 控制信号
    wire [3:0] ALUSel;
    wire ASel;
    wire [1:0] BSel;
    wire [2:0] ImmSel;
    wire WBSel;
    wire [2:0] PCSel;
    wire MemWr;
    wire RegWr;
    
    // 数据通路信号
    wire [31:0] reg_data1, reg_data2;
    wire [31:0] ALU_A, ALU_B;
    wire [31:0] ALU_R;
    wire [31:0] imm;
    wire [31:0] wb_data;
    wire [31:0] mem_data;
    wire [31:0] a, b;
    
    // ALU状态信号
    wire less, zero;
    wire BJump;
    
    // 计数器
    integer cycle_count = 0;

    // 实例化被测模块
    CPU uut (
        .clk(clk),
        .clk_on(clk_on),
        .rst(rst),
        .enable(enable),
        .which(which),
        .code(code)
    );
    
    // 连接CPU内部信号用于观察
    // PC相关
    assign pc_value = uut.pc;
    assign dnpc_value = uut.dnpc;
    
    // 指令解码
    assign current_inst = uut.inst;
    assign opcode = uut.opcode;
    assign funct3 = uut.funct3;
    assign funct7 = uut.funct7;
    assign rs1 = uut.rs1;
    assign rs2 = uut.rs2;
    assign rd = uut.rd;
    
    // 控制信号
    assign ALUSel = uut.ALUSel;
    assign ASel = uut.ASel;
    assign BSel = uut.BSel;
    assign ImmSel = uut.ImmSel;
    assign WBSel = uut.WBSel;
    assign PCSel = uut.PCSel;
    assign MemWr = uut.MemWr;
    assign RegWr = uut.RegWr;
    
    // 数据通路
    assign reg_data1 = uut.reg_data1;
    assign reg_data2 = uut.reg_data2;
    assign ALU_A = uut.ALU_A;
    assign ALU_B = uut.ALU_B;
    assign ALU_R = uut.ALU_R;
    assign imm = uut.imm;
    assign wb_data = uut.wb_data;
    assign mem_data = uut.mem_data;
    assign a = uut.a;
    assign b = uut.b;
    
    // ALU状态
    assign less = uut.less;
    assign zero = uut.zero;
    assign BJump = uut.BJump;

    // 主时钟生成 (100MHz)
    always #5 clk = ~clk;

    // CPU执行时钟生成 (clk_on: 0,1,0,1...)
    always #50 clk_on = ~clk_on;
    
    // 周期计数
    always @(posedge clk_on) begin
        if (rst)
            cycle_count <= 0;
        else
            cycle_count <= cycle_count + 1;
    end

    // 主测试序列
    initial begin
        // 初始化信号
        clk = 0;
        clk_on = 0;
        rst = 1;
        
        $display("========================================");
        $display("    RV32I CPU 详细信号观察仿真开始");
        $display("    (使用新的Dnpc模块设计)");
        $display("========================================");
        
        // 保持复位状态 500ns
        #500;
        
        // 释放复位，开始执行COE中的指令
        rst = 0;
        $display("复位释放，开始执行COE指令 - 时间: %0t", $time);
        
        // 运行更长时间来执行COE中的所有指令
        // 增加到100us，足够执行大量指令
        #500000;  // 500us，观察更多指令执行
        
        $display("========================================");
        $display("仿真结束 - 总执行周期: %0d", cycle_count);
        $display("========================================");
        
        // 完成仿真
        $stop;
    end
    
    // 详细观察每个周期的所有关键信号
    always @(posedge clk_on) begin
        if (!rst) begin
            $display("=== 周期 %0d ===", cycle_count);
            $display("PC: 0x%08h -> 0x%08h", pc_value, dnpc_value);
            $display("指令: 0x%08h [op=0x%02h, f3=0x%01h, f7=0x%02h]", 
                     current_inst, opcode, funct3, funct7);
            $display("寄存器: rs1=x%0d, rs2=x%0d, rd=x%0d", rs1, rs2, rd);
            $display("控制信号: ALUSel=0x%01h, ASel=%b, BSel=0x%01h, PCSel=0x%01h", 
                     ALUSel, ASel, BSel, PCSel);
            $display("寄存器数据: A=0x%08h, B=0x%08h", a, b);
            $display("寄存器读出: RegData1=0x%08h, RegData2=0x%08h", reg_data1, reg_data2);
            $display("ALU: A=0x%08h, B=0x%08h, Result=0x%08h", ALU_A, ALU_B, ALU_R);
            $display("立即数: 0x%08h, 写回数据: 0x%08h", imm, wb_data);
            $display("ALU状态: less=%b, zero=%b, BJump=%b", less, zero, BJump);
            $display("存储器: MemData=0x%08h, MemWr=%b, RegWr=%b", mem_data, MemWr, RegWr);
            $display("显示: which=%0d, code=0x%02h", which, code);
            $display("----------------------------------------");
        end
    end
    
    // 检测PC跳转
    reg [31:0] prev_pc = 0;
    always @(posedge clk_on) begin
        if (!rst) begin
            if (pc_value != prev_pc) begin
                if (pc_value == prev_pc + 4) begin
                    $display("[PC顺序] 0x%08h -> 0x%08h (正常递增)", prev_pc, pc_value);
                end else begin
                    $display("[PC跳转] 0x%08h -> 0x%08h (跳转指令)", prev_pc, pc_value);
                end
            end
            prev_pc <= pc_value;
        end
    end
    
    // 检测指令类型
    always @(posedge clk_on) begin
        if (!rst && current_inst != 0) begin
            case(opcode)
                7'b0110011: $display("[指令类型] R-type: 寄存器-寄存器运算 (ADD/SUB/SLL/SLT/SRL/SRA/OR/AND)");
                7'b0010011: $display("[指令类型] I-type: 立即数运算 (ADDI/SLTI/SLTIU/XORI/ORI/ANDI/SLLI/SRLI/SRAI)");
                7'b0000011: $display("[指令类型] I-type: 加载指令 (LB/LH/LW/LBU/LHU)");
                7'b0100011: $display("[指令类型] S-type: 存储指令 (SB/SH/SW)");
                7'b1100011: $display("[指令类型] B-type: 分支指令 (BEQ/BNE/BLT/BGE/BLTU/BGEU)");
                7'b1101111: $display("[指令类型] J-type: JAL跳转");
                7'b1100111: $display("[指令类型] I-type: JALR跳转");
                7'b0110111: $display("[指令类型] U-type: LUI (加载高位立即数)");
                7'b0010111: $display("[指令类型] U-type: AUIPC (PC相对加载高位立即数)");
                default:    $display("[指令类型] 未知指令: opcode=0x%02h", opcode);
            endcase
        end
    end
    
    // 检测寄存器写入
    always @(posedge clk_on) begin
        if (!rst && RegWr && rd != 0) begin
            $display("[寄存器写入] x%0d <= 0x%08h", rd, wb_data);
        end
    end
    
    // 检测存储器访问
    always @(posedge clk_on) begin
        if (!rst && MemWr) begin
            $display("[存储器写入] Addr=0x%08h, Data=0x%08h", ALU_R, reg_data2);
        end
    end
    
    // 检测分支和跳转
    always @(posedge clk_on) begin
        if (!rst && BJump) begin
            $display("[分支跳转] 条件满足，跳转到: 0x%08h", dnpc_value);
        end
    end

endmodule 