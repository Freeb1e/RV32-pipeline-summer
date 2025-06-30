`timescale 1ns / 1ps
module buffer_F_D_data(
        input clk,
        input rst,
        input [31:0] instr_F,
        input [31:0] PC_reg_F,
        input [31:0] PC_reg_plus4_F,
        input valid,
        output [31:0] instr_D,
        output [31:0] PC_reg_D,
        output [31:0] PC_reg_plus4_D
    );

    Reg #(32, 0) reg_instr (
            .clk(clk),
            .rst(rst),
            .din(instr_F),
            .dout(instr_D),
            .wen(valid)
        );

    Reg #(32, 0) reg_PC_reg (
            .clk(clk),
            .rst(rst),
            .din(PC_reg_F),
            .dout(PC_reg_D),
            .wen(valid)
        );

    Reg #(32, 0) reg_PC_reg_plus4 (
            .clk(clk),
            .rst(rst),
            .din(PC_reg_plus4_F),
            .dout(PC_reg_plus4_D),
            .wen(valid)
        );

endmodule

module buffer_D_E_data(
        input clk,
        input rst,
        input [31:0] PC_reg_D,
        input [31:0] PC_reg_plus4_D,
        input [31:0] imme_D,
        input [31:0] rdata1_D,
        input [31:0] rdata2_D,
        input [4:0] Rd_D,
        input [4:0] Rs1_D,
        input [4:0] Rs2_D,
        input valid,
        output [31:0] PC_reg_E,
        output [31:0] PC_reg_plus4_E,
        output [31:0] imme_E,
        output [31:0] rdata1_E,
        output [31:0] rdata2_E,
        output [4:0] Rd_E,
        output [4:0] Rs1_E,
        output [4:0] Rs2_E
    );

    Reg #(32, 0) reg_PC_reg(
            .clk(clk),
            .rst(rst),
            .din(PC_reg_D),
            .dout(PC_reg_E),
            .wen(valid)
        );
    Reg #(32, 0) reg_PC_reg_plus4(
            .clk(clk),
            .rst(rst),
            .din(PC_reg_plus4_D),
            .dout(PC_reg_plus4_E),
            .wen(valid)
        );
    Reg #(32, 0) reg_imme(
            .clk(clk),
            .rst(rst),
            .din(imme_D),
            .dout(imme_E),
            .wen(valid)
        );
    Reg #(32, 0) reg_Rs1(
            .clk(clk),
            .rst(rst),
            .din(rdata1_D),
            .dout(rdata1_E),
            .wen(valid)
        );
    Reg #(32, 0) reg_Rs2(
            .clk(clk),
            .rst(rst),
            .din(rdata2_D),
            .dout(rdata2_E),
            .wen(valid)
        );
    Reg #(5, 0) reg_Rd(
            .clk(clk),
            .rst(rst),
            .din(Rd_D),
            .dout(Rd_E),
            .wen(valid)
        );
    Reg #(5,0) reg_Rs1_a(
            .clk(clk),
            .rst(rst),
            .din(Rs1_D),
            .dout(Rs1_E),
            .wen(valid)
        );
    Reg #(5,0) reg_Rs2_a(
            .clk(clk),
            .rst(rst),
            .din(Rs2_D),
            .dout(Rs2_E),
            .wen(valid)
        );

endmodule

module buffer_E_M_data(
        input clk,
        input rst,
        input [31:0] ALUResult_E,
        input [31:0] WriteData_E,
        input [4:0] Rd_E,
        input [31:0] PC_reg_plus4_E,
        input valid,
        output [31:0] ALUResult_M,
        output [31:0] WriteData_M,
        output [4:0] Rd_M,
        output [31:0] PC_reg_plus4_M,
        input [31:0] imme_E,
        output [31:0] imme_M
    );
    Reg #(32, 0)reg_ALUResult(
            .clk(clk),
            .rst(rst),
            .din(ALUResult_E),
            .dout(ALUResult_M),
            .wen(valid)
        );
    Reg #(32, 0)reg_WriteData(
            .clk(clk),
            .rst(rst),
            .din(WriteData_E),
            .dout(WriteData_M),
            .wen(valid)
        );
    Reg #(5, 0) reg_Rd(
            .clk(clk),
            .rst(rst),
            .din(Rd_E),
            .dout(Rd_M),
            .wen(valid)
        );
    Reg #(32, 0) reg_PC_reg_plus4(
            .clk(clk),
            .rst(rst),
            .din(PC_reg_plus4_E),
            .dout(PC_reg_plus4_M),
            .wen(valid)
        );
    Reg #(32, 0) reg_imme(
            .clk(clk),
            .rst(rst),
            .din(imme_E),
            .dout(imme_M),
            .wen(valid)
        );

endmodule

module buffer_M_W_data(
    input clk,
    input rst,
    input [31:0] ALUResult_M,
    input [31:0] ReadData_M,
    input [31:0] PC_reg_plus4_M,
    input [4:0] Rd_M,
    input valid,
    output [31:0] ALUResult_W,
    output [31:0] ReadData_W,
    output [4:0] Rd_W,
    output [31:0] PC_reg_plus4_W,
    input [31:0] imme_M,
    output [31:0] imme_W
    );
    Reg #(32, 0) reg_ALUResult(
            .clk(clk),
            .rst(rst),
            .din(ALUResult_M),
            .dout(ALUResult_W),
            .wen(valid)
        );
    Reg #(32, 0) reg_WriteData(
            .clk(clk),
            .rst(rst),
            .din(ReadData_M),
            .dout(ReadData_W),
            .wen(valid)
        );
    Reg #(5, 0) reg_Rd(
            .clk(clk),
            .rst(rst),
            .din(Rd_M),
            .dout(Rd_W),
            .wen(valid)
        );
    Reg #(32, 32'h8000_0004) reg_PC_reg_plus4(
            .clk(clk),
            .rst(rst),
            .din(PC_reg_plus4_M),
            .dout(PC_reg_plus4_W),
            .wen(valid)
        );
    Reg #(32,0) reg_imme(
            .clk(clk),
            .rst(rst),
            .din(imme_M),
            .dout(imme_W),
            .wen(valid)
        );

endmodule
