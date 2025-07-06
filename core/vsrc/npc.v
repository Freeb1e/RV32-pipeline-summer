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
    wire [7:0] wmask;
`ifndef SIMULATION
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


    wire ReadData_M_valid; // 增加该信号
    datapath_wrapper datapath1(
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
        .wmask(perip_mask),
        .ReadData_M_valid(ReadData_M_valid) // 增加该信号
    );
    reg ReadData_M_valid_reg;
    always @(posedge clk) begin
        if(rst) begin
            ReadData_M_valid_reg <= 1'b0;
        end else begin
            ReadData_M_valid_reg <= mem_ren & (~ReadData_M_valid);
        end
    end
    assign ReadData_M_valid = ReadData_M_valid_reg;

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
`else
    wire [31:0] mem_data_in_1;
    assign mem_data_in = mem_data_in_1; // for simulation
`endif
       memory #(.IS_IF(0)) u_memory(
               .raddr 	(mem_addr  ),
               .waddr 	(mem_addr  ),
               .wdata 	(mem_data_out ),
               .wmask 	(wmask  ),
               .wen   	(mem_wen    ),
               .valid 	(mem_ren | mem_wen ),
               .rdata 	(mem_data_in_1  )
           );

    memory #(.IS_IF(1)) u_instr(
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
                $display("EBREAK triggered at PC: %h", PC_reg_WB);
                ebreak();
            end
        end

`endif

endmodule

module datapath_wrapper(
    input clk,
    input rst,
    input [31:0] instr_F,
    input [31:0] ReadData_M,
    input ReadData_M_valid, // 增加该信号
    output [31:0] mem_data_out,
    output [31:0] mem_addr,
    output MemWrite_M,
    output MemRead_M,
    output reg [1:0] wmask,
    output reg [31:0] ALUResult_E,
    output [31:0] PC_reg_F
);

    wire [3:0] data_axi_wstrb;
    datapath u_datapath(
        .clk              	(clk               ),
        .rst              	(rst               ),
        .inst_axi_araddr  	(PC_reg_F   ),
        .inst_axi_arvalid 	(  ),
        .inst_axi_arready 	( 1'b1 ),
        .inst_axi_rdata   	(instr_F    ),
        .inst_axi_rresp   	( 2'b00   ),
        .inst_axi_rvalid  	(1'b1   ),
        .inst_axi_rready  	(   ),

        .data_axi_araddr  	(mem_addr   ),
        .data_axi_arvalid 	(MemRead_M  ),
        .data_axi_arready 	(1'b1  ),
        .data_axi_rdata   	(ReadData_M    ),
        .data_axi_rresp   	(2'b00    ),
        .data_axi_rvalid  	(ReadData_M_valid   ),
        .data_axi_rready  	(   ),
        .data_axi_awaddr  	(mem_addr   ),
        .data_axi_awvalid 	(MemWrite_M  ),
        .data_axi_awready 	(1'b1  ),
        .data_axi_wdata   	(mem_data_out    ),
        .data_axi_wstrb   	(data_axi_wstrb    ),
        .data_axi_wready  	(1'b1   ),
        .data_axi_bresp   	(2'b00    ),
        .data_axi_bvalid  	(1'b1   ),
        .data_axi_bready  	(   )
    );
    always @(*) begin
        case (data_axi_wstrb)
            4'b0001: wmask = 2'b00; // Byte
            4'b0011: wmask = 2'b01; // Half-word
            4'b1111: wmask = 2'b10; // Word
            default: wmask = 2'b11; // No write
        endcase
    end


endmodule
