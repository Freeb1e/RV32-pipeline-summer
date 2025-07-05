`include "define.v"
`include "pipeline_config.v"

`timescale 1ns / 1ps
module datapath(

        input clk,
        input rst,
        input [31:0] instr_F,
        input [31:0] ReadData_M,
        output [31:0] mem_data_out,
        output [31:0] mem_addr,
        output MemWrite_M,
        output MemRead_M,
        output reg [31:0] ALUResult_E,
        output [31:0] PC_reg_F,
        //--------写回阶段指令PC---------
        output wire [31:0] PC_reg_WB_test,
        `ifndef SIMULATION
        output reg [1:0] mask,
`endif
        output reg [7:0] wmask,
        //-------------------------------
        output ebreak
    );

    //测试输出信号端口----------
`ifdef RAMBUFFER

   assign PC_reg_WB_test=(flash_w_r)?32'b0:PC_reg_W;
    reg flash_w_r;
    always @(posedge clk) begin
        if (rst)
            flash_w_r <= 1'b0;
        else
            flash_w_r <= flash_W;
    end
`else
    assign PC_reg_WB_test=PC_reg_W;
`endif

    assign ebreak=ebreak_W;
    //--------------------------
    // 控制信号
    wire RegWrite_D;
    wire valid_PC, valid_F, valid_D, valid_E, valid_M;
    wire flash_D, flash_E;
    wire [3:0] ALUControl_D, ALUControl_E;
    wire [4:0] Rs1_D, Rs2_D, Rs1_E, Rs2_E, Rd_D, Rd_W, Rd_M, Rd_E;
    wire Jump_D, Branch_D;
    wire MemWrite_D, MemWrite_E;
    wire MemRead_D, MemRead_E;
    wire ALU_DB_Src_D;
    wire [1:0] ResultSrc_D, ResultSrc_E, ResultSrc_M, ResultSrc_W;
    wire [2:0] funct3_D, funct3_E, funct3_M;
    wire reg_ren_D, reg_ren_E;
    wire RegWrite_E, RegWrite_M, RegWrite_W;
    wire auipc_D;
    wire jalr_D;
    wire Jump_E;
    wire Branch_E;
    wire ALU_DB_Src_E;
    wire auipc_E;
    wire [6:0] opcode_D, opcode_E;
    wire [2:0] funct3_W;
    wire ALU_OverFlow;
    wire ebreak_D, ebreak_E, ebreak_M, ebreak_W;

    wire ALU_ZERO;

    // 数据信号
    wire [31:0] imme_D, imme_E, imme_M, imme_W;
    wire [31:0] ALUResult_W, ALUResult_M;
    wire [31:0] rdata1_D, rdata2_D, rdata1_E, rdata2_E, rdata2_M;
    wire [31:0] PC_reg_D, PC_reg_E;
    wire [31:0] instr_D;
    wire [31:0] ReadData_W;
    wire [31:0] PC_reg_M, PC_reg_W;
    wire [31:0] ALU_DA, ALU_DB;
    wire [31:0] ALUResult_E_RAW;

