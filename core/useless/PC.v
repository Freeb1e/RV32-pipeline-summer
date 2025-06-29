module PC(
    input clk,
    input rst,
    input jump,
    input [31:0] ALU_result,
    output reg [31:0] pc,
    output wire [31:0] snpc
);
    wire [31:0] dnpc;
    assign snpc = pc + 4;
    assign dnpc = jump ? {ALU_result[31:1], 1'b0} : snpc;
    always @(posedge clk) begin
        if(rst) begin
            pc <= 32'h80000000;
        end
        else begin
            pc <= dnpc;
        end
    end

endmodule
