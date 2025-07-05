`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/22/2025 11:42:01 AM
// Design Name: 
// Module Name: dram_driver
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module dram_driver(
    input  logic         clk				,

    input  logic [17:0]  perip_addr			,
    input  logic [31:0]  perip_wdata		,
	input  logic [1:0]	 perip_mask			,
    input  logic         dram_wen           ,
    output logic [31:0]  perip_rdata		
);
    logic [15:0] dram_addr;
    logic [ 1:0] offset;
    logic [31:0] dram_data, dram_rdata_raw, dout;
    logic [ 3:0] byte_wea;  // 4位字节写使能信号

    assign dram_addr = perip_addr[17:2];
    assign offset = perip_addr[1:0];
    assign perip_rdata = dout;
    // 根据mask和offset对写数据进行对齐
    always_comb begin
        case (perip_mask)
            2'b00: begin // sb - 字节写入，需要将数据放到正确的字节位置
                case (offset)
                    2'b00: dram_data = {24'b0, perip_wdata[7:0]};           // 数据放在[7:0]
                    2'b01: dram_data = {16'b0, perip_wdata[7:0], 8'b0};     // 数据放在[15:8]
                    2'b10: dram_data = {8'b0, perip_wdata[7:0], 16'b0};     // 数据放在[23:16]
                    2'b11: dram_data = {perip_wdata[7:0], 24'b0};           // 数据放在[31:24]
                    default: dram_data = perip_wdata;
                endcase
            end
            2'b01: begin // sh - 半字写入，需要将数据放到正确的半字位置
                case (offset[1])
                    1'b0: dram_data = {16'b0, perip_wdata[15:0]};           // 数据放在[15:0]
                    1'b1: dram_data = {perip_wdata[15:0], 16'b0};           // 数据放在[31:16]
                    default: dram_data = perip_wdata;
                endcase
            end
            2'b10: dram_data = perip_wdata;  // sw - 字写入，直接使用原数据
            default: dram_data = perip_wdata;
        endcase
    end

    // DRAM Mem_DRAM (
    //     .clk        (clk),
    //     .a          (dram_addr),
    //     .spo        (dram_rdata_raw),
    //     .we         (dram_wen),
    //     .d          (dram_data)
    // );
blk_mem_gen_0 BRAM_instance (
        .clka       (clk),          // 时钟
        .wea        (byte_wea),     // 4位字节写使能
        .addra      (dram_addr),    // 地址
        .dina       (dram_data),    // 写数据
        .douta      (dram_rdata_raw) // 读数据
    );
    
    // 生成4位字节写使能信号
    always_comb begin
        byte_wea = 4'b0000;  // 默认不写入
        if (dram_wen) begin
            case (perip_mask)
                2'b00: begin // sb - 字节写入
                    case (offset)
                        2'b00: byte_wea = 4'b0001;  // 写第0字节
                        2'b01: byte_wea = 4'b0010;  // 写第1字节
                        2'b10: byte_wea = 4'b0100;  // 写第2字节
                        2'b11: byte_wea = 4'b1000;  // 写第3字节
                        default: byte_wea = 4'b0000;
                    endcase
                end
                2'b01: begin // sh - 半字写入
                    case (offset[1])
                        1'b0: byte_wea = 4'b0011;  // 写低16位 (字节0,1)
                        1'b1: byte_wea = 4'b1100;  // 写高16位 (字节2,3)
                        default: byte_wea = 4'b0000;
                    endcase
                end
                2'b10: byte_wea = 4'b1111;  // sw - 字写入，写所有4字节
                default: byte_wea = 4'b0000;
            endcase
        end
    end
    
    // dram_rdata_raw process, lh lb
    always_comb begin
        dout = 0;
        case (perip_mask)
            2'b00: // lb/lbu
                case (offset)
                    2'b00:  dout = {24'b0, dram_rdata_raw[7:0]};
                    2'b01:  dout = {24'b0, dram_rdata_raw[15:8]};
                    2'b10:  dout = {24'b0, dram_rdata_raw[23:16]};
                    2'b11:  dout = {24'b0, dram_rdata_raw[31:24]};
                endcase
            2'b01: // lh/lhu
                case (offset[1])
                    1'b0:  dout = {24'b0, dram_rdata_raw[15:0]};
                    1'b1:  dout = {24'b0, dram_rdata_raw[31:16]};
                endcase
            2'b10: dout = dram_rdata_raw;
            default: dout = 0;
        endcase
    end

    // 原来的写入控制部分（已注释，现在通过byte_wea字节写使能实现）
    // dram_data_raw process, sh, sb
    /*
    always_comb begin
        case (perip_mask)
            2'b10: dram_data = perip_wdata;  // sw
            2'b01: begin           // sh
                case (offset[1])
                    1'b0: dram_data = {dram_rdata_raw[31:16], perip_wdata[15:0]};
                    1'b1: dram_data = {perip_wdata[15:0], dram_rdata_raw[15:0]};
                endcase
            end
            2'b00: begin           // sb
                case (offset)
                    2'b00: dram_data = {dram_rdata_raw[31:8], perip_wdata[7:0]};
                    2'b01: dram_data = {dram_rdata_raw[31:16], perip_wdata[7:0], dram_rdata_raw[7:0]};
                    2'b10: dram_data = {dram_rdata_raw[31:24], perip_wdata[7:0], dram_rdata_raw[15:0]};
                    2'b11: dram_data = {perip_wdata[7:0], dram_rdata_raw[23:0]};
                endcase
            end
            default: dram_data = perip_wdata;
        endcase
    end
    */
endmodule
