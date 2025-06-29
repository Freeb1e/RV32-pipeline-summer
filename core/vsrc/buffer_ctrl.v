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
        input valid_D,
        output RegWrite_E,
        output [1:0] ResultSrc_E,
        output  MemWrite_E,
        output MemRead_E,
        output Jump_E,
        output Branch_E,
        output [3:0]ALUControl_E,
        output ALUSrc_E,
        output auipc_E,
        output [2:0] funct3_E,
        output reg_ren_E,
        output [6:0] opcode_E

    );

    Reg reg_RegWrite(
            .clk(clk),
            .rst(rst),
            .din(RegWrite_D),
            .dout(RegWrite_E),
            .wen(valid_D)
        );
    Reg #(2,0)reg_ResultSrc(
            .clk(clk),
            .rst(rst),
            .din(ResultSrc_D),
            .dout(ResultSrc_E),
            .wen(valid_D)
        );
    Reg reg_MemWrite(
            .clk(clk),
            .rst(rst),
            .din(MemWrite_D),
            .dout(MemWrite_E),
            .wen(valid_D)
        );
    Reg reg_MemRead(   
            .clk(clk),
            .rst(rst),
            .din(MemRead_D),
            .dout(MemRead_E),
            .wen(valid_D)
        );
    Reg reg_Jump(
            .clk(clk),
            .rst(rst),
            .din(Jump_D),
            .dout(Jump_E),
            .wen(valid_D)
        );
    Reg reg_Branch(
            .clk(clk),
            .rst(rst),
            .din(Branch_D),
            .dout(Branch_E),
            .wen(valid_D)
        );
    Reg #(4,0)reg_ALUControl(
            .clk(clk),
            .rst(rst),
            .din(ALUControl_D),
            .dout(ALUControl_E),
            .wen(valid_D)
        );
    Reg reg_ALUSrc(
            .clk(clk),
            .rst(rst),
            .din(ALUSrc_D),
            .dout(ALUSrc_E),
            .wen(valid_D)
        );
    Reg reg_auipc(
            .clk(clk),
            .rst(rst),
            .din(auipc_D),
            .dout(auipc_E),
            .wen(valid_D)
        );
    Reg #(3,0) reg_funct3(
            .clk(clk),
            .rst(rst),
            .din(funct3_D),
            .dout(funct3_E),
            .wen(valid_D)
        );
    Reg reg_reg_ren(
            .clk(clk),
            .rst(rst),
            .din(reg_ren_D),
            .dout(reg_ren_E),
            .wen(valid_D)
        );
    Reg #(7,0) reg_opcode(
            .clk(clk),
            .rst(rst),
            .din(opcode_D),
            .dout(opcode_E),
            .wen(valid_D)
        );

endmodule

module buffer_E_M_ctrl(
        input clk,
        input rst,
        input RegWrite_E,
        input [1:0] ResultSrc_E,
        input  MemWrite_E,
        input  MemRead_E,
        input [2:0] funct3_E,
        input valid_E,
        output RegWrite_M,
        output [1:0] ResultSrc_M,
        output  MemWrite_M,
        output  MemRead_M,
        output [2:0] funct3_M

    );
    Reg reg_RegWrite(
            .clk(clk),
            .rst(rst),
            .din(RegWrite_E),
            .dout(RegWrite_M),
            .wen(valid_E)
        );
    Reg #(2,0)reg_ResultSrc(
            .clk(clk),
            .rst(rst),
            .din(ResultSrc_E),
            .dout(ResultSrc_M),
            .wen(valid_E)
        );
    Reg  reg_MemWrite(
             .clk(clk),
             .rst(rst),
             .din(MemWrite_E),
             .dout(MemWrite_M),
             .wen(valid_E)
         );
    Reg reg_MemRead(
             .clk(clk),
             .rst(rst),
             .din(MemRead_E),
             .dout(MemRead_M),
             .wen(valid_E)
         );
    Reg #(3,0) reg_funct3(
            .clk(clk),
            .rst(rst),
            .din(funct3_E),
            .dout(funct3_M),
            .wen(valid_E)
        );

endmodule


module buffer_M_W_ctrl(
        input clk,
        input rst,
        input RegWrite_M,
        input [1:0] ResultSrc_M,
        input [2:0] funct3_M,
        input valid_M,
        output RegWrite_W,
        output [1:0] ResultSrc_W,
        output [2:0] funct3_W

    );
    Reg reg_RegWrite(
            .clk(clk),
            .rst(rst),
            .din(RegWrite_M),
            .dout(RegWrite_W),
            .wen(valid_M)
        );
    Reg #(2,0)reg_ResultSrc(
            .clk(clk),
            .rst(rst),
            .din(ResultSrc_M),
            .dout(ResultSrc_W),
            .wen(valid_M)
        );
    Reg #(3,0) reg_funct3(
            .clk(clk),
            .rst(rst),
            .din(funct3_M),
            .dout(funct3_W),
            .wen(valid_M)
        );

endmodule