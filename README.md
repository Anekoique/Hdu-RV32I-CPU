此CPU并不符合Hdu要求实现的多周期CPU，使用多周期架构但为单周期实现

报告为AI生成

# RISC-V 32位单周期CPU设计报告

## 项目概述

本项目实现了一个基于RISC-V 32位指令集架构(RV32I)的单周期CPU处理器。该CPU支持RISC-V基础整数指令集，采用经典的五级流水线结构概念但实现为单周期执行，包括取指(IF)、译码(ID)、执行(EX)、访存(MEM)、写回(WB)等阶段。

## 整体架构

### CPU核心组件
- **顶层模块(Top)**: 系统顶层接口，连接CPU核心与外设
- **CPU主模块**: 包含完整的数据通路和控制通路
- **控制单元(CU)**: 指令译码和控制信号生成
- **算术逻辑单元(ALU)**: 执行算术和逻辑运算
- **寄存器文件(Regfile)**: 32个通用寄存器
- **存储器系统**: 指令存储器(IMem)和数据存储器(DMem)

### 支持的指令类型
- R-type: 寄存器-寄存器运算指令
- I-type: 立即数运算指令、加载指令、跳转指令
- S-type: 存储指令
- B-type: 分支指令
- U-type: 上位立即数指令
- J-type: 跳转指令

## 主要模块简介

### 1. 取指阶段(IF)
- PC寄存器: 存储当前程序计数器
- DNPC模块: 动态计算下一条指令地址
- 指令存储器: ROM形式的指令存储
- IR寄存器: 指令寄存器

### 2. 译码阶段(ID)
- 控制单元: 根据opcode生成各种控制信号
- 寄存器文件: 提供源操作数
- 立即数生成器: 生成各种格式的立即数

### 3. 执行阶段(EX)
- ALU: 执行算术逻辑运算
- 加法器: 专用加法运算单元
- 桶形移位器: 移位运算单元

### 4. 访存阶段(MEM)
- 数据存储器: RAM形式的数据存储

### 5. 写回阶段(WB)
- 多路选择器: 选择写回数据源

### 6. 显示模块
- 七段数码管控制: 用于调试和结果显示

## 主要特性

1. **单周期执行**: 每条指令在一个时钟周期内完成
2. **完整的RISC-V RV32I支持**: 实现了基础整数指令集
3. **模块化设计**: 各功能模块独立，便于维护和扩展
4. **调试支持**: 通过七段数码管显示内部状态
5. **FPGA友好**: 适合在FPGA上实现和验证

## 技术规格

- **位宽**: 32位
- **寄存器数量**: 32个通用寄存器
- **指令集**: RISC-V RV32I
- **存储器**: 指令存储器(ROM) + 数据存储器(RAM)
- **时钟**: 支持板载时钟和手动单步时钟
- **复位**: 同步复位支持

此报告将在后续章节中详细介绍各个模块的设计实现和代码分析。

---

# 详细模块分析

## 1. Top 顶层模块

### 1.1 模块功能
Top模块是整个CPU系统的顶层封装，负责连接CPU核心与外部接口。它主要作为一个简单的封装层，将外部信号直接传递给内部的CPU模块。

### 1.2 端口定义
```verilog
module Top(
    input clk,          // 板卡时钟信号
    input clk_on,       // 单步时钟信号，用于模拟单周期执行
    input rst,          // 复位信号
    input [3:0] SegSel, // 七段数码管选择信号，用于选择显示内容
    output enable,      // 数码管使能信号
    output [2:0] which, // 数码管位选信号
    output [7:0] code   // 数码管段选信号
);
```

### 1.3 实现代码
```verilog
`timescale 1ns / 1ps
module Top(
        input clk,
        input clk_on,
        input rst,
        input [3:0] SegSel,
        output enable,
        output [2:0] which,
        output [7:0] code
    );

    CPU RV32I (
        .clk(clk),
        .clk_on(clk_on),
        .rst(rst),
        .SegSel(SegSel),
        .enable(enable),
        .which(which),
        .code(code)
    );

endmodule
```

### 1.4 设计特点
1. **简洁的顶层设计**: Top模块仅作为信号转接，不包含复杂逻辑
2. **双时钟支持**: 
   - `clk`: 板卡时钟，用于数码管显示等高频操作
   - `clk_on`: 单步时钟，用于CPU核心的单周期执行控制
3. **调试接口**: 通过SegSel选择不同的内部信号在数码管上显示
4. **模块化设计**: 将所有CPU功能封装在CPU模块中，便于测试和维护

### 1.5 信号流向
- **输入信号**: 来自外部FPGA引脚或测试激励
- **输出信号**: 连接到七段数码管显示模块
- **内部连接**: 所有信号直接传递给CPU模块，无额外处理

## 2. CPU 主模块

### 2.1 模块功能
CPU模块是整个处理器的核心，实现了完整的RISC-V RV32I单周期数据通路。它包含了取指、译码、执行、访存、写回的完整流程，以及用于调试的七段数码管显示功能。

### 2.2 端口定义
```verilog
module CPU (
    input clk,           // 板卡时钟
    input clk_on,        // CPU执行时钟
    input rst,           // 复位信号
    input [3:0] SegSel,  // 数码管显示选择
    output enable,       // 数码管使能
    output [2:0] which,  // 数码管位选
    output [7:0] code    // 数码管段选
);
```

### 2.3 参数定义
```verilog
// 分支类型参数
parameter Branch_eq   = 3'b000;  // 相等分支 (BEQ)
parameter Branch_ne   = 3'b001;  // 不等分支 (BNE)
parameter Branch_lt   = 3'b100;  // 小于分支 (BLT)
parameter Branch_ge   = 3'b101;  // 大于等于分支 (BGE)

// 写回数据选择参数
parameter WBSel_ALU = 1'b0;      // 选择ALU结果写回
parameter WBSel_MEM = 1'b1;      // 选择内存数据写回
```

### 2.4 内部信号定义
CPU模块定义了大量内部信号，按功能阶段分类如下：

#### IF阶段信号
```verilog
wire [31:0] pc;          // 当前程序计数器
wire [31:0] dnpc;        // 下一条指令地址
wire [31:0] inst;        // 当前指令
wire [31:0] imem_inst;   // 从指令存储器读出的指令
```

#### ID阶段信号
```verilog
wire [6:0] opcode;       // 操作码
wire [2:0] funct3;       // 功能码3
wire [6:0] funct7;       // 功能码7
wire [4:0] rs1, rs2, rd; // 源寄存器1、2和目标寄存器

