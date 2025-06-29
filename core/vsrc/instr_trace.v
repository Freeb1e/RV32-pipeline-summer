module instr_trace(
    input clk,
    input rst,
    input [31:0] instr_D_TR,
    input valid_D,
    input valid_E,
    input valid_M,
    input [31:0] PC_reg_plus4_W,
    input flash_E,

    output [31:0] instr_W_TR,
    output [31:0] instr_M_TR,
    output [31:0] PC_reg_WB
);
    wire [31:0] instr_E_TR;
    //wire [31:0] instr_M_TR;

    Reg #(32,0)E_I  (
        .clk(clk),
        .rst(rst|flash_E),
        .din(instr_D_TR),
        .dout(instr_E_TR),
        .wen(valid_D)
    );
    Reg#(32,0) M_I  (
        .clk(clk),
        .rst(rst),
        .din(instr_E_TR),
        .dout(instr_M_TR),
        .wen(valid_E)
    );
    Reg #(32,0)W_I  (
        .clk(clk),
        .rst(rst),
        .din(instr_M_TR),
        .dout(instr_W_TR),
        .wen(valid_M)
    );
    assign PC_reg_WB = PC_reg_plus4_W-32'd4;
endmodule
