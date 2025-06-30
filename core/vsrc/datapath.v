`include "define.v"
`include "pipeline_config.v"
//`include "buffer_ctrl.v"
//`include "buffer_data.v"
`timescale 1ns / 1ps
module datapath(

        input clk,
        input rst,
        input [31:0] instr_F,
        input [31:0] ReadData_M,
        output reg [31:0] mem_data_out,
        output [31:0] mem_addr,
        output MemWrite_M,
        output MemRead_M,
        output [31:0] ALUResult_E,
        output [31:0] PC_reg_F,
        //--------写回阶段指令PC---------
        output wire [31:0] PC_reg_WB_test,
        // output wire RegWrite_W_test,
        //-------------------------------
        output ebreak
    );

    //测试输出信号端口----------
    assign PC_reg_WB_test=PC_reg_W;
    // assign RegWrite_W_test=RegWrite_W;
    //--------------------------

    wire RegWrite_D;


    wire ALU_ZERO;


    wire valid_F;
    wire valid_D;
    wire valid_E;
    wire valid_M;
    wire valid_PC;
    wire flash_D;
    wire flash_E;
    valid_ctrl u_valid_ctrl(
                   .clk      	(clk       ),
                   .rst      	(rst       ),

                   .ResultSrc_E_raw	(ResultSrc_E),
                   .RegWrite_E	(RegWrite_E),
                   .Rs1_D    	(Rs1_D     ),
                   .Rs2_D    	(Rs2_D     ),
                   .Rd_E     	(Rd_E      ),
                   .PCSrc_E  	(Jump_sign    ),

                   .valid_F  	(valid_F   ),
                   .valid_D  	(valid_D   ),
                   .valid_E  	(valid_E   ),
                   .valid_M  	(valid_M   ),
                   .valid_PC 	(valid_PC  ),
                   .flash_D  	(flash_D   ),
                   .flash_E  	(flash_E   )
               );

    //--------------------------------------------------------------------------------

    // Decoder generate control signal
    wire [31:0] imme_D;
    wire [3:0] ALUControl_D;
    wire [4:0] Rs1_D,Rs2_D,Rd_D;
    wire Jump_D,Branch_D;
    wire mem_wen_D;
    wire mem_ren_D;
    wire ALU_DB_Src_D;
    wire [1:0] ResultSrc_D;
    wire [2:0] funct3_D;
    wire auipc_D;
    wire jalr_D;
    wire reg_ren_D;
    mulcu_decoder mulcu1(
                      .instr(instr_D),
                      .ALU_ZERO(ALU_ZERO),
                      .alu_op(ALUControl_D),
                      .imme(imme_D),
                      .ebreak(ebreak),
                      .Rs1(Rs1_D),
                      .Rs2(Rs2_D),
                      .Rd(Rd_D),
                      .jump(Jump_D),
                      .branch(Branch_D),
                      .reg_wen(RegWrite_D),
                      .reg_ren(reg_ren_D),
                      .ALU_DB_Src(ALU_DB_Src_D),
                      .Reg_Src(ResultSrc_D),
                      .mem_wen(mem_wen_D),
                      .mem_ren(mem_ren_D),
                      .auipc(auipc_D),
                      .jalr(jalr_D),
                      .funct3(funct3_D),
                      .opcode(opcode_D)
                  );
    // the control signal between decode and excute
    wire RegWrite_E;

    wire [1:0] ResultSrc_E;
    wire MemWrite_E;
    wire MemRead_E;
    wire Jump_E;
    wire Branch_E;
    wire [3:0] ALUControl_E;
    wire ALU_DB_Src_E;
    wire auipc_E;
    wire [2:0] funct3_E;
    wire reg_ren_E;
    wire [6:0] opcode_D,opcode_E;

    buffer_D_E_Ctrl u_buffer_D_E_Ctrl(
                        .clk          	(clk           ),
                        .rst          	(rst   |flash_E        ),

                        .RegWrite_D   	(RegWrite_D    ),
                        .ResultSrc_D  	(ResultSrc_D ),
                        .MemWrite_D   	(mem_wen_D    ),
                        .MemRead_D    	(mem_ren_D     ),
                        .Jump_D       	(Jump_D       ),
                        .Branch_D     	(Branch_D    ),
                        .ALUControl_D 	(ALUControl_D  ),
                        .ALUSrc_D     	(ALU_DB_Src_D      ),
                        .auipc_D      	(auipc_D       ),
                        .funct3_D     	(funct3_D      ),
                        .reg_ren_D    	(reg_ren_D     ),
                        .opcode_D     	(opcode_D      ),

                        .RegWrite_E   	(RegWrite_E    ),
                        .ResultSrc_E  	(ResultSrc_E   ),
                        .MemWrite_E   	(MemWrite_E    ),
                        .MemRead_E    	(MemRead_E     ),
                        .Jump_E       	(Jump_E        ),
                        .Branch_E     	(Branch_E      ),
                        .ALUControl_E 	(ALUControl_E  ),
                        .ALUSrc_E     	(ALU_DB_Src_E      ),
                        .auipc_E      	(auipc_E       ),
                        .funct3_E     	(funct3_E      ),
                        .reg_ren_E    	(reg_ren_E     ),
                        .opcode_E     	(opcode_E      ),

                        .valid_D      	(valid_D       )
                    );


    // the control signal between excute and memory
    wire RegWrite_M;
    wire [1:0] ResultSrc_M;
    wire [2:0] funct3_M;
    buffer_E_M_ctrl u_buffer_E_M_ctrl(
                        .clk         	(clk          ),
                        .rst         	(rst     ),
                        .RegWrite_E  	(RegWrite_E   ),
                        .ResultSrc_E 	(ResultSrc_E  ),
                        .MemWrite_E  	(MemWrite_E   ),
                        .MemRead_E   	(MemRead_E    ),
                        .funct3_E    	(funct3_E     ),

                        .RegWrite_M  	(RegWrite_M   ),
                        .ResultSrc_M 	(ResultSrc_M  ),
                        .MemWrite_M  	(MemWrite_M   ),
                        .MemRead_M   	(MemRead_M    ),
                        .funct3_M    	(funct3_M     ),

                        .valid_E     	(valid_E      )
                    );
    // the control signal between memory and write back
    wire RegWrite_W;
    wire [1:0] ResultSrc_W;
    wire [2:0] funct3_W;
    buffer_M_W_ctrl u_buffer_M_W_ctrl(
                        .clk         	(clk          ),
                        .rst         	(rst          ),
                        .RegWrite_M  	(RegWrite_M   ),
                        .ResultSrc_M 	(ResultSrc_M  ),
                        .funct3_M    	(funct3_M     ),
                        .RegWrite_W  	(RegWrite_W  ),
                        .ResultSrc_W 	(ResultSrc_W  ),
                        .funct3_W    	(funct3_W     ),

                        .valid_M     	(valid_M      )
                    );

    //--------------------------------------------------------------------------------------------
    // output declaration of module buffer_F_D_data
    wire [31:0] instr_D;
    wire [31:0] PC_reg_D;

    buffer_F_D_data u_buffer_F_D_data(
                        .clk            	(clk             ),
                        .rst            	(rst     |flash_D         ),

                        .instr_F        	(instr_F         ),
                        .PC_reg_F       	(PC_reg_F        ),

                        .instr_D        	(instr_D         ),
                        .PC_reg_D       	(PC_reg_D        ),

                        .valid        	(valid_F         )
                    );


    // output declaration of module buffer_D_E_data
    wire [31:0] PC_reg_E;
    wire [31:0] imme_E;
    wire [31:0] rdata1_E;
    wire [31:0] rdata2_E;
    wire [4:0] Rd_E;
    wire [4:0] Rs1_E,Rs2_E;
    buffer_D_E_data u_buffer_D_E_data(
                        .clk            	(clk             ),
                        .rst            	(rst  |flash_E   ),

                        .PC_reg_D       	(PC_reg_D        ),
                        .imme_D         	(imme_D          ),
                        .rdata1_D          	(rdata1_D           ),
                        .rdata2_D          	(rdata2_D           ),
                        .Rd_D           	(Rd_D            ),
                        .Rs1_D         	    (Rs1_D          ),
                        .Rs2_D         	    (Rs2_D          ),

                        .PC_reg_E       	(PC_reg_E        ),
                        .imme_E         	(imme_E          ),
                        .rdata1_E          	(rdata1_E           ),
                        .rdata2_E          	(rdata2_E           ),
                        .Rd_E           	(Rd_E            ),
                        .Rs1_E         	    (Rs1_E          ),
                        .Rs2_E         	    (Rs2_E          ),

                        .valid        	    (valid_D         )
                    );

    // output declaration of module buffer_E_M_data
    wire [31:0] ALUResult_M;
    wire [4:0] Rd_M;
    wire [31:0] PC_reg_plus4_M;
    wire [31:0] imme_M;
    wire [31:0] rdata2_M;
    wire [31:0] PC_reg_M;
    buffer_E_M_data u_buffer_E_M_data(
                        .clk            	(clk             ),
                        .rst            	(rst      ),

                        .ALUResult_E    	(ALUResult_E     ),
                        .WriteData_E    	(rdata2_E     ),
                        .Rd_E           	(Rd_E            ),
                        .PC_reg_E 	        (PC_reg_E  ),
                        .imme_E         	(imme_E          ),

                        .ALUResult_M    	(ALUResult_M     ),
                        .WriteData_M    	(rdata2_M     ),
                        .Rd_M           	(Rd_M            ),
                        .PC_reg_M 	        (PC_reg_M  ),
                        .imme_M         	(imme_M          ),

                        .valid        	(valid_E         )
                    );

    // output declaration of module buffer_M_W_data
    wire [31:0] ALUResult_W;
    wire [4:0] Rd_W;
    wire [31:0] PC_reg_plus4_W;
    wire [31:0] ReadData_W;
    wire [31:0] imme_W;
    wire [31:0] PC_reg_W;
    buffer_M_W_data u_buffer_M_W_data(
                        .clk            	(clk             ),
                        .rst            	(rst             ),
                        .ALUResult_M    	(ALUResult_M     ),
                        .ReadData_M    	    (ReadData_M     ),
                        .PC_reg_M 	(PC_reg_M  ),
                        .Rd_M           	(Rd_M            ),
                        .imme_M         	(imme_M          ),

                        .ALUResult_W    	(ALUResult_W     ),
                        .ReadData_W    	    (ReadData_W     ),
                        .Rd_W           	(Rd_W            ),
                        .PC_reg_W 	        (PC_reg_W  ),
                        .imme_W         	(imme_W          ),

                        .valid        	(valid_M         )
                    );


    //--------------------------------------------------------------------------------------------


    wire [31:0] PC_src;
    wire [31:0] PC_norm,PC_jump,PC_jalr;
    PC PC_1(
           .clk(clk),
           .rst(rst),
           .PC_src(PC_src),
           .PC_reg(PC_reg_F),
           .valid_in(valid_PC),
           .valid_out()
       );
    wire Jump_sign;
    assign PC_norm=PC_reg_F+32'd4;
    assign PC_jump=PC_reg_E+imme_E;
    assign PC_jalr=imme_E+ALU_DA;
    assign Jump_sign=Jump_E |( Branch_E & branch_true);
    assign PC_src=(Jump_sign)?((jalr_E)?PC_jalr:PC_jump):PC_norm;

    reg jalr_E;
    always@(posedge clk) begin
        if (rst) begin
            jalr_E <= 1'b0;
        end else begin
            jalr_E <= jalr_D;
        end
    end

//分支预测为跳转
    wire [6:0] opcode_F;
    assign opcode_F=instr_F[6:0];
    wire branch_F,jal_F;
    wire [31:0] I_imme_F,J_imme_F,B_imme_F;
    wire [31:0] imme_F;
    wire [31:0] PC_branch_jal_F;
    wire predict;

    assign branch_F=(opcode_F==`B_type);
    assign jal_F=(opcode_F==`jal);

    assign J_imme_F={{12{instr_F[31]}},instr_F[19:12],instr_F[20],instr_F[30:21],1'b0};
    assign B_imme_F={{20{instr_F[31]}},instr_F[7],instr_F[30:25],instr_F[11:8],1'b0};
    assign imme_F=(jal_F)?J_imme_F:(branch_F)?B_imme_F:{32'd4};
    assign PC_branch_jal_F=PC_reg_F+imme_F;





    //-----------------EX stage----------------
    wire [31:0] ALU_DA,ALU_DB;
    wire ALU_OverFlow;
    wire [31:0] ALUResult_E_RAW;
    ALU ALU1(
            .ALU_DA(ALU_DA),
            .ALU_DB(ALU_DB),
            .ALU_CTL(ALUControl_E),
            .ALU_ZERO(ALU_ZERO),
            .ALU_OverFlow(ALU_OverFlow),
            .ALU_DC(ALUResult_E_RAW)
        );
    always @(*) begin
        case(ResultSrc_E)
            2'b00:
                ALUResult_E=ALUResult_E_RAW;
            2'b10:
                ALUResult_E=PC_reg_E+32'd4;
            2'b11:
                ALUResult_E=imme_E;
            default:
                ALUResult_E=ALUResult_E_RAW;
        endcase
    end


    HU_Reg_forward u_Reg_forward(
                       .RegWrite_M   	(RegWrite_M    ),
                       .RegWrite_W   	(RegWrite_W    ),
                       .ALUResult_M  	(ALUResult_M   ),
                       .rdata_reg_W  	(rdata_reg_W   ),
                       //.ResultSrc_M  	(ResultSrc_M   ),
                       //.funct3_M     	(funct3_M      ),
                       .Rd_M         	(Rd_M          ),
                       .Rd_W         	(Rd_W          ),
                       .Rs1_E        	(Rs1_E         ),
                       .Rs2_E        	(Rs2_E         ),
                       .reg_ren_E    	(reg_ren_E     ),
                       .auipc_E      	(auipc_E       ),
                       .PC_reg_E     	(PC_reg_E      ),
                       .rdata1_E     	(rdata1_E      ),
                       .ALU_DB_Src_E 	(ALU_DB_Src_E  ),
                       .imme_E       	(imme_E        ),
                       .rdata2_E     	(rdata2_E      ),
                       `ifdef forward
                          .Real_rdata2_E 	(real_rdata2_E  ),
                          `endif
                       .ALU_DA       	(ALU_DA        ),
                       .ALU_DB       	(ALU_DB        )
                   );
    /*
    assign ALU_DA=(reg_ren_E)?((auipc_E)? PC_reg_E:rdata1_E):32'b0;
    assign ALU_DB=(ALU_DB_Src_E)?rdata2_E:imme_E;*/




    wire beq,bne,blt,bge,bltu,bgeu;
    assign beq=(opcode_E==`B_type)&&(funct3_E==3'b000);
    assign bne=(opcode_E==`B_type)&&(funct3_E==3'b001);
    assign blt=(opcode_E==`B_type)&&(funct3_E==3'b100);
    assign bge=(opcode_E==`B_type)&&(funct3_E==3'b101);
    assign bltu=(opcode_E==`B_type)&&(funct3_E==3'b110);
    assign bgeu=(opcode_E==`B_type)&&(funct3_E==3'b111);

    wire bne_true,beq_true,blt_true,bge_true,bltu_true,bgeu_true;

    assign beq_true=(beq & ALU_ZERO);
    assign bne_true=(bne & ~ALU_ZERO);
    assign blt_true=(blt & ALUResult_E[0]);
    assign bge_true=(bge & ~ALUResult_E[0]);
    assign bltu_true=(bltu & ALUResult_E[0]);
    assign bgeu_true=(bgeu & ~ALUResult_E[0]);
    wire branch_true;
    assign branch_true=(beq_true | bne_true | blt_true | bge_true | bltu_true | bgeu_true);
    //-----------------Write Back stage----------------
    //-----------------------------------------
    wire [31:0] rdata1_D;
    wire [31:0] rdata2_D;
    reg  [31:0] rdata_reg_W;

    RegisterFile u_RegisterFile(
                     .clk    	(~clk     ),
                     .rst    	(rst     ),
                     .wdata  	(rdata_reg_W   ),
                     .waddr  	(Rd_W   ),
                     .wen    	(RegWrite_W     ),
                     .raddr1 	(Rs1_D  ),
                     .raddr2 	(Rs2_D  ),
                     .rdata1 	(rdata1_D  ),
                     .rdata2 	(rdata2_D  ),
                     .ren    	(reg_ren_D    )
                 );


    always @(*) begin
        case(ResultSrc_W)
            2'b01:
                rdata_reg_W=mem_data_pro;
            default:
                rdata_reg_W=ALUResult_W;
        endcase
    end

    reg [31:0] mem_data_pro;

    always @(*) begin
        case(funct3_W)
            3'b000:
                mem_data_pro={{24{ReadData_W[7]}},ReadData_W[7:0]};
            3'b001:
                mem_data_pro={{16{ReadData_W[15]}},ReadData_W[15:0]};
            3'b010:
                mem_data_pro=ReadData_W;
            3'b100:
                mem_data_pro={24'b0,ReadData_W[7:0]};
            3'b101:
                mem_data_pro={16'b0,ReadData_W[15:0]};
            default:
                mem_data_pro=ReadData_W;
        endcase
    end
    //-----------------------------------------

    //-----------------MEM stage----------------
    //-----------------------------------------
    always @(*) begin

        case(funct3_M)
            3'b000:
                mem_data_out = {ReadData_M[31:8],rdata2_My[7:0]};
            3'b001:
                mem_data_out = {ReadData_M[31:16],rdata2_My[15:0]};
            3'b010:
                mem_data_out = rdata2_My;
            default:
                mem_data_out = 32'b0;
        endcase
    end
//sw数据冲突处理

wire [31:0]real_rdata2_E;
reg [31:0] real_rdata2_M;

wire [31:0] rdata2_My;
assign rdata2_My=real_rdata2_M;

reg [4:0] Rs2_M;

always @(posedge clk) begin
    if (rst) begin
        real_rdata2_M<=32'b0;
    end else begin
        real_rdata2_M<=real_rdata2_E;
    end
end
//-------------------------------------------
    assign mem_addr=ALUResult_M ;
//-----------------------------------------


// output declaration of module instr_trace
    wire [31:0] instr_W_TR;
    wire [31:0] instr_M_TR;
    
    instr_trace u_instr_trace(
        .clk            	(clk             ),
        .rst            	(rst             ),
        .instr_D_TR     	(instr_D      ),
        .valid_D        	(valid_D         ),
        .valid_E        	(valid_E         ),
        .valid_M        	(valid_M         ),
        .flash_E        	(flash_E         ),
        .instr_W_TR     	(instr_W_TR      ),
        .instr_M_TR     	(instr_M_TR      )
    );
    
endmodule