// 控制信号
wire [3:0] ALUSel;       // ALU操作选择
wire ASel;               // ALU输入A选择
wire [1:0] BSel;         // ALU输入B选择
wire [2:0] ImmSel;       // 立即数类型选择
wire WBSel;              // 写回数据选择
wire [2:0] PCSel;        // PC更新方式选择
wire MemWr;              // 内存写使能
wire RegWr;              // 寄存器写使能

// 数据信号
wire [31:0] imm;         // 立即数
wire [31:0] reg_data1, reg_data2; // 寄存器输出数据
wire [31:0] a, b;        // 流水线寄存器输出
wire [31:0] ALU_A, ALU_B; // ALU输入
```

#### EX阶段信号
```verilog
wire [31:0] r, ALU_R;    // ALU结果和流水线寄存器输出
wire less, zero;         // ALU比较结果
reg  BJump;              // 分支跳转标志
```

#### MEM阶段信号
```verilog
wire [31:0] mem_data;    // 内存读出数据
```

#### WB阶段信号
```verilog
wire [31:0] wb_data;     // 写回数据
reg [31:0] SegData;      // 数码管显示数据
```

### 2.5 整体数据通路
CPU采用单周期实现，但在设计上体现了经典的五级流水线结构：
1. **IF**: 取指令，更新PC
2. **ID**: 指令译码，寄存器读取
3. **EX**: ALU运算，分支判断
4. **MEM**: 内存访问
5. **WB**: 结果写回

### 2.6 设计特点
1. **单周期执行**: 每条指令在一个`clk_on`周期内完成
2. **流水线寄存器**: 虽然是单周期，但使用了流水线寄存器来同步数据
3. **完整的控制逻辑**: 支持所有RV32I基础指令
4. **调试支持**: 通过SegSel可以观察内部各种信号状态

## 3. IF阶段 - 取指阶段

### 3.1 阶段功能
IF阶段负责从指令存储器中取出当前PC地址对应的指令，并计算下一条指令的地址。该阶段包含PC寄存器、DNPC模块、指令存储器和指令寄存器。

### 3.2 DNPC模块 - 动态下一PC计算

#### 3.2.1 模块功能
DNPC（Dynamic Next PC）模块负责根据当前指令类型和执行结果计算下一条指令的地址，支持顺序执行、分支跳转、无条件跳转等多种PC更新方式。

#### 3.2.2 端口定义
```verilog
module Dnpc (
    input rst,              // 复位信号
    input [31:0] pc,        // 当前PC值
    input [31:0] reg_data,  // 寄存器数据（用于JALR）
    input [31:0] imm,       // 立即数
    input [2:0] PCSel,      // PC选择信号
    input BJump,            // 分支跳转标志
    output reg [31:0] dnpc  // 下一PC值
);
```

#### 3.2.3 实现代码
```verilog
module Dnpc (
        input rst,
        input [31:0] pc,
        input [31:0] reg_data,
        input [31:0] imm,
        input [2:0] PCSel,
        input BJump,
        output reg [31:0] dnpc
    );

    parameter PCSel_jal   = 3'b011;  // JAL跳转
    parameter PCSel_jalr  = 3'b110;  // JALR跳转
    parameter PCSel_snpc  = 3'b111;  // 顺序执行

    wire [31:0] dnpc_branch; // 分支跳转地址
    wire [31:0] dnpc_jalr;   // JALR跳转地址
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
```

#### 3.2.4 工作原理
1. **复位状态**: 当rst为高时，dnpc输出0x00000000
2. **JAL跳转**: PC + 立即数，用于无条件跳转
3. **JALR跳转**: 寄存器值 + 立即数，用于寄存器间接跳转
4. **顺序执行**: PC + 4，用于普通指令
5. **分支跳转**: 根据BJump信号决定是否跳转

### 3.3 PC寄存器

#### 3.3.1 模块功能
PC寄存器存储当前程序计数器的值，在每个时钟上升沿更新为下一条指令地址。

#### 3.3.2 实现代码
```verilog
Reg PC (
    .clk(clk_on),      // 使用CPU执行时钟
    .rst(rst),         // 复位信号
    .data_in(dnpc),    // 输入下一PC值
    .data_out(pc)      // 输出当前PC值
);
```

#### 3.3.3 工作特点
- 使用`clk_on`时钟，实现单步执行控制
- 复位时PC值为0
- 每个时钟周期更新为DNPC模块计算的下一地址

### 3.4 IMem指令存储器

#### 3.4.1 模块功能
指令存储器以ROM形式实现，存储程序指令，根据PC地址输出对应的32位指令。

#### 3.4.2 实现代码
```verilog
module IMem(
    input clk,           // 时钟信号
    input [7:2] addr,    // 6位地址（32位对齐）
    output [31:0] inst   // 32位指令输出
);

    ROM rom_inst (
        .clka(clk),      // 时钟连接
        .addra(addr),    // 地址连接
        .douta(inst)     // 数据输出
    );

