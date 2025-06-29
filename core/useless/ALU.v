module ALU(
    input [2:0] mode,
    input [31:0] A,
    input [31:0] B,
    input Cin,
    output zero,
    output wire overflow,
    output wire Cout,
    output wire [31:0] result
);
    wire add_overflow, sub_overflow;
    wire add_Cout, sub_Cout;
    wire [31:0] add_result, sub_result;

    assign zero = ~(|result);
    adder adder_inst(
        .A(A),
        .B(B),
        .Cin(Cin),
        .sum(add_result),
        .Cout(add_Cout),
        .overflow(add_overflow)
    );
    adder sub_inst(
        .A(A),
        .B(~B),
        .Cin(1),
        .sum(sub_result),
        .Cout(sub_Cout),
        .overflow(sub_overflow)
    );

    assign Cout = mode == 3'b000 ? add_Cout :
                  mode == 3'b001 ? sub_Cout : 1'b0;

    // output declaration of module MuxKeyWithDefault
    wire [32:0] out;
    MuxKeyWithDefault #(8, 3, 33) u_MuxKeyWithDefault(
        .out         	(out          ),
        .key         	(mode          ),
        .default_out 	(33'b0  ),
        .lut         	({3'b000, add_overflow, add_result,
                          3'b001, sub_overflow, sub_result,
                          3'b010, 1'b0, $signed(A)>>>B[4:0],
                          3'b011, 1'b0, A&B,
                          3'b100, 1'b0, A|B,
                          3'b101, 1'b0, A^B,
                          3'b110, 1'b0, A<<B[4:0],
                          3'b111, 1'b0, A>>B[4:0]
                        })
    );

    assign {overflow, result} = out;
    
endmodule

module adder(
    input [31:0] A,
    input [31:0] B,
    input Cin,
    output [31:0] sum,
    output Cout,
    output overflow
);
    assign {Cout, sum} = A + B + {31'b0,Cin};
    assign overflow = (A[31]&B[31]&~sum[31]) | (~A[31]&~B[31]&sum[31]);
endmodule

