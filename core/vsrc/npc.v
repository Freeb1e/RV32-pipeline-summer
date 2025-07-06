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

    // 数据存储器访存延迟参数
    parameter DATA_MEM_DELAY = 3;  // 3个周期的延迟

    // 数据存储器延迟控制寄存器
    reg [2:0] data_read_delay_counter;
    reg [2:0] data_write_delay_counter;
    reg data_read_pending;
    reg data_write_pending;
    reg data_arready_reg;
    reg data_rvalid_reg;
    reg data_awready_reg;
    reg data_wready_reg;
    reg data_bvalid_reg;

    // 数据存储器AXI信号延迟逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_read_delay_counter <= 0;
            data_write_delay_counter <= 0;
            data_read_pending <= 0;
            data_write_pending <= 0;
            data_arready_reg <= 1;
            data_rvalid_reg <= 0;
            data_awready_reg <= 1;
            data_wready_reg <= 1;
            data_bvalid_reg <= 0;
        end
        else begin
            // 读延迟逻辑
            if (data_axi_arvalid && data_arready_reg && !data_read_pending) begin
                // 开始读操作延迟
                data_read_pending <= 1;
                data_arready_reg <= 0;
                data_rvalid_reg <= 0;
                data_read_delay_counter <= DATA_MEM_DELAY - 1;
            end
            else if (data_read_pending) begin
                if (data_read_delay_counter == 0) begin
                    // 延迟结束，发出读数据有效信号
                    data_rvalid_reg <= 1;
                    data_read_pending <= 0;
                    data_arready_reg <= 1;
                end
                else begin
                    data_read_delay_counter <= data_read_delay_counter - 1;
                end
            end
            else if (data_rvalid_reg && data_axi_rready) begin
                // 读数据被接收，清除有效信号
                data_rvalid_reg <= 0;
            end

            // 写延迟逻辑
            if (data_axi_awvalid && data_axi_wvalid && data_awready_reg && data_wready_reg && !data_write_pending) begin
                // 开始写操作延迟
                data_write_pending <= 1;
                data_awready_reg <= 0;
                data_wready_reg <= 0;
                data_bvalid_reg <= 0;
                data_write_delay_counter <= DATA_MEM_DELAY - 1;
            end
            else if (data_write_pending) begin
                if (data_write_delay_counter == 0) begin
                    // 延迟结束，发出写响应信号
                    data_bvalid_reg <= 1;
                    data_write_pending <= 0;
                    data_awready_reg <= 1;
                    data_wready_reg <= 1;
                end
                else begin
                    data_write_delay_counter <= data_write_delay_counter - 1;
                end
            end
            else if (data_bvalid_reg && data_axi_bready) begin
                // 写响应被接收，清除有效信号
                data_bvalid_reg <= 0;
            end
        end
    end

    // 数据存储器AXI信号分配
    assign data_axi_arready = data_arready_reg;
    assign data_axi_rvalid = data_rvalid_reg;
    assign data_axi_rresp = 2'b00;
    assign data_axi_awready = data_awready_reg;
    assign data_axi_wready = data_wready_reg;
    assign data_axi_bvalid = data_bvalid_reg;
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