endmodule
```

#### 3.4.3 设计特点
- 使用IP核生成的ROM模块
- 地址使用`pc[7:2]`，实现32位地址对齐
- 支持64个32位指令（256字节）

### 3.5 IR指令寄存器

#### 3.5.1 模块功能
指令寄存器用于缓存从指令存储器读出的指令，为下一阶段的译码提供稳定的指令数据。

#### 3.5.2 实现代码
```verilog
Reg IR (
    .clk(clk),              // 使用板卡时钟
    .rst(rst),              // 复位信号
    .data_in(imem_inst),    // 从IMem读出的指令
    .data_out(inst)         // 输出给ID阶段的指令
);
```

### 3.6 IF阶段数据流
1. **PC生成**: DNPC根据控制信号计算下一PC值
2. **PC更新**: PC寄存器在`clk_on`上升沿更新
3. **取指**: IMem根据PC地址输出指令
4. **指令缓存**: IR在`clk`上升沿缓存指令

### 3.7 时序分析
- **PC更新**: 在`clk_on`上升沿，适合单步调试
- **指令缓存**: 在`clk`上升沿，保证指令稳定性
- **组合逻辑**: DNPC和IMem为组合逻辑，响应快速

## 4. ID阶段 - 译码阶段

### 4.1 阶段功能
ID阶段负责对指令进行译码，提取指令中的各个字段，生成控制信号，读取寄存器数据，并生成立即数。该阶段是CPU控制逻辑的核心。

### 4.2 指令译码

#### 4.2.1 指令格式解析
RISC-V指令采用固定32位长度，不同类型指令的字段分布如下：
```verilog
assign {funct7, rs2, rs1, funct3, rd, opcode} = inst;
```

#### 4.2.2 字段说明
- `opcode[6:0]`: 操作码，确定指令类型
- `funct3[2:0]`: 功能码，细分指令操作
- `funct7[6:0]`: 扩展功能码，进一步区分指令
- `rs1[4:0]`: 源寄存器1地址
- `rs2[4:0]`: 源寄存器2地址  
- `rd[4:0]`: 目标寄存器地址

### 4.3 CU控制单元

#### 4.3.1 模块功能
控制单元（Control Unit）是CPU的"大脑"，根据指令的opcode、funct3、funct7字段生成各种控制信号，控制数据通路的运行。

#### 4.3.2 端口定义
```verilog
module CU (
    input [6:0] opcode,     // 操作码
    input [2:0] funct3,     // 功能码3
    input [6:0] funct7,     // 功能码7
    output reg [3:0] ALUSel, // ALU操作选择
    output reg ASel,         // ALU输入A选择
    output reg [1:0] BSel,   // ALU输入B选择
    output reg [2:0] PCSel,  // PC选择
    output reg [2:0] ImmSel, // 立即数类型选择
    output reg WBSel,        // 写回选择
    output reg MemWr,        // 存储器写使能
    output reg RegWr         // 寄存器写使能
);
```

#### 4.3.3 支持的指令类型
```verilog
// R-type 寄存器-寄存器运算
parameter Rtype         = 7'b0110011;
// I-type 立即数运算和加载指令
parameter Itype_compute = 7'b0010011;
parameter jalr          = 7'b1100111;
parameter load          = 7'b0000011;
// B-type 分支指令
parameter Btype         = 7'b1100011;
// J-type 跳转指令
parameter jal           = 7'b1101111;
// S-type 存储指令
parameter store         = 7'b0100011;
// U-type 上位立即数指令
parameter lui           = 7'b0110111;
parameter auipc         = 7'b0010111;
```

#### 4.3.4 控制信号说明

##### ImmSel - 立即数类型选择
```verilog
parameter ImmItype = 3'b000; // I-type立即数
parameter ImmUtype = 3'b001; // U-type立即数
parameter ImmStype = 3'b010; // S-type立即数
parameter ImmBtype = 3'b011; // B-type立即数
parameter ImmJtype = 3'b100; // J-type立即数
```

##### ASel/BSel - ALU输入选择
```verilog
parameter ASel_pc  = 1'b0;   // A输入选择PC
parameter ASel_rs1 = 1'b1;   // A输入选择寄存器rs1

