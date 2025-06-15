`timescale 1ns / 1ps

module CPU_enhanced_tb();

    // 测试台信号定义
    reg clk;
    reg clk_on;
    reg rst;
    wire enable;
    wire [2:0] which;
    wire [7:0] code;
    
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

    // 时钟生成
    initial clk = 0;
    always #5 clk = ~clk;  // 100MHz主时钟
    
    initial clk_on = 0;
    always #50 clk_on = ~clk_on;  // CPU执行时钟

    // 周期计数
    always @(posedge clk_on) begin
        if (rst)
            cycle_count <= 0;
        else
            cycle_count <= cycle_count + 1;
    end

    // 主测试序列
    initial begin
        rst = 1;
        
        // 等待几个时钟周期后释放复位
        repeat(6) @(posedge clk_on);
        rst = 0;
        
        // 运行足够长时间执行COE中的指令
        repeat(100) @(posedge clk_on);
        
        $finish;
    end
    
    // 观察关键信号变化
    always @(posedge clk_on) begin
        if (!rst) begin
            $display("Cycle %0d: which=%0d, code=0x%02h, time=%0t", 
                     cycle_count, which, code, $time);
        end
    end
    
    // 检测显示输出变化
    reg [2:0] prev_which = 0;
    reg [7:0] prev_code = 0;
    
    always @(which, code) begin
        if (!rst && (which != prev_which || code != prev_code)) begin
            $display("Display Update: which=%0d->%0d, code=0x%02h->0x%02h at time=%0t", 
                     prev_which, which, prev_code, code, $time);
            prev_which = which;
            prev_code = code;
        end
    end

endmodule 