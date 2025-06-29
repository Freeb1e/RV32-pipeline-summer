`include "define.v"
module PC(
    input clk,
    input rst,
    input [31:0] PC_src,
    input valid_in,
    output reg valid_out,
    output reg [31:0] PC_reg
);


always@(posedge clk) begin
    if(rst) begin
        PC_reg <= `PC_rst;
    end
    else begin
        if(valid_in)
        PC_reg <= PC_src;
    end
end

always@(posedge clk) begin
    if(rst) begin
        valid_out <= 1'b1;
    end
    else begin
        valid_out <= valid_in;
    end
end
endmodule
