`include "define.v"
`timescale 1ns / 1ps
module npc(
        input clk,
        input rst,
        output [31:0] ALU_DC
    );
    wire stop_sim;
    wire [31:0] instr;
    //wire [31:0] ALU_DC;
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
                 .ebreak(stop_sim)
             );

    // output declaration of module memory

    memory u_memory_read(
               .raddr 	(mem_addr  ),
               .waddr 	(mem_addr  ),
               .wdata 	( ),
               .wmask 	(8'h0F  ),
               .wen   	(1'b0    ),
               .valid 	(mem_ren ),
               .rdata 	(mem_data_in  )
           );

    memory u_memory_write(
               .raddr 	(mem_addr  ),
               .waddr 	(mem_addr  ),
               .wdata 	(mem_data_out  ),
               .wmask 	(8'h0F  ),
               .wen   	(mem_wen    ),
               .valid 	(mem_ren  ),
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


endmodule
