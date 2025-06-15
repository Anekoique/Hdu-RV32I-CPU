# 开启比特流压缩，优化bit文件大小
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

#时钟源20MHz
set_property PACKAGE_PIN H4 [get_ports clk]
set_property IOSTANDARD LVCMOS18 [get_ports clk]

# 数码管的段选引脚约束
set_property PACKAGE_PIN H19 [get_ports {code[7]}]
set_property PACKAGE_PIN G20 [get_ports {code[6]}]
set_property PACKAGE_PIN J22 [get_ports {code[5]}]
set_property PACKAGE_PIN K22 [get_ports {code[4]}]
set_property PACKAGE_PIN K21 [get_ports {code[3]}]
set_property PACKAGE_PIN H20 [get_ports {code[2]}]
set_property PACKAGE_PIN H22 [get_ports {code[1]}]
set_property PACKAGE_PIN J21 [get_ports {code[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {code[7]}]
set_property IOSTANDARD LVCMOS18 [get_ports {code[6]}]
set_property IOSTANDARD LVCMOS18 [get_ports {code[5]}]
set_property IOSTANDARD LVCMOS18 [get_ports {code[4]}]
set_property IOSTANDARD LVCMOS18 [get_ports {code[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {code[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {code[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {code[0]}]

# 数码管的位选及使能信号的约束
set_property PACKAGE_PIN N22 [get_ports {which[0]}]
set_property PACKAGE_PIN M21 [get_ports {which[1]}]
set_property PACKAGE_PIN M22 [get_ports {which[2]}]
set_property PACKAGE_PIN L21 [get_ports enable]
set_property IOSTANDARD LVCMOS18 [get_ports enable]
set_property IOSTANDARD LVCMOS18 [get_ports {which[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {which[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {which[0]}]

# 开关管脚约束
set_property PULLDOWN true [get_ports SegSel]
set_property IOSTANDARD LVCMOS18 [get_ports SegSel]
set_property PACKAGE_PIN R6  [get_ports {SegSel[3]}]
set_property PACKAGE_PIN U7  [get_ports {SegSel[2]}]
set_property PACKAGE_PIN AB7  [get_ports {SegSel[1]}]
set_property PACKAGE_PIN AB8  [get_ports {SegSel[0]}]

# 按键管脚约束
set_property IOSTANDARD LVCMOS18 [get_ports rst]
set_property IOSTANDARD LVCMOS18 [get_ports clk_on]
set_property PACKAGE_PIN V8  [get_ports rst]
set_property PACKAGE_PIN AA8 [get_ports clk_on]

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets clk_on_IBUF]

# 解决SegSel[2]的时钟路由问题
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets SegSel_IBUF[3]]