`ifdef RAMBUFFER

    wire flash_W;
    wire valid_WB_rise;
`endif

    valid_ctrl u_valid_ctrl(
                   .clk      	(clk       ),
                   .rst      	(rst       ),

                   .ResultSrc_E_raw	(ResultSrc_E),
                   .RegWrite_E	(RegWrite_E),
                   .Rs1_D    	(Rs1_D     ),
                   .Rs2_D    	(Rs2_D     ),
                   .Rd_E     	(Rd_E      ),
                   .PCSrc_E  	(Pre_Wrong),
`ifdef RAMBUFFER
                   .MemRead_E  (MemRead_E),
                   .flash_W    (flash_W),
                   .MemRead_M  (MemRead_M),
                   .valid_WB_rise	(valid_WB_rise),
`endif
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

    mulcu_decoder mulcu1(
                      .instr(instr_D),
                      .ALU_ZERO(ALU_ZERO),
                      .alu_op(ALUControl_D),
                      .imme(imme_D),
                      .ebreak(ebreak_D),
                      .Rs1(Rs1_D),
                      .Rs2(Rs2_D),
                      .Rd(Rd_D),
                      .jump(Jump_D),
                      .branch(Branch_D),
                      .reg_wen(RegWrite_D),
                      .reg_ren(reg_ren_D),
                      .ALU_DB_Src(ALU_DB_Src_D),
                      .Reg_Src(ResultSrc_D),
                      .mem_wen(MemWrite_D),
                      .mem_ren(MemRead_D),
                      .auipc(auipc_D),
                      .jalr(jalr_D),
                      .funct3(funct3_D),
                      .opcode(opcode_D)
                  );
    // the control signal between decode and excute


    // 使用合并后的buffer_D_E模块
    buffer_D_E u_buffer_D_E(
                   .clk          	(clk           ),
                   .rst          	(rst   |flash_E        ),
                   .valid_D      	(valid_D       ),

                   // 控制信号
                   .RegWrite_D   	(RegWrite_D    ),
                   .ResultSrc_D  	(ResultSrc_D ),
                   .MemWrite_D   	(MemWrite_D   ),
                   .MemRead_D    	(MemRead_D     ),
                   .Jump_D       	(Jump_D       ),
                   .Branch_D     	(Branch_D    ),
                   .ALUControl_D 	(ALUControl_D  ),
                   .ALUSrc_D     	(ALU_DB_Src_D      ),
                   .auipc_D      	(auipc_D       ),
                   .funct3_D     	(funct3_D      ),
                   .reg_ren_D    	(reg_ren_D     ),
                   .opcode_D     	(opcode_D      ),
                   .ebreak_D     	(ebreak_D      ),

                   // 数据
                   .PC_reg_D       (PC_reg_D        ),
                   .imme_D         (imme_D          ),
                   .rdata1_D       (rdata1_D        ),
                   .rdata2_D       (rdata2_D        ),
                   .Rd_D           (Rd_D            ),
                   .Rs1_D          (Rs1_D           ),
                   .Rs2_D          (Rs2_D           ),

                   // 控制信号输出
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
                   .ebreak_E     	(ebreak_E      ),

                   // 数据输出
                   .PC_reg_E       (PC_reg_E        ),
                   .imme_E         (imme_E          ),
                   .rdata1_E       (rdata1_E        ),
                   .rdata2_E       (rdata2_E        ),
                   .Rd_E           (Rd_E            ),
                   .Rs1_E          (Rs1_E           ),
                   .Rs2_E          (Rs2_E           )
               );


    // 注意：控制模块已被合并到统一的流水线缓冲区模块中

    //--------------------------------------------------------------------------------------------
    // output declaration of module buffer_F_D_data


    // 使用合并后的buffer_F_D模块
    buffer_F_D u_buffer_F_D(
                   .clk            	(clk             ),
                   .rst            	(rst     |flash_D         ),

                   .instr_F        	(instr_F         ),
                   .PC_reg_F       	(PC_reg_F        ),

                   .instr_D        	(instr_D         ),
                   .PC_reg_D       	(PC_reg_D        ),

                   .valid        	    (valid_F         )
               );

    // 使用合并后的buffer_E_M模块
    buffer_E_M u_buffer_E_M(
                   .clk            	(clk             ),
                   .rst            	(rst             ),
                   .valid_E        	(valid_E         ),

                   // 控制信号输入
                   .RegWrite_E       (RegWrite_E      ),
                   .ResultSrc_E      (ResultSrc_E     ),
                   .MemWrite_E       (MemWrite_E      ),
                   .MemRead_E        (MemRead_E       ),
                   .funct3_E         (funct3_E        ),
                   .ebreak_E         (ebreak_E        ),

                   // 数据输入
                   .ALUResult_E    	(ALUResult_E     ),
                   .WriteData_E    	(rdata2_E        ),
                   .Rd_E           	(Rd_E            ),
                   .PC_reg_E 	      (PC_reg_E        ),
                   .imme_E         	(imme_E          ),

                   // 控制信号输出
                   .RegWrite_M       (RegWrite_M      ),
                   .ResultSrc_M      (ResultSrc_M     ),
                   .MemWrite_M       (MemWrite_M      ),
                   .MemRead_M        (MemRead_M       ),
                   .funct3_M         (funct3_M        ),
                   .ebreak_M         (ebreak_M        ),

                   // 数据输出
                   .ALUResult_M    	(ALUResult_M     ),
                   .WriteData_M    	(rdata2_M        ),
                   .Rd_M           	(Rd_M            ),
                   .PC_reg_M 	      (PC_reg_M        ),
                   .imme_M         	(imme_M          )
               );

    // 使用合并后的buffer_M_W模块
    buffer_M_W u_buffer_M_W(
                   .clk            	(clk             ),
`ifdef RAMBUFFER
                   .rst            	(rst    ),
`else
                   .rst            	(rst           ),
`endif
                   .valid_M        	(valid_M         ),

                   // 控制信号输入
                   .RegWrite_M       (RegWrite_M      ),
                   .ResultSrc_M      (ResultSrc_M     ),
                   .funct3_M         (funct3_M        ),
                   .ebreak_M         (ebreak_M        ),

                   // 数据输入
                   .ALUResult_M    	(ALUResult_M     ),
                   .ReadData_M    	  (ReadData_M      ),
                   .PC_reg_M 	      (PC_reg_M        ),
                   .Rd_M           	(Rd_M            ),
                   .imme_M         	(imme_M          ),

                   // 控制信号输出
                   .RegWrite_W       (RegWrite_W      ),
                   .ResultSrc_W      (ResultSrc_W     ),
                   .funct3_W         (funct3_W        ),
                   .ebreak_W         (ebreak_W        ),

                   // 数据输出
                   .ALUResult_W    	(ALUResult_W     ),
                   .ReadData_W    	  (ReadData_W      ),
                   .Rd_W           	(Rd_W            ),
                   .PC_reg_W 	      (PC_reg_W        ),
                   .imme_W         	(imme_W          )
               );
`ifdef rise
    reg [4:0] Rd_riseW;
    reg [31:0] rdata_reg_riseW;
    reg RegWrite_riseW;
    always @(posedge clk) begin
        if (rst ) begin
            Rd_riseW <= 5'b0;
            rdata_reg_riseW <= 32'b0;
            RegWrite_riseW <= 1'b0;
        end else
        `ifdef RAMBUFFER
         if(~flash_W) 
        `else
        `endif
        begin
            Rd_riseW <= Rd_W;
            rdata_reg_riseW <= rdata_reg_W;
            RegWrite_riseW <= RegWrite_W;
        end
    end
`endif

    //--------------------------------------------------------------------------------------------


    reg [31:0] PC_src;
    wire [31:0] PC_norm,PC_jump,PC_jalr;
    
    // BTB相关信号
    wire btb_hit;
    wire [31:0] btb_target_addr;
    wire btb_update;
    wire [31:0] btb_update_target;
    
    // BTB实例化
    BTB u_BTB(
        .clk(clk),
        .rst(rst),
        .valid_in(btb_update),           // EX阶段确认为分支指令时更新BTB
        .branch_PC(PC_reg_E),            // 当前执行的分支指令PC
        .branch_target(btb_update_target), // 实际的分支目标地址
        .PC_in(PC_reg_F),                // IF阶段的PC
        .hit(btb_hit),                   // BTB命中信号
        .target_addr(btb_target_addr)    // 预测的分支目标地址
    );

    /* verilator lint_off PINCONNECTEMPTY */
/* verilator lint_off UNUSEDSIGNAL */
PC PC_1(
       .clk(clk),
       .rst(rst),
       .PC_src(PC_src),
       .PC_reg(PC_reg_F),
       .valid_in(valid_PC),
       .valid_out() // 未使用但需要连接
   );
/* verilator lint_on UNUSEDSIGNAL */
    wire Jump_sign;
    // PC计算
    assign PC_norm=PC_reg_F+32'd4;
    assign PC_jump=PC_reg_E+imme_E;
    assign PC_jalr=imme_E+ALU_DA;
    assign Jump_sign=Jump_E |( Branch_E & branch_true);
    
    // BTB更新逻辑 - 在EX阶段确认分支结果后更新
    assign btb_update = (Jump_E || (Branch_E & branch_true)) && valid_E;
    assign btb_update_target = jalr_E ? PC_jalr : PC_jump;
    
    //assign PC_src=(Jump_sign)?((jalr_E)?PC_jalr:PC_jump):PC_norm;]
    wire Pre_Wrong;


    reg jalr_E;
    always@(posedge clk) begin
        if (rst) begin
            jalr_E <= 1'b0;
        end
        else begin
            jalr_E <=(flash_E)?1'b0:(valid_D)?jalr_D:jalr_E;
        end
    end
`ifdef Predict
    
    // 使用BTB进行分支预测
    wire [31:0] PC_normal_path, PC_correction_path;
    
    // 分支预测状态机（方向预测）
    reg [1:0] state;
    wire predict_ctrl;
    wire predict_direction;
    assign predict_ctrl = (state[1] == 1'b1); // MSB 为 1 表示预测跳转
    
    // 两位饱和计数器更新逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= 2'b00; // 初始化为强烈不跳转
        end
        else if (Branch_E) begin // 仅在 EX 阶段为分支指令时更新状态
            case (state)
                2'b00: // 强烈不跳转
                    state <= Pre_Wrong ? 2'b01 : 2'b00;
                2'b01: // 弱不跳转
                    state <= Pre_Wrong ? 2'b10 : 2'b00;
                2'b10: // 弱跳转
                    state <= Pre_Wrong ? 2'b01 : 2'b11;
                2'b11: // 强烈跳转
                    state <= Pre_Wrong ? 2'b10 : 2'b11;
            endcase
        end
    end
    
    // 将BTB与方向预测器结合
    reg predict_D, predict_E;
    wire predict_F;
    
    // 基于BTB和方向预测器进行预测
    // 如果BTB命中，使用方向预测器判断是否跳转
    // 如果是JAL指令，总是预测跳转
    assign predict_F = btb_hit && predict_ctrl;
    
    // 预测信号流水线传递
    always@(posedge clk) begin
        if (rst) begin
            predict_D <= 1'b0;
            predict_E <= 1'b0;
        end
        else begin
            predict_D <= flash_D ? 1'b0 : (valid_F ? predict_F : predict_D);
            predict_E <= flash_E ? 1'b0 : (valid_D ? predict_D : predict_E);
        end
    end
    
    // 优化的PC选择逻辑
    wire correction_needed;
    
    assign Pre_Wrong = predict_E ^ Jump_sign;
    
    // 正常路径：预测正确时的PC选择
    // 当BTB命中且方向预测为跳转时，使用BTB预测的目标地址
    assign PC_normal_path = (btb_hit && predict_ctrl) ? btb_target_addr : PC_norm;
    
    // 修正路径：预测错误时的PC选择  
    wire [31:0] PC_next_E;
    assign PC_next_E = PC_reg_E + 32'd4; // 执行阶段PC+4
    assign PC_correction_path = Jump_sign ? 
                              (jalr_E ? PC_jalr : PC_jump) : PC_next_E;
    
    // 最终PC选择
    always@(*) begin
        PC_src = Pre_Wrong ? PC_correction_path : PC_normal_path;
    end
`else
    assign PC_src=(Jump_sign)?((jalr_E)?PC_jalr:PC_jump):PC_norm;
    assign Pre_Wrong=Jump_sign; //不使用分支预测
`endif


    //-----------------EX stage----------------

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
`ifdef rise
                       .Rd_riseW   	(Rd_riseW    ),
                       .rdata_reg_riseW    (rdata_reg_riseW   ),
                       .RegWrite_riseW    (RegWrite_riseW   ),


`endif
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

    reg  [31:0] rdata_reg_W;

    RegisterFile u_RegisterFile(

`ifdef rise
                     .clk    	(clk     ),
`else
                     .clk    	(~clk     ),
`endif
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
    assign mem_data_out = rdata2_My;
    always @(*) begin
        case(funct3_M)
            3'b000:
                wmask=8'h01;
            3'b001:
                wmask=8'h03;
            3'b010:
                wmask=8'h0F;
            default:
                wmask=8'h00;
        endcase
`ifdef SIMULATION
`else
        case(funct3_M)
            3'b000:
                mask=2'b00;
            3'b001:
                mask=2'b01;
            3'b010:
                mask=2'b10;
            3'b100:
                mask=2'b00;
            3'b101:
                mask=2'b01;
            default:
                mask=2'b10;
        endcase
`endif

    end

    //sw数据冲突处理

    wire [31:0]real_rdata2_E;
    reg [31:0] real_rdata2_M;

    wire [31:0] rdata2_My;
    assign rdata2_My=real_rdata2_M;

    always @(posedge clk) begin
        if (rst) begin
            real_rdata2_M<=32'b0;
        end
        else begin
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
`ifdef RAMBUFFER
                    .flash_W        	(flash_W         ),
`endif
                    .instr_W_TR     	(instr_W_TR      ),
                    .instr_M_TR     	(instr_M_TR      )
                );

endmodule
