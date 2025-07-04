`include "pipeline_config.v"
module HU_Reg_forward(
        input RegWrite_M,
        input RegWrite_W,
        input [31:0] ALUResult_M,
        input [31:0] rdata_reg_W,
        input [4:0] Rd_M,
        input [4:0] Rd_W,
        input [4:0] Rs1_E,
        input [4:0] Rs2_E,

        input reg_ren_E,
        input auipc_E,
        input [31:0]PC_reg_E,
        input [31:0] rdata1_E,

        input ALU_DB_Src_E,
        input [31:0] imme_E,
        input [31:0] rdata2_E,

        output [31:0] ALU_DA,
`ifdef forward
        output reg [31:0] Real_rdata2_E,
`ifdef rise
        input  [4:0] Rd_riseW,
        input  [31:0] rdata_reg_riseW,
        input  RegWrite_riseW,
        input [4:0] Rd_buf2,
        input [31:0] rdata_reg_buf2,
        input RegWrite_buf2,
`endif
`endif
        output [31:0] ALU_DB
    );
    reg [31:0] Real_rdata1_E;

`ifdef priority_E

    // 优化的前递逻辑 - 使用并行判断减少关键路径
    wire forward_M_Rs1, forward_W_Rs1, forward_rise_Rs1, forward_buf2_Rs1;
    wire forward_M_Rs2, forward_W_Rs2, forward_rise_Rs2, forward_buf2_Rs2;
    
    // 并行生成所有前递条件
    assign forward_M_Rs1 = RegWrite_M && (Rs1_E == Rd_M) && (Rs1_E != 5'b0);
    assign forward_W_Rs1 = RegWrite_W && (Rs1_E == Rd_W) && (Rs1_E != 5'b0);
    assign forward_M_Rs2 = RegWrite_M && (Rs2_E == Rd_M) && (Rs2_E != 5'b0);
    assign forward_W_Rs2 = RegWrite_W && (Rs2_E == Rd_W) && (Rs2_E != 5'b0);
    
`ifdef rise
    assign forward_rise_Rs1 = RegWrite_riseW && (Rs1_E == Rd_riseW) && (Rs1_E != 5'b0);
    assign forward_rise_Rs2 = RegWrite_riseW && (Rs2_E == Rd_riseW) && (Rs2_E != 5'b0);
`else
    assign forward_rise_Rs1 = 1'b0;
    assign forward_rise_Rs2 = 1'b0;
`endif

`ifdef RAMBUFFER
`ifdef rise
    assign forward_buf2_Rs1 = RegWrite_buf2 && (Rs1_E == Rd_buf2) && (Rs1_E != 5'b0);
    assign forward_buf2_Rs2 = RegWrite_buf2 && (Rs2_E == Rd_buf2) && (Rs2_E != 5'b0);
`else
    assign forward_buf2_Rs1 = 1'b0;
    assign forward_buf2_Rs2 = 1'b0;
`endif
`else
    assign forward_buf2_Rs1 = 1'b0;
    assign forward_buf2_Rs2 = 1'b0;
`endif

    // Rs1前递逻辑 - 使用优先级编码
    always@(*) begin
        if (!reg_ren_E) begin
            Real_rdata1_E = 32'b0;
        end else if (forward_M_Rs1) begin
            Real_rdata1_E = ALUResult_M;        // 最高优先级：M级
        end else if (forward_W_Rs1) begin
            Real_rdata1_E = rdata_reg_W;      // 次高优先级：W级
        end 
        else 
        `ifdef rise
            if (forward_rise_Rs1) begin
            Real_rdata1_E = rdata_reg_riseW;    // 第三优先级：riseW
        end else 
        `endif
        `ifdef RAMBUFFER
        if (forward_buf2_Rs1) begin
            Real_rdata1_E = rdata_reg_buf2;     // 最低优先级：buf2
        end else
        `endif 
        begin
            
            Real_rdata1_E = rdata1_E;           // 无前递
        end
    end

    // Rs2前递逻辑 - 使用优先级编码
    always@(*) begin
        if (!reg_ren_E) begin
            Real_rdata2_E = 32'b0;
        end else if (forward_M_Rs2) begin
            Real_rdata2_E = ALUResult_M;        // 最高优先级：M级
        end else if (forward_W_Rs2) begin
            Real_rdata2_E = rdata_reg_W;        // 次高优先级：W级
        end else 
        `ifdef rise
        if (forward_rise_Rs2) begin
            Real_rdata2_E = rdata_reg_riseW;    // 第三优先级：riseW
        end else
        `endif 
        `ifdef RAMBUFFER
         if (forward_buf2_Rs2) begin
            Real_rdata2_E = rdata_reg_buf2;     // 最低优先级：buf2
        end else 
        `endif 
        begin
            Real_rdata2_E = rdata2_E;           // 无前递
        end
    end
`else
    always@(*) begin
        if (reg_ren_E) begin
            if(RegWrite_W && (Rs1_E == Rd_W)) begin
                Real_rdata1_E = rdata_reg_W;
            end
            else begin
                if(RegWrite_M && (Rs1_E == Rd_M)) begin
                    Real_rdata1_E = ALUResult_M;
                end
                else begin
                    Real_rdata1_E = rdata1_E;
                end
            end

        end
        else begin
            Real_rdata1_E = 32'b0;
        end
    end

    always@(*) begin
        if (reg_ren_E) begin
            if(RegWrite_W && (Rs2_E == Rd_W)) begin
                Real_rdata2_E = rdata_reg_W;
            end
            else begin
                if(RegWrite_M && (Rs2_E == Rd_M)) begin
                    Real_rdata2_E = ALUResult_M;
                end

                else begin
                    Real_rdata2_E = rdata2_E;
                end
            end
        end
        else begin
            Real_rdata2_E = 32'b0;
        end
    end
`endif



`ifdef forward
    assign ALU_DA = (auipc_E) ? PC_reg_E : ((Rs1_E==5'd0)? 32'd0:Real_rdata1_E);
    assign ALU_DB = (ALU_DB_Src_E) ? ((Rs2_E==5'd0)? 32'd0:Real_rdata2_E) : imme_E;
`else
    reg [31:0] Real_rdata2_E;
    assign ALU_DA=(reg_ren_E)?((auipc_E)? PC_reg_E:rdata1_E):32'b0;
    assign ALU_DB=(ALU_DB_Src_E)?rdata2_E:imme_E;
`endif

endmodule
