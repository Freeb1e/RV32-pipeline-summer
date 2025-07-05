`include "define.v"
`include "pipeline_config.v"
`timescale 1ns / 1ps
`ifdef SIMULATION
module npc(
`else
module myCPU(
`endif
`ifdef SIMULATION
        input clk,
        input rst
`else
        input wire cpu_clk,
        input wire cpu_rst,

        // AXI4-Lite 指令接口 (Master)
        output wire [31:0]   inst_axi_araddr,
        output wire          inst_axi_arvalid,
        input wire           inst_axi_arready,
        input wire [31:0]    inst_axi_rdata,
        input wire [1:0]     inst_axi_rresp,
        input wire           inst_axi_rvalid,
        output wire          inst_axi_rready,

        // AXI4-Lite 数据接口 (Master)
        // 读通道
        output wire [31:0]   data_axi_araddr,
        output wire          data_axi_arvalid,
        input wire           data_axi_arready,
        input wire [31:0]    data_axi_rdata,
        input wire [1:0]     data_axi_rresp,
        input wire           data_axi_rvalid,
        output wire          data_axi_rready,
        // 写通道
        output wire [31:0]   data_axi_awaddr,
        output wire          data_axi_awvalid,
        input wire           data_axi_awready,
        output wire [31:0]   data_axi_wdata,
        output wire [3:0]    data_axi_wstrb,
        output wire          data_axi_wvalid,
        input wire           data_axi_wready,
        input wire [1:0]     data_axi_bresp,
        input wire           data_axi_bvalid,
        output wire          data_axi_bready,

`endif
    );
`ifndef SIMULATION
    wire rst;
    wire clk;
    assign clk = cpu_clk;
    assign rst = cpu_rst;
`else
    // SIMULATION 模式下的内部信号
    wire [31:0] inst_axi_araddr;
    wire inst_axi_arvalid;
    wire inst_axi_arready;
    wire [31:0] inst_axi_rdata;
    wire [1:0] inst_axi_rresp;
    wire inst_axi_rvalid;
    wire inst_axi_rready;

    wire [31:0] data_axi_araddr;
    wire data_axi_arvalid;
    wire data_axi_arready;
    wire [31:0] data_axi_rdata;
    wire [1:0] data_axi_rresp;
    wire data_axi_rvalid;
    wire data_axi_rready;
    wire [31:0] data_axi_awaddr;
    wire data_axi_awvalid;
    wire data_axi_awready;
    wire [31:0] data_axi_wdata;
    wire [3:0] data_axi_wstrb;
    wire data_axi_wvalid;
    wire data_axi_wready;
    wire [1:0] data_axi_bresp;
    wire data_axi_bvalid;
    wire data_axi_bready;

    // 模拟AXI响应信号
    assign inst_axi_arready = 1'b1;
    assign inst_axi_rvalid = inst_axi_arvalid;
    assign inst_axi_rresp = 2'b00;
    assign data_axi_arready = 1'b1;
    assign data_axi_rvalid = data_axi_arvalid;
    assign data_axi_rresp = 2'b00;
    assign data_axi_awready = 1'b1;
    assign data_axi_wready = 1'b1;
    assign data_axi_bvalid = 1'b1;
    assign data_axi_bresp = 2'b00;

`endif
    wire stop_sim;

    datapath datapath1(
                 .clk(clk),
                 .rst(rst),

                 // AXI4-Lite 指令接口
                 .inst_axi_araddr(inst_axi_araddr),
                 .inst_axi_arvalid(inst_axi_arvalid),
                 .inst_axi_arready(inst_axi_arready),
                 .inst_axi_rdata(inst_axi_rdata),
                 .inst_axi_rresp(inst_axi_rresp),
                 .inst_axi_rvalid(inst_axi_rvalid),
                 .inst_axi_rready(inst_axi_rready),

                 // AXI4-Lite 数据接口
                 .data_axi_araddr(data_axi_araddr),
                 .data_axi_arvalid(data_axi_arvalid),
                 .data_axi_arready(data_axi_arready),
                 .data_axi_rdata(data_axi_rdata),
                 .data_axi_rresp(data_axi_rresp),
                 .data_axi_rvalid(data_axi_rvalid),
                 .data_axi_rready(data_axi_rready),
                 .data_axi_awaddr(data_axi_awaddr),
                 .data_axi_awvalid(data_axi_awvalid),
                 .data_axi_awready(data_axi_awready),
                 .data_axi_wdata(data_axi_wdata),
                 .data_axi_wstrb(data_axi_wstrb),
                 .data_axi_wvalid(data_axi_wvalid),
                 .data_axi_wready(data_axi_wready),
                 .data_axi_bresp(data_axi_bresp),
                 .data_axi_bvalid(data_axi_bvalid),
                 .data_axi_bready(data_axi_bready),
                 .PC_W(PC_W),
                 .valid_W_out(valid_W),
                 .ebreak(stop_sim)
             );

    // output declaration of module memory
`ifdef SIMULATION

    memory #(.IS_IF(0)) u_memory(
               .raddr 	(data_axi_araddr  ),     // 使用AXI数据地址
               .waddr 	(data_axi_awaddr  ),     // 使用AXI写地址
               .wdata 	(data_axi_wdata   ),     // 使用AXI写数据
               .wmask 	({4'h0, data_axi_wstrb}  ),
               .wen   	(data_axi_awvalid ),     // 使用AXI写有效信号
               .valid 	(data_axi_arvalid | data_axi_awvalid ), // 读或写有效
               .rdata 	(data_axi_rdata  )
           );

    memory #(.IS_IF(1)) u_instr(
               .raddr 	(inst_axi_araddr  ),     // 使用AXI指令地址
               .waddr 	(32'b0  ),               // 指令内存不写
               .wdata 	(32'b0  ),
               .wmask 	(8'h00  ),               // 指令内存不写
               .wen   	(1'b0    ),
               .valid 	(inst_axi_arvalid ),     // 使用AXI指令读有效
               .rdata 	(inst_axi_rdata  ) 
           );

    wire [31:0] PC_W;
    wire valid_W;
    export "DPI-C" function get_pc_inst;
               function void get_pc_inst();
                   output int cpu_pc;
                   output int cpu_inst;
                   cpu_pc = PC_W;
                   cpu_inst = inst_axi_rdata;
               endfunction
    export "DPI-C" function get_validW;
                function void get_validW();
                     output byte validW;
                     validW = {7'b0,valid_W};
                endfunction

    import "DPI-C" function void ebreak();
                always @ (posedge clk) begin
                    if(stop_sim) begin
                        $display("EBREAK triggered at PC: %h", PC_W);
                        ebreak();
                    end
                end
`endif

endmodule