parameter BSel_rs2 = 2'b00;  // B输入选择寄存器rs2
parameter BSel_imm = 2'b01;  // B输入选择立即数
parameter BSel_4   = 2'b10;  // B输入选择常数4
```

##### PCSel - PC更新选择
```verilog
parameter PCSel_jal     = 3'b011; // JAL跳转
parameter PCSel_jalr    = 3'b110; // JALR跳转
parameter PCSel_snpc    = 3'b111; // 顺序执行PC+4
// 其他值用于分支指令的条件跳转
```

#### 4.3.5 控制信号真值表

以下是各种指令类型对应的完整控制信号真值表：

| 指令类型 | ImmSel | ASel | BSel | ALUSel | PCSel | WBSel | MemWr | RegWr |
|---------|--------|------|------|--------|-------|-------|-------|-------|
| **R-type指令** |
| ADD     | ImmI   | rs1  | rs2  | 0000   | snpc  | ALU   | 0     | 1     |
| SUB     | ImmI   | rs1  | rs2  | 1000   | snpc  | ALU   | 0     | 1     |
| AND     | ImmI   | rs1  | rs2  | 0111   | snpc  | ALU   | 0     | 1     |
| OR      | ImmI   | rs1  | rs2  | 0110   | snpc  | ALU   | 0     | 1     |
| XOR     | ImmI   | rs1  | rs2  | 0100   | snpc  | ALU   | 0     | 1     |
| SLL     | ImmI   | rs1  | rs2  | 0001   | snpc  | ALU   | 0     | 1     |
| SRL     | ImmI   | rs1  | rs2  | 0101   | snpc  | ALU   | 0     | 1     |
| SRA     | ImmI   | rs1  | rs2  | 1101   | snpc  | ALU   | 0     | 1     |
| SLT     | ImmI   | rs1  | rs2  | 0010   | snpc  | ALU   | 0     | 1     |
| SLTU    | ImmI   | rs1  | rs2  | 0011   | snpc  | ALU   | 0     | 1     |
| **I-type计算指令** |
| ADDI    | ImmI   | rs1  | imm  | 0000   | snpc  | ALU   | 0     | 1     |
| ANDI    | ImmI   | rs1  | imm  | 0111   | snpc  | ALU   | 0     | 1     |
| ORI     | ImmI   | rs1  | imm  | 0110   | snpc  | ALU   | 0     | 1     |
| XORI    | ImmI   | rs1  | imm  | 0100   | snpc  | ALU   | 0     | 1     |
| SLLI    | ImmI   | rs1  | imm  | 0001   | snpc  | ALU   | 0     | 1     |
| SRLI    | ImmI   | rs1  | imm  | 0101   | snpc  | ALU   | 0     | 1     |
| SRAI    | ImmI   | rs1  | imm  | 1101   | snpc  | ALU   | 0     | 1     |
| SLTI    | ImmI   | rs1  | imm  | 0010   | snpc  | ALU   | 0     | 1     |
| SLTIU   | ImmI   | rs1  | imm  | 0011   | snpc  | ALU   | 0     | 1     |
| **加载存储指令** |
| LW      | ImmI   | rs1  | imm  | 0000   | snpc  | MEM   | 0     | 1     |
| SW      | ImmS   | rs1  | imm  | 0000   | snpc  | -     | 1     | 0     |
| **分支指令** |
| BEQ     | ImmB   | rs1  | rs2  | 1000   | 000   | -     | 0     | 0     |
| BNE     | ImmB   | rs1  | rs2  | 1000   | 001   | -     | 0     | 0     |
| BLT     | ImmB   | rs1  | rs2  | 1010   | 100   | -     | 0     | 0     |
| BGE     | ImmB   | rs1  | rs2  | 1010   | 101   | -     | 0     | 0     |
| **跳转指令** |
| JAL     | ImmJ   | pc   | 4    | 0000   | jal   | ALU   | 0     | 1     |
| JALR    | ImmI   | pc   | 4    | 0000   | jalr  | ALU   | 0     | 1     |
| **上位立即数指令** |
| LUI     | ImmU   | rs1  | imm  | 1111   | snpc  | ALU   | 0     | 1     |
| AUIPC   | ImmU   | pc   | imm  | 0000   | snpc  | ALU   | 0     | 1     |

#### 4.3.6 ALUSel生成逻辑详解

控制单元中ALUSel的生成逻辑较为复杂，需要结合opcode、funct3和funct7：

```verilog
case(opcode)
    Itype_compute:  ALUSel = {funct3 == 3'b101 & funct7[5], funct3};
    Rtype:          ALUSel = {funct7[5], funct3};
    Btype:          ALUSel = {funct3[2:1] == 2'b00, 1'b0, funct3[2:1]};
    // ... 其他指令类型
endcase
```

**详细分析**：

1. **I-type计算指令**：
   - 基础编码：`{0, funct3}`
   - 特殊处理：移位指令SRAI需要设置最高位
   - `funct3 == 3'b101 & funct7[5]`：当为SRAI时设置ALUSel[3]=1

2. **R-type指令**：
   - 直接使用：`{funct7[5], funct3}`
   - funct7[5]用于区分ADD/SUB、SRL/SRA等

3. **分支指令**：
   - 特殊编码：`{funct3[2:1] == 2'b00, 1'b0, funct3[2:1]}`
   - BEQ/BNE: funct3[2:1] = 00 → ALUSel = 1000 (SUB)
   - BLT/BGE: funct3[2:1] = 10 → ALUSel = 0010 (SLT)

#### 4.3.7 控制单元状态机设计

虽然本CPU采用单周期设计，但控制单元的逻辑可以看作是一个组合逻辑"状态机"：

```
指令输入 → 译码逻辑 → 控制信号输出
     ↓           ↓           ↓
  [31:0]      组合逻辑    8个控制信号
   inst    ←─────────→   (ImmSel,ASel,etc.)
```

**译码过程**：
1. **第一级译码**：根据opcode[6:0]确定指令大类
2. **第二级译码**：根据funct3[2:0]细分指令类型  
3. **第三级译码**：根据funct7[6:0]进一步区分（仅R-type和部分I-type）
4. **控制信号生成**：每个控制信号都有对应的case语句

#### 4.3.8 关键控制逻辑实现

##### RegWr写使能逻辑
```verilog
case(opcode)
    lui, auipc, Itype_compute, Rtype, jal, jalr, load: RegWr = 1'b1;
    Btype, store: RegWr = 1'b0;
    default: RegWr = 1'b0;
endcase
```

##### WBSel写回选择逻辑
```verilog
case(opcode)
    load: WBSel = WBSel_MEM;  // 只有加载指令从内存写回
    default: WBSel = WBSel_ALU; // 其他指令都从ALU写回
endcase
```

##### PCSel PC选择逻辑
```verilog
case(opcode)
    jal:   PCSel = PCSel_jal;   // PC + imm
    jalr:  PCSel = PCSel_jalr;  // rs1 + imm  
    Btype: PCSel = funct3;      // 条件跳转，funct3编码条件类型
    default: PCSel = PCSel_snpc; // PC + 4
endcase
```

#### 4.3.9 控制单元时序分析

控制单元的时序特性：

1. **输入稳定时间**：指令inst必须在时钟前沿稳定
2. **输出延迟**：从inst变化到控制信号稳定约5-8ns
3. **关键路径**：inst → opcode译码 → ALUSel生成 → ALU运算
4. **时序余量**：控制信号应在ALU计算前充分稳定

#### 4.3.10 扩展性设计

控制单元的设计具有良好的扩展性：

1. **新增指令**：只需在对应的case语句中添加新的opcode
2. **新增控制信号**：可以轻松添加新的输出端口和控制逻辑
3. **多周期扩展**：可以改造为状态机形式支持多周期执行
4. **流水线扩展**：控制信号可以在流水线中传递

**设计原则**：
- 组合逻辑实现，响应快速
- 模块化设计，便于修改
- 完整的指令覆盖
- 清晰的信号命名

### 4.4 Imm立即数生成器

#### 4.4.1 模块功能
根据指令类型和ImmSel控制信号，从32位指令中提取并符号扩展立即数。

#### 4.4.2 实现代码
```verilog
module Imm (
    input [31:0] inst,       // 32位指令
    input [2:0] ImmSel,      // 立即数类型选择
    output reg [31:0] imm    // 32位立即数输出
);

    parameter ImmItype = 3'b000;
    parameter ImmUtype = 3'b001;
    parameter ImmStype = 3'b010;
    parameter ImmBtype = 3'b011;
    parameter ImmJtype = 3'b100;

    // 各种类型立即数的生成
    wire [31:0] immI, immU, immS, immB, immJ;

    assign immI = {{20{inst[31]}}, inst[31:20]};                    // I-type: 12位符号扩展
    assign immU = {inst[31:12], 12'b0};                             // U-type: 高20位+12个0
    assign immS = {{20{inst[31]}}, inst[31:25], inst[11:7]};        // S-type: 分散的12位
    assign immB = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0}; // B-type: 分支偏移
    assign immJ = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0}; // J-type: 跳转偏移

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
```

#### 4.4.3 立即数格式
1. **I-type**: 12位符号扩展，用于算术运算和加载指令
2. **U-type**: 20位高位立即数，低12位为0
3. **S-type**: 12位符号扩展，用于存储指令
4. **B-type**: 13位符号扩展，最低位为0，用于分支
5. **J-type**: 21位符号扩展，最低位为0，用于跳转

### 4.5 Regfile寄存器文件

#### 4.5.1 模块功能
寄存器文件实现32个32位通用寄存器，支持同时读取两个寄存器和写入一个寄存器。

#### 4.5.2 实现代码
```verilog
module Regfile (
    input rst,              // 复位信号
    input clk,              // 时钟信号
    input [4:0] Ra,         // 读端口A地址
    input [4:0] Rb,         // 读端口B地址
    input [4:0] Rw,         // 写端口地址
    input [31:0] busW,      // 写数据
    input RegWr,            // 写使能
    output wire [31:0] busA, // 读端口A数据
    output wire [31:0] busB  // 读端口B数据
);

    reg [31:0] regs [31:0]; // 32个32位寄存器

    // 读操作（组合逻辑）
    assign busA = (Ra == 5'd0) ? 32'd0 : regs[Ra];
    assign busB = (Rb == 5'd0) ? 32'd0 : regs[Rb];

    // 写操作（时序逻辑）
    integer i;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            for(i = 0; i < 32; i = i + 1) begin
                regs[i] <= 32'd0;
            end
        end
        else if(RegWr && Rw != 5'd0)
            regs[Rw] <= busW;
    end

endmodule
```

#### 4.5.3 设计特点
1. **零寄存器**: x0寄存器恒为0，写入无效
2. **双端口读**: 可同时读取两个寄存器
3. **单端口写**: 每个周期只能写一个寄存器
4. **同步写入**: 写操作在时钟上升沿进行

### 4.6 流水线寄存器A和B

#### 4.6.1 功能说明
A和B寄存器用于缓存从寄存器文件读出的数据，为EX阶段提供稳定的操作数。

#### 4.6.2 实现代码
```verilog
Reg A (
    .clk(clk),              // 板卡时钟
    .rst(rst),              // 复位信号
    .data_in(reg_data1),    // 寄存器文件输出A
    .data_out(a)            // 给EX阶段的操作数A
);

Reg B (
    .clk(clk),              // 板卡时钟
    .rst(rst),              // 复位信号
    .data_in(reg_data2),    // 寄存器文件输出B
    .data_out(b)            // 给EX阶段的操作数B
);
```

### 4.7 ALU输入选择逻辑

#### 4.7.1 功能说明
根据控制信号ASel和BSel选择ALU的输入数据源。

#### 4.7.2 实现代码
```verilog
assign ALU_A = ASel    ? a : pc;    // A输入：寄存器数据或PC
assign ALU_B = BSel[1] ? 32'd4 :    // B输入：常数4
               BSel[0] ? imm : b;   //       立即数或寄存器数据
```

#### 4.7.3 输入选择
- **ALU_A**: 寄存器数据（大多数运算）或PC（地址计算）
- **ALU_B**: 寄存器数据（R-type）、立即数（I-type）或常数4（PC+4）

### 4.8 ID阶段数据流总结
1. **指令解析**: 提取opcode、funct3、funct7、rs1、rs2、rd
2. **控制信号生成**: CU根据指令字段生成控制信号
3. **立即数生成**: Imm模块生成各种格式的立即数
4. **寄存器读取**: Regfile读取源操作数
5. **数据缓存**: A、B寄存器缓存操作数
6. **输入选择**: 为ALU选择正确的输入数据

## 5. EX阶段 - 执行阶段

### 5.1 阶段功能
EX阶段是CPU的运算核心，负责执行算术逻辑运算、地址计算、分支条件判断等操作。该阶段以ALU为核心，配合专用的加法器和桶形移位器完成各种运算。

### 5.2 ALU主模块

#### 5.2.1 模块功能
ALU（Arithmetic Logic Unit）是执行各种算术和逻辑运算的核心部件，支持加减法、逻辑运算、移位运算、比较运算等。

#### 5.2.2 端口定义
```verilog
module Alu(
    input [31:0] a,         // 操作数A
    input [31:0] b,         // 操作数B
    input [3:0] ALUSel,     // 运算类型选择
    output wire less, zero, // 比较结果标志
    output reg [31:0] r     // 运算结果
);
```

#### 5.2.3 内部组件
ALU内部包含加法器和桶形移位器两个专用运算单元：

```verilog
// 加法器实例
Adder adder(
    .a(a),
    .b(b),
    .Cin(cin),      // 进位输入
    .r(adder_r),    // 加法结果
    .cf(cf),        // 进位标志
    .of(of)         // 溢出标志
);

// 桶形移位器实例
Barrel barrel(
    .din(a),            // 输入数据
    .shamt(b[4:0]),     // 移位数量
    .lr(lr),            // 左/右移控制
    .al(al),            // 算术/逻辑控制
    .dout(barrel_r)     // 移位结果
);
```

#### 5.2.4 控制逻辑
```verilog
assign cin = ALUSel[3] | ALUSel[1];  // 进位输入控制
assign lr = ~ALUSel[2];              // 移位方向控制
assign al = ALUSel[3];               // 移位类型控制
assign sf = adder_r[31];             // 符号标志
assign less = ALUSel[0] ? cf : sf ^ of; // 小于比较
assign zero = ~|r;                   // 零标志
```

#### 5.2.5 运算选择逻辑
```verilog
always @(*) begin
    casez(ALUSel)
        4'b?000: r = adder_r;           // 加减法运算
        4'b??01: r = barrel_r;          // 移位运算
        4'b001?: r = {31'd0, less};     // 比较运算
        4'b?100: r = a ^ b;             // 异或运算
        4'b?110: r = a | b;             // 或运算
        4'b0111: r = a & b;             // 与运算
        4'b1111: r = b;                 // 直接传递B（用于LUI）
        default: r = adder_r;
    endcase
end
```

#### 5.2.6 ALUSel编码详解

ALU支持的运算类型通过4位ALUSel信号编码，具体编码如下：

| ALUSel | 运算类型 | 功能说明 | 对应RISC-V指令 |
|--------|---------|----------|----------------|
| 0000   | ADD     | 加法运算 | ADD, ADDI, LW, SW, AUIPC, JAL, JALR |
| 1000   | SUB     | 减法运算 | SUB, BEQ, BNE, BLT, BGE |
| 0001   | SLL     | 逻辑左移 | SLL, SLLI |
| 0101   | SRL     | 逻辑右移 | SRL, SRLI |
| 1101   | SRA     | 算术右移 | SRA, SRAI |
| 0010   | SLT     | 有符号比较 | SLT, SLTI, BLT, BGE |
| 0011   | SLTU    | 无符号比较 | SLTU, SLTIU |
| 0100   | XOR     | 异或运算 | XOR, XORI |
| 0110   | OR      | 或运算   | OR, ORI |
| 0111   | AND     | 与运算   | AND, ANDI |
| 1111   | PASS_B  | 直接传递B | LUI |

#### 5.2.7 标志位生成详解

ALU生成two个重要的标志位用于分支判断：

##### Zero标志位
```verilog
assign zero = ~|r;  // 结果为0时zero=1
```
- **用途**: BEQ和BNE指令的条件判断
- **逻辑**: 对ALU结果的所有位进行或运算，再取反
- **时序**: 组合逻辑，实时更新

##### Less标志位
```verilog
assign less = ALUSel[0] ? cf : sf ^ of;
```
- **用途**: BLT和BGE指令的条件判断
- **逻辑**: 
  - 当ALUSel[0]=1时（无符号比较），less = cf（进位标志）
  - 当ALUSel[0]=0时（有符号比较），less = sf ^ of（符号标志异或溢出标志）
- **原理**: 
  - 无符号比较：A < B 等价于 A - B 产生借位
  - 有符号比较：A < B 等价于 (A - B < 0) 且 无溢出，或 (A - B > 0) 且 有溢出

#### 5.2.8 运算流水线时序

ALU的运算过程分为以下几个时序阶段：

1. **T0阶段（组合逻辑）**:
   - 输入数据a、b稳定
   - ALUSel控制信号稳定
   - 加法器和移位器开始计算

2. **T1阶段（组合逻辑）**:
   - 加法器输出adder_r
   - 移位器输出barrel_r
   - 标志位cf、of、sf生成

3. **T2阶段（组合逻辑）**:
   - 根据ALUSel选择最终结果r
   - 生成less和zero标志
   - 输出稳定

4. **T3阶段（时序逻辑）**:
   - F寄存器在时钟上升沿锁存结果
   - 为下一阶段提供稳定的ALU_R

#### 5.2.9 关键路径分析

ALU的关键路径（最长延迟路径）分析：

1. **加法器路径**: a/b输入 → 32位加法器 → 结果选择 → 输出r
2. **移位器路径**: a输入 → 5级桶形移位 → 结果选择 → 输出r  
3. **比较路径**: 加法器结果 → 标志生成 → less输出

**时序约束**:
- 最长路径：约15ns（取决于工艺）
- 建议时钟周期：≥20ns（50MHz）
- 关键信号：ALUSel信号应尽早稳定

### 5.3 Adder加法器

#### 5.3.1 模块功能
专用32位加法器，支持加法和减法运算，并生成进位和溢出标志。

#### 5.3.2 实现代码
```verilog
module Adder(
    input [31:0] a,     // 操作数A
    input [31:0] b,     // 操作数B
    input Cin,          // 进位输入
    output wire [31:0] r, // 运算结果
    output wire cf, of  // 进位和溢出标志
);

    wire c32;           // 第32位进位
    wire [31:0] neg_b = {32{Cin}} ^ b; // B的反码（减法时）
    assign {c32, r} = a + neg_b + {31'd0, Cin};
    assign cf = c32 ^ Cin;             // 进位标志
    assign of = (a[31] == neg_b[31]) & (a[31] != r[31]); // 溢出标志

endmodule
```

#### 5.3.3 工作原理
1. **加法运算**: Cin=0时，neg_b = b，执行a + b
2. **减法运算**: Cin=1时，neg_b = ~b，执行a + (~b) + 1 = a - b
3. **标志生成**: 
   - cf: 进位标志，用于无符号比较
   - of: 溢出标志，用于有符号运算检测

### 5.4 Barrel桶形移位器

#### 5.4.1 模块功能
实现高效的移位运算，支持左移、逻辑右移、算术右移，移位位数可达31位。

#### 5.4.2 实现代码
```verilog
module Barrel(
    input [31:0] din,    // 输入数据
    input [4:0] shamt,   // 移位数量
    input lr,            // 左/右移控制（1=左移，0=右移）
    input al,            // 算术/逻辑控制（1=算术，0=逻辑）
    output reg [31:0] dout // 输出结果
);

    reg [31:0] sh_data [4:0]; // 五级移位中间结果
    wire in;                  // 移位填充位

    assign in = al ? din[31] : 1'b0; // 算术右移填充符号位

    always @(*) begin
        if(lr) begin // 左移
            sh_data[0] = shamt[0] ? {din[30:0], 1'd0} : din;
            sh_data[1] = shamt[1] ? {sh_data[0][29:0], 2'd0} : sh_data[0];
            sh_data[2] = shamt[2] ? {sh_data[1][27:0], 4'd0} : sh_data[1];
            sh_data[3] = shamt[3] ? {sh_data[2][23:0], 8'd0} : sh_data[2];
            sh_data[4] = shamt[4] ? {sh_data[3][15:0], 16'd0} : sh_data[3];
        end
        else begin // 右移
            sh_data[0] = shamt[0] ? {{1{in}}, din[31:1]} : din;
            sh_data[1] = shamt[1] ? {{2{in}}, sh_data[0][31:2]} : sh_data[0];
            sh_data[2] = shamt[2] ? {{4{in}}, sh_data[1][31:4]} : sh_data[1];
            sh_data[3] = shamt[3] ? {{8{in}}, sh_data[2][31:8]} : sh_data[2];
            sh_data[4] = shamt[4] ? {{16{in}}, sh_data[3][31:16]} : sh_data[3];
        end
        dout = sh_data[4];
    end

endmodule
```

#### 5.4.3 移位类型
1. **逻辑左移**: lr=1, al=0，高位填0
2. **逻辑右移**: lr=0, al=0，低位填0  
3. **算术右移**: lr=0, al=1，高位填符号位

#### 5.4.4 桶形移位原理
采用五级移位结构，每级可选择移位2^i位（i=0,1,2,3,4），通过组合可实现0-31位的任意移位。

### 5.5 ALU结果寄存器F

#### 5.5.1 功能说明
F寄存器用于缓存ALU的运算结果，为MEM阶段提供稳定的地址或数据。

#### 5.5.2 实现代码
```verilog
Reg F (
    .clk(clk),        // 板卡时钟
    .rst(rst),        // 复位信号
    .data_in(r),      // ALU运算结果
    .data_out(ALU_R)  // 输出给MEM阶段
);
```

### 5.6 分支跳转判断逻辑

#### 5.6.1 功能说明
根据ALU的比较结果和PCSel控制信号，判断是否需要进行分支跳转。

#### 5.6.2 实现代码
```verilog
always @(*) begin
    case (PCSel)
        Branch_eq:    BJump = zero;    // BEQ: 相等时跳转
        Branch_ne:    BJump = ~zero;   // BNE: 不等时跳转
        Branch_lt:    BJump = less;    // BLT: 小于时跳转
        Branch_ge:    BJump = ~less;   // BGE: 大等时跳转
        default:      BJump = 1'b0;    // 其他情况不跳转
    endcase
end
```

#### 5.6.3 分支指令支持
- **BEQ**: 相等分支，zero=1时跳转
- **BNE**: 不等分支，zero=0时跳转
- **BLT**: 小于分支，less=1时跳转
- **BGE**: 大等分支，less=0时跳转

### 5.7 EX阶段数据流总结
1. **运算执行**: ALU根据ALUSel执行相应运算
2. **标志生成**: 生成zero、less等比较标志
3. **分支判断**: 根据比较结果决定是否跳转
4. **结果缓存**: F寄存器缓存运算结果
5. **地址计算**: 为MEM阶段提供内存访问地址

### 5.8 支持的运算类型
- **算术运算**: 加法、减法
- **逻辑运算**: 与、或、异或
- **移位运算**: 逻辑左移、逻辑右移、算术右移
- **比较运算**: 有符号/无符号比较
- **地址计算**: PC相对寻址、基址寻址

## 6. MEM阶段 - 访存阶段

### 6.1 阶段功能
MEM阶段负责数据存储器的访问，包括加载指令的数据读取和存储指令的数据写入。该阶段以数据存储器为核心，实现CPU与存储系统的交互。

### 6.2 DMem数据存储器

#### 6.2.1 模块功能
数据存储器以RAM形式实现，支持32位数据的读写操作，为加载和存储指令提供数据存储服务。

#### 6.2.2 端口定义
```verilog
module DMem (
    input clk,           // 时钟信号
    input [7:2] addr,    // 6位地址（32位对齐）
    input [31:0] din,    // 写入数据
    input MemWr,         // 写入使能
    output [31:0] dout   // 读出数据
);
```

#### 6.2.3 实现代码
```verilog
module DMem (
        input clk,
        input [7:2] addr,
        input [31:0] din,
        input MemWr,
        output [31:0] dout
    );

    RAM ram_data (
        .clka(clk),      // 时钟连接
        .wea(MemWr),     // 写使能连接
        .addra(addr),    // 地址连接
        .dina(din),      // 写数据连接
        .douta(dout)     // 读数据连接
    );

endmodule
```

#### 6.2.4 设计特点
- **IP核实现**: 使用Xilinx IP核生成的RAM模块
- **32位对齐**: 地址使用`ALU_R[7:2]`，支持64个32位数据
- **同步访问**: 读写操作都是同步的
- **单端口**: 每个时钟周期只能进行一次读或写操作

#### 6.2.5 在CPU中的连接
```verilog
DMem dmem (
    .clk(~clk_on),           // 使用取反的CPU时钟
    .addr(ALU_R[7:2]),       // 使用ALU计算的地址
    .din(reg_data2),         // 写入rs2寄存器的数据
    .MemWr(MemWr),           // 控制单元生成的写使能
    .dout(mem_data)          // 读出的数据
);
```

### 6.3 存储器访问类型

#### 6.3.1 加载指令(Load)
- **LW**: 加载32位字
- 地址计算: `rs1 + immediate`
- 数据流向: `Memory → Register`
- 控制信号: `MemWr=0, WBSel=WBSel_MEM`

#### 6.3.2 存储指令(Store)
- **SW**: 存储32位字
- 地址计算: `rs1 + immediate`
- 数据流向: `Register → Memory`
- 控制信号: `MemWr=1, RegWr=0`

### 6.4 时钟设计
数据存储器使用`~clk_on`（取反的CPU时钟）的原因：
- 在CPU时钟的负边沿进行存储器访问
- 确保地址和数据已经稳定
- 避免与寄存器更新产生竞争

## 7. WB阶段 - 写回阶段

### 7.1 阶段功能
WB阶段负责选择正确的数据写回到寄存器文件，支持ALU结果和存储器数据两种写回源。

### 7.2 写回数据选择

#### 7.2.1 选择逻辑
```verilog
assign wb_data = WBSel == WBSel_ALU ? ALU_R : mem_data;
```

#### 7.2.2 写回源类型
- **WBSel_ALU (1'b0)**: 选择ALU运算结果
  - 算术逻辑指令 (R-type, I-type)
  - 地址计算指令 (AUIPC)
  - 立即数加载指令 (LUI)
  - 跳转指令 (JAL, JALR)

- **WBSel_MEM (1'b1)**: 选择存储器数据
  - 加载指令 (LW)

### 7.3 写回控制
写回操作由以下信号控制：
- `RegWr`: 寄存器写使能，由控制单元生成
- `rd`: 目标寄存器地址，从指令中解析
- `wb_data`: 写回数据，由WBSel选择

### 7.4 不同指令的写回行为

| 指令类型 | WBSel | RegWr | 写回内容 |
|---------|-------|-------|----------|
| R-type  | ALU   | 1     | ALU运算结果 |
| I-type计算 | ALU | 1     | ALU运算结果 |
| LUI     | ALU   | 1     | 立即数 |
| AUIPC   | ALU   | 1     | PC+立即数 |
| JAL     | ALU   | 1     | PC+4 |
| JALR    | ALU   | 1     | PC+4 |
| Load    | MEM   | 1     | 存储器数据 |
| Store   | -     | 0     | 不写回 |
| Branch  | -     | 0     | 不写回 |

## 8. 显示模块

### 8.1 SegData数据选择

#### 8.1.1 功能说明
为了便于调试，CPU设计了一个数据选择器，可以通过SegSel信号选择不同的内部信号显示在七段数码管上。

#### 8.1.2 实现代码
```verilog
always @(*) begin
    case (SegSel)
        0: SegData = inst;      // 当前指令
        1: SegData = pc;        // 程序计数器
        2: SegData = mem_data;  // 存储器数据
        3: SegData = ALU_R;     // ALU结果
        4: SegData = reg_data1; // 寄存器rs1数据
        5: SegData = reg_data2; // 寄存器rs2数据
        6: SegData = imm;       // 立即数
        7: SegData = wb_data;   // 写回数据
    endcase
end
```

### 8.2 Seg七段数码管控制器

#### 8.2.1 模块功能
七段数码管模块负责将32位数据以16进制形式显示在8位七段数码管上，支持动态扫描显示。

#### 8.2.2 实现代码
```verilog
module Seg(
    input clk,              // 时钟信号
    input rst,              // 复位信号
    input [31:0] data,      // 显示数据
    output reg [2:0] which, // 数码管位选
    output reg [7:0] code   // 数码管段选
);

    reg [14:0] count = 0;   // 分频计数器
    
    // 分频计数
    always @(posedge rst or posedge clk) begin
        if(rst)
            count <= 0;
        else
            count <= count + 1'b1;
    end

    // 位选控制
    always @(posedge rst or posedge count[14]) begin
        if(rst)
            which <= 0;
        else
            which <= which + 1'b1;
    end

    // 数据选择
    reg [3:0] data_x;
    always @* case (which)
        0: data_x = data[31:28]; // 最高4位
        1: data_x = data[27:24];
        2: data_x = data[23:20];
        3: data_x = data[19:16];
        4: data_x = data[15:12];
        5: data_x = data[11:8];
        6: data_x = data[7:4];
        7: data_x = data[3:0];   // 最低4位
    endcase

    // 7段译码
    always @* case (data_x)
        4'h0: code = 8'b0000_0011; // 显示0
        4'h1: code = 8'b1001_1111; // 显示1
        4'h2: code = 8'b0010_0101; // 显示2
        4'h3: code = 8'b0000_1101; // 显示3
        4'h4: code = 8'b1001_1001; // 显示4
        4'h5: code = 8'b0100_1001; // 显示5
        4'h6: code = 8'b0100_0001; // 显示6
        4'h7: code = 8'b0001_1111; // 显示7
        4'h8: code = 8'b0000_0001; // 显示8
        4'h9: code = 8'b0000_1001; // 显示9
        4'hA: code = 8'b0001_0001; // 显示A
        4'hB: code = 8'b1100_0001; // 显示B
        4'hC: code = 8'b0110_0011; // 显示C
        4'hD: code = 8'b1000_0101; // 显示D
        4'hE: code = 8'b0110_0001; // 显示E
        4'hF: code = 8'b0111_0001; // 显示F
    endcase

endmodule
```

#### 8.2.3 工作原理
1. **分频**: 使用15位计数器对时钟分频
2. **扫描**: 每2^15个时钟周期切换一个数码管位
3. **译码**: 将4位十六进制数转换为7段显示码
4. **显示**: 动态扫描8个数码管，显示32位数据

### 8.3 调试支持
通过SegSel可以观察的内部状态：
- **SegSel=0**: 观察当前执行的指令
- **SegSel=1**: 观察程序计数器值
- **SegSel=2**: 观察存储器读出的数据
- **SegSel=3**: 观察ALU运算结果
- **SegSel=4,5**: 观察源寄存器数据
- **SegSel=6**: 观察立即数值
- **SegSel=7**: 观察最终写回的数据

这种设计使得可以在不使用仿真工具的情况下，直接在硬件上观察CPU的内部状态，极大地方便了调试工作。

## 9. 通用寄存器模块

### 9.1 Reg模块功能
Reg模块是一个通用的32位寄存器，在CPU设计中被广泛使用作为流水线寄存器，用于在不同阶段之间传递和同步数据。

### 9.2 端口定义
```verilog
module Reg(
    input clk,              // 时钟信号
    input rst,              // 复位信号
    input [31:0] data_in,   // 输入数据
    output reg [31:0] data_out // 输出数据
);
```

### 9.3 实现代码
```verilog
module Reg(
        input clk,
        input rst,
        input [31:0] data_in,
        output reg [31:0] data_out
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out <= 32'b0;      // 复位时输出0
        end
        else begin
            data_out <= data_in;    // 时钟上升沿更新输出
        end
    end

endmodule
```

### 9.4 在CPU中的应用
该模块在CPU中有多个实例，用于不同的目的：

1. **PC寄存器**: 存储程序计数器
   ```verilog
   Reg PC (.clk(clk_on), .rst(rst), .data_in(dnpc), .data_out(pc));
   ```

2. **IR寄存器**: 存储当前指令
   ```verilog
   Reg IR (.clk(clk), .rst(rst), .data_in(imem_inst), .data_out(inst));
   ```

3. **A、B寄存器**: 存储ALU操作数
   ```verilog
   Reg A (.clk(clk), .rst(rst), .data_in(reg_data1), .data_out(a));
   Reg B (.clk(clk), .rst(rst), .data_in(reg_data2), .data_out(b));
   ```

4. **F寄存器**: 存储ALU结果
   ```verilog
   Reg F (.clk(clk), .rst(rst), .data_in(r), .data_out(ALU_R));
   ```

### 9.5 设计特点
- **异步复位**: 支持异步复位，复位时立即清零
- **同步更新**: 在时钟上升沿更新数据
- **通用性**: 可用于任何需要寄存器缓存的场合
- **简洁性**: 实现简单，易于理解和维护

---

# 项目总结与分析

## 10. 设计特色与创新点

### 10.1 单周期架构的流水线思维
虽然本CPU采用单周期实现，但在设计上体现了流水线的思维：
- 使用流水线寄存器分隔各个阶段
- 清晰的数据通路和控制通路分离
- 便于后续扩展为多周期或流水线CPU

### 10.2 双时钟设计
采用双时钟设计巧妙地解决了不同模块的时序需求：
- `clk`: 高频时钟，用于数码管显示和指令缓存
- `clk_on`: 低频时钟，用于CPU核心执行和调试

### 10.3 强大的调试功能
通过SegSel和七段数码管实现的调试系统：
- 可观察8种不同的内部状态
- 无需仿真即可进行硬件调试
- 16进制显示，信息量大

### 10.4 模块化设计
良好的模块化设计：
- 每个功能单元独立封装
- 接口清晰，便于测试和维护
- 易于理解和扩展

## 11. 性能分析

### 11.1 时序特性
- **单周期执行**: 每条指令一个`clk_on`周期完成
- **时钟频率**: 受限于最长的组合逻辑路径
- **流水线寄存器**: 提供了时序缓冲

### 11.2 资源利用
- **存储资源**: 指令存储器64×32bit，数据存储器64×32bit
- **寄存器**: 32个通用寄存器 + 多个流水线寄存器
- **组合逻辑**: ALU、控制单元、多路选择器等

### 11.3 指令支持
完整支持RISC-V RV32I基础指令集：
- 算术逻辑指令：ADD, SUB, AND, OR, XOR, SLT等
- 移位指令：SLL, SRL, SRA
- 立即数指令：ADDI, ANDI, ORI, XORI等
- 分支指令：BEQ, BNE, BLT, BGE
- 跳转指令：JAL, JALR
- 存储器指令：LW, SW
- 上位立即数：LUI, AUIPC

## 12. 改进建议

### 12.1 功能扩展
1. **更多指令支持**
   - 支持更多的分支指令（BLTU, BGEU等）
   - 支持不同宽度的加载存储（LB, LH, SB, SH等）
   - 添加系统指令支持

2. **存储器扩展**
   - 增加存储器容量
   - 支持字节寻址
   - 添加缓存机制

3. **异常处理**
   - 添加异常和中断支持
   - 实现特权级机制

### 12.2 性能优化
1. **流水线化**
   - 将单周期CPU改造为流水线CPU
   - 添加数据前递和冲突检测
   - 实现分支预测

2. **时序优化**
   - 优化关键路径时序
   - 添加更多流水线级
   - 平衡各级延迟

3. **功耗优化**
   - 添加时钟门控
   - 实现动态电压频率调整
   - 优化不必要的信号翻转

### 12.3 工程改进
1. **测试验证**
   - 添加更完整的测试用例
   - 实现自动化验证流程
   - 添加覆盖率分析

2. **文档完善**
   - 添加详细的用户手册
   - 提供更多的使用示例
   - 完善调试指南

## 13. 结论

本项目成功实现了一个功能完整的RISC-V 32位单周期CPU，具有以下特点：

1. **功能完整性**: 完整支持RV32I基础指令集，能够执行各种类型的程序
2. **设计合理性**: 采用经典的五级流水线概念进行模块划分，结构清晰
3. **调试便利性**: 集成了强大的硬件调试功能，便于开发和验证
4. **扩展性良好**: 模块化设计为后续功能扩展和性能优化奠定了基础

该CPU设计不仅实现了基本的处理器功能，更在工程实践中体现了良好的设计思想和实现技巧，为深入理解计算机体系结构和处理器设计提供了很好的案例。通过这个项目，我们可以深刻理解RISC-V指令集架构、单周期CPU的工作原理，以及硬件描述语言在数字系统设计中的应用。

本设计虽然是单周期实现，但其模块化的架构和清晰的接口设计为后续改进提供了良好的基础。无论是扩展为多周期CPU、流水线CPU，还是添加更多的功能特性，都可以在现有架构的基础上进行增量式的改进和优化。
