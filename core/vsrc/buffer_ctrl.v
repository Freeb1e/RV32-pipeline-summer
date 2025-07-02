`timescale 1ns / 1ps
module buffer_D_E_Ctrl(
        input clk,
        input rst,
        input RegWrite_D,
        input [1:0] ResultSrc_D,
        input MemWrite_D,
        input MemRead_D,
        input Jump_D,
        input Branch_D,
        input [3:0]ALUControl_D,
        input ALUSrc_D,
        input auipc_D,
        input [2:0] funct3_D,
        input reg_ren_D,
        input [6:0] opcode_D,
        input ebreak_D,
        input valid_D,
        output reg RegWrite_E,
        output reg [1:0] ResultSrc_E,
        output reg MemWrite_E,
        output reg MemRead_E,
        output reg Jump_E,
        output reg Branch_E,
        output reg [3:0]ALUControl_E,
        output reg ALUSrc_E,
        output reg auipc_E,
        output reg [2:0] funct3_E,
        output reg reg_ren_E,
        output reg [6:0] opcode_E,
        output reg ebreak_E

    );

    always @(posedge clk) begin
        if (rst) begin
            RegWrite_E <= 1'b0;
            ResultSrc_E <= 2'b0;
            MemWrite_E <= 1'b0;
            MemRead_E <= 1'b0;
            Jump_E <= 1'b0;
            Branch_E <= 1'b0;
            ALUControl_E <= 4'b0;
            ALUSrc_E <= 1'b0;
            auipc_E <= 1'b0;
            funct3_E <= 3'b0;
            reg_ren_E <= 1'b0;
            opcode_E <= 7'b0;
            ebreak_E <= 1'b0;
        end
        else if (valid_D) begin
            RegWrite_E <= RegWrite_D;
            ResultSrc_E <= ResultSrc_D;
            MemWrite_E <= MemWrite_D;
            MemRead_E <= MemRead_D;
            Jump_E <= Jump_D;
            Branch_E <= Branch_D;
            ALUControl_E <= ALUControl_D;
            ALUSrc_E <= ALUSrc_D;
            auipc_E <= auipc_D;
            funct3_E <= funct3_D;
            reg_ren_E <= reg_ren_D;
            opcode_E <= opcode_D;
            ebreak_E <= ebreak_D;
        end
    end

endmodule

module buffer_E_M_ctrl(
        input clk,
        input rst,
        input RegWrite_E,
        input [1:0] ResultSrc_E,
        input  MemWrite_E,
        input  MemRead_E,
        input [2:0] funct3_E,
        input ebreak_E,
        input valid_E,
        output reg RegWrite_M,
        output reg [1:0] ResultSrc_M,
        output reg MemWrite_M,
        output reg MemRead_M,
        output reg [2:0] funct3_M,
        output reg ebreak_M

    );
    always @(posedge clk) begin
        if (rst) begin
            RegWrite_M <= 1'b0;
            ResultSrc_M <= 2'b0;
            MemWrite_M <= 1'b0;
            MemRead_M <= 1'b0;
            funct3_M <= 3'b0;
            ebreak_M <= 1'b0;
        end
        else if (valid_E) begin
            RegWrite_M <= RegWrite_E;
            ResultSrc_M <= ResultSrc_E;
            MemWrite_M <= MemWrite_E;
            MemRead_M <= MemRead_E;
            funct3_M <= funct3_E;
            ebreak_M <= ebreak_E;
        end
    end

endmodule


module buffer_M_W_ctrl(
        input clk,
        input rst,
        input RegWrite_M,
        input [1:0] ResultSrc_M,
        input [2:0] funct3_M,
        input ebreak_M,
        input valid_M,
        output reg RegWrite_W,
        output reg [1:0] ResultSrc_W,
        output reg [2:0] funct3_W,
        output reg ebreak_W

    );
    always @(posedge clk) begin
        if (rst) begin
            RegWrite_W <= 1'b0;
            ResultSrc_W <= 2'b0;
            funct3_W <= 3'b0;
            ebreak_W <= 1'b0;
        end
        else if (valid_M) begin
            RegWrite_W <= RegWrite_M;
            ResultSrc_W <= ResultSrc_M;
            funct3_W <= funct3_M;
            ebreak_W <= ebreak_M;
        end
    end

endmodule
