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
        `endif 
        output [31:0] ALU_DB
    );
    reg [31:0] Real_rdata1_E;

`ifdef priority_E

    always@(*) begin
        if (reg_ren_E) begin
            if(RegWrite_M && (Rs1_E == Rd_M)) begin
                Real_rdata1_E = ALUResult_M;
            end
            else begin
                if(RegWrite_W && (Rs1_E == Rd_W)) begin
                    Real_rdata1_E = rdata_reg_W;
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
            if(RegWrite_M && (Rs2_E == Rd_M)) begin
                Real_rdata2_E = ALUResult_M;
            end
            else begin
                if(RegWrite_W && (Rs2_E == Rd_W)) begin
                    Real_rdata2_E = rdata_reg_W;
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
                Real_rdata2_E = rdata_reg_W;end
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
