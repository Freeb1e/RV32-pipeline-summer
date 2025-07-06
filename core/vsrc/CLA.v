`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/01/23 20:15:10
// Design Name: 
// Module Name: CLA
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
module CLA_32(
    input [31:0]A,
    input [31:0]B,
    input Cin,
    output [32:0]Sum
    );

    // 声明内部信号
    wire c16;

    // 16位超前进位加法器实例
    Adder16  Adder16_inst0 (
        .a(A[15:0]),
        .b(B[15:0]),
        .cin(Cin),
        .s(Sum[15:0]),
        .cout(c16)
    );
    Adder16  Adder16_inst1 (
        .a(A[31:16]),
        .b(B[31:16]),
        .cin(c16),
        .s(Sum[31:16]),
        .cout(Sum[32])
    );

endmodule

module Adder16(
    input [15:0]a,
    input [15:0]b,
    input cin,
    output [15:0]s,
    output cout
    );
    // 声明内部信号
    wire c4, c8, c12, c16;
    wire [15:0] p, g;
   
    // 4位加法器实例
    Adder4  Adder4_inst0 (
        .a(a[3:0]),
        .b(b[3:0]),
        .cin(cin),
        .s(s[3:0]),
        // .cout(),
        .p(p[3:0]),
        .g(g[3:0])
    );
    Adder4  Adder4_inst1 (
        .a(a[7:4]),
        .b(b[7:4]),
        .cin(c4),
        .s(s[7:4]),
        // .cout(),
        .p(p[7:4]),
        .g(g[7:4])
    );
    Adder4  Adder4_inst2 (
        .a(a[11:8]),
        .b(b[11:8]),
        .cin(c8),
        .s(s[11:8]),
        // .cout(),
        .p(p[11:8]),
        .g(g[11:8])
    );
    Adder4  Adder4_inst3 (
        .a(a[15:12]),
        .b(b[15:12]),
        .cin(c12),
        .s(s[15:12]),
        // .cout(),
        .p(p[15:12]),
        .g(g[15:12])
    );

    // 进位链信号产生实例
    LookHeadCarryer4  LookHeadCarryer4_inst (
        .p(p),
        .g(g),
        .cin(cin),
        .c4(c4),
        .c8(c8),
        .c12(c12),
        .c16(c16)
    );

    assign cout = c16;

endmodule


module LookHeadCarryer4(
    input [15:0]p,
    input [15:0]g,
    input cin,
    output c4,
    output c8,
    output c12,
    output c16
    );
    wire pm0, pm1, pm2, pm3;
    wire gm0, gm1, gm2, gm3;

    assign pm0 = p[3]  & p[2]  & p[1]  & p[0];
    assign pm1 = p[7]  & p[6]  & p[5]  & p[4];
    assign pm2 = p[11] & p[10] & p[9]  & p[8];
    assign pm3 = p[15] & p[14] & p[13] & p[12];
    assign gm0 = g[3]  | p[3]&g[2]   | p[3]&p[2]&g[1]    | p[3]&p[2]&p[1]&g[0];
    assign gm1 = g[7]  | p[7]&g[6]   | p[7]&p[6]&g[5]    | p[7]&p[6]&p[5]&g[4];
    assign gm2 = g[11] | p[11]&g[10] | p[11]&p[10]&g[9]  | p[11]&p[10]&p[9]&g[8];
    assign gm3 = g[15] | p[15]&g[14] | p[15]&p[14]&g[13] | p[15]&p[14]&p[13]&g[12];

    assign c4  = gm0 | pm0 & cin;
    assign c8  = gm1 | pm1 & c4;
    assign c12 = gm2 | pm2 & c8;
    assign c16 = gm3 | pm3 & c12;

endmodule


module Adder4(
    input [3:0]a,
    input [3:0]b,
    input cin,
    output [3:0]s,

    output [3:0]p,
    output [3:0]g
    );
 
    wire c0, c1, c2, c3;
    wire p0, p1, p2, p3;
    wire g0, g1, g2, g3;

    assign g0 = a[0] & b[0];
    assign g1 = a[1] & b[1];
    assign g2 = a[2] & b[2];
    assign g3 = a[3] & b[3];


    assign p0 = a[0] ^ b[0];
    assign p1 = a[1] ^ b[1];
    assign p2 = a[2] ^ b[2];
    assign p3 = a[3] ^ b[3];


    assign c0 = cin;
    assign c1 = g0 | p0&c0;
    assign c2 = g1 | p1&g0 | p1&p0&c0;
    assign c3 = g2 | p2&g1 | p2&p1&g0 | p2&p1&p0&c0;


    assign s[0] = p0 ^ c0;
    assign s[1] = p1 ^ c1;
    assign s[2] = p2 ^ c2;
    assign s[3] = p3 ^ c3;

    assign p = {p3,p2,p1,p0};
    assign g = {g3,g2,g1,g0};

endmodule
