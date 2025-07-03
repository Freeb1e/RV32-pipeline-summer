`include "define.v"
`include "pipeline_config.v"
`timescale 1ns / 1ps
module npc(
`ifdef SIMULATION
        input clk,
        input rst
`else
        input wire cpu_clk,
        input wire cpu_rst,

        // Interface to IROM
        output wire [31:0] irom_addr,
        input wire [31:0] irom_data,

        // Interface to DRAM & peripheral
        output wire [31:0] perip_addr,
        output wire perip_wen,
        output wire [1:0] perip_mask,
        output wire [31:0] perip_wdata,
        input wire [31:0] perip_rdata
`endif
    );
`ifdef SIMULATION
`else
    wire rst;
    wire clk;
    assign clk = cpu_clk;
    assign rst = cpu_rst;
    assign irom_addr = PC_reg;

    assign instr = irom_data;
    assign perip_addr = mem_addr;
    assign perip_wen = mem_wen;
    assign perip_wdata = mem_data_out;

    assign mem_data_in = perip_rdata;
`endif

    wire [31:0] ALU_DC;
    wire stop_sim;
    wire [31:0] instr;
    wire [31:0] PC_reg;
    wire [31:0] mem_data_in;
    wire [31:0] mem_data_out;
    wire [31:0] mem_addr;
    wire mem_wen;
    wire mem_ren;
    wire [31:0] PC_reg_WB; // for test
    datapath datapath1(
                 .clk(clk),
                 .rst(rst),
                 .instr_F(instr),
                 .ReadData_M(mem_data_in),
                 .mem_data_out(mem_data_out),
                 .mem_addr(mem_addr),
                 .MemWrite_M(mem_wen),
                 .MemRead_M(mem_ren),
                 .ALUResult_E(ALU_DC),
                 .PC_reg_F(PC_reg),
                 .PC_reg_WB_test(PC_reg_WB), // for test
                 `ifdef SIMULATION
                 `else
                 .mask(perip_mask),
                 `endif
                 .ebreak(stop_sim)
             );

    // output declaration of module memory
`ifdef SIMULATION
`ifdef RAMBUFFER

 reg [31:0] mem_data_in_r;
 wire [31:0] mem_data_in_1;

    always @(posedge clk) begin
        if (rst)
            mem_data_in_r <= 32'b0;
        else
            mem_data_in_r <= mem_data_in_1;
    end
    assign mem_data_in = mem_data_in_r;
`endif
       memory u_memory_read(
               .raddr 	(mem_addr  ),
               .waddr 	(mem_addr  ),
               .wdata 	( ),
               .wmask 	(8'h0F  ),
               .wen   	(1'b0    ),
               .valid 	(mem_ren | mem_wen  ),
               `ifdef RAMBUFFER
               .rdata 	(mem_data_in_1  )
               `else
                .rdata 	(mem_data_in  )
                `endif
           );
    memory u_memory_write(
               .raddr 	(mem_addr  ),
               .waddr 	(mem_addr  ),
               .wdata 	(mem_data_out  ),
               .wmask 	(8'h0F  ),
               .wen   	(mem_wen    ),
               .valid 	(mem_wen  ),
               .rdata 	( )
           );

    memory u_instr(
               .raddr 	(PC_reg  ),
               .waddr 	(mem_addr  ),
               .wdata 	(32'b0  ),
               .wmask 	(8'h0F  ),
               .wen   	(1'b0    ),
               .valid 	(~rst  ),
               .rdata 	(instr )
           );

    wire [31:0] PC_reg_difftest;
    //assign PC_reg_difftest = PC_reg; // for difftest
    assign PC_reg_difftest = PC_reg_WB; // for difftest
    export "DPI-C" function get_pc_inst;
               function void get_pc_inst();
                   output int cpu_pc;
                   output int cpu_inst;
                   cpu_pc = PC_reg_difftest;
                   cpu_inst = instr;
               endfunction

               import "DPI-C" function void ebreak();
                          always @ (posedge clk) begin
                              if(stop_sim) begin
                                  ebreak();
                              end
                          end

`endif
                      endmodule
