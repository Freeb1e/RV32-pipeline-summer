`include "pipeline_config.v"
module valid_ctrl(
        input          clk,
        input          rst,

        input arready, // AXI4-Lite ADDRESS READ CHANNEL
        input rvalid, // AXI4-LITE READ CHANNEL
        input load_M,
        input stall,
        input Pre_Wrong, // 分支预测错误

        output valid_F,
        output valid_D,
        output reg valid_E,
        output reg valid_M,
        output reg valid_W,
        output ready_F,
        output ready_D,
        output ready_E,
        output ready_M,
        output ready_W

    );
    reg valid_D_reg, valid_E_reg;
    assign valid_F = 1'b1; // 单周期取到指令
    assign valid_D = valid_D_reg & (~stall); // D级valid受stall影响
    always @(posedge clk) begin
        if(rst) begin
            valid_D_reg <= 1'b0;
            valid_E <= 1'b0;
            valid_M <= 1'b0;
            valid_W <= 1'b0;
        end
        else begin
            if(valid_F & ready_D) begin
                valid_D_reg <= ~Pre_Wrong;
            end else if(valid_D & ready_E) begin // 与下游握手完成后取消valid
                valid_D_reg <= 1'b0; 
            end

            if(valid_D & ready_E) begin
                valid_E <= ~Pre_Wrong;
            end else if(valid_E & ready_M) begin
                valid_E <= 1'b0; 
            end

            if(valid_E & ready_M & ((~load_M) | rvalid)) begin // 读阶段rdata有效，握手成功；或非读阶段，直接有效
                valid_M <= 1'b1;
            end else if(valid_M & ready_W) begin 
                valid_M <= 1'b0; 
            end

            if(valid_M & ready_W) begin
                valid_W <= 1'b1;
            end else if(valid_W) begin
                valid_W <= 1'b0; 
            end
        end
    end

    assign ready_W = ~rst; // 总是能单周期写回
    assign ready_M = ready_W ? ((load_M) ? arready : 1'b1) : 1'b0; // 读阶段需要AXI4-Lite地址通道握手，非读阶段直接ready
    assign ready_E = ready_M;
    assign ready_D = (~stall) & ready_E;
    assign ready_F = ready_D; // F级总是ready

endmodule
