module npc(
    input clk,
    input rst
);

    /* Decode signals */
    wire [4:0] rs1, rs2, rd;
    wire [31:0] imm;
    wire [2:0] funct3;
    wire [6:0] funct7;
    wire [6:0] opcode;
    wire [2:0] ALU_op;
    wire [2:0] rdregsrc;
    wire [1:0] cmp_type;
    wire ALUsrc1;
    wire ALUsrc2;
    wire jump;
    wire branch;

    /* RegisterFile control signals */
    wire wen;
    wire [31:0] rf_wdata;
    wire [31:0] rf_rdata1;
    wire [31:0] rf_rdata2;
    wire [4:0] rf_raddr1;
    wire [4:0] rf_raddr2;

    /* ALU signals */
    wire [31:0] ALU_result;
    wire [31:0] ALU_A;
    wire [31:0] ALU_B;
    wire ALU_Cin;
    wire ALU_zero;
    wire ALU_overflow;
    wire ALU_Cout;
    wire [31:0] ALU_result;

    /* compare signals */
    wire equal;
    wire signed_less;
    wire unsigned_less;

    /* ebreak signal */
    wire stop_sim;

    /* PC signals */
    wire [31:0] pc;
    wire [31:0] snpc;
    wire dir_jump;
    wire branch_judge;
    assign branch_judge = branch ? (funct3 == 3'b000 ? rf_rdata1==rf_rdata2 :
                                    funct3 == 3'b001 ? rf_rdata1!=rf_rdata2 :
                                    funct3 == 3'b101 ? $signed(rf_rdata1)>=$signed(rf_rdata2) :
                                    funct3 == 3'b111 ? rf_rdata1>=rf_rdata2 :
                                    funct3 == 3'b100 ? $signed(rf_rdata1)<$signed(rf_rdata2) :
                                    funct3 == 3'b110 ? rf_rdata1<rf_rdata2 :
                                                       1'b0)
                                    : 1'b0;
    assign dir_jump = jump | (branch_judge);
    

    /* Memory signals */
    wire [31:0] inst;
    reg ivalid;
    wire [31:0] draddr;
    wire [31:0] dwaddr;
    wire [31:0] dwdata;
    wire [7:0] dwmask;
    wire [31:0] drdata;
    wire dvalid;
    wire dwen;
    wire [31:0] drdata_ext;

    /* local signals */
    wire [31:0] cmp_result;

    PC u_PC(
        .clk(clk),
        .rst(rst),
        .jump(dir_jump),
        .ALU_result(ALU_result),
        .pc(pc),
        .snpc(snpc)
    );

    IDU idu_inst(
        .inst(inst),
        .rd(rd),
        .rs1(rs1),
        .rs2(rs2),
        .imm(imm),
        .funct3(funct3),
        .funct7(funct7),
        .opcode(opcode),
        .ALU_op(ALU_op),
        .rdregsrc(rdregsrc),
        .ALUsrc1(ALUsrc1),
        .ALUsrc2(ALUsrc2),
        .jump(jump),
        .branch(branch),
        .cmp_type(cmp_type),
        .dwmask(dwmask),
        .dwen(dwen),
        .dvalid(dvalid),
        .stop_sim(stop_sim)
    );

    assign rf_wdata = rdregsrc == 0 ? ALU_result :
                      rdregsrc == 1 ? drdata_ext :
                      rdregsrc == 2 ? snpc : 
                      rdregsrc == 3 ? cmp_result : 32'b0;

    assign rf_raddr1 = rs1;
    assign rf_raddr2 = rs2;
    assign wen = rdregsrc != 4;
    RegisterFile#(.ADDR_WIDTH(5),.DATA_WIDTH(32)) u_RegisterFile(
        .clk    	(clk     ),
        .rst    	(rst     ),
        .wdata  	(rf_wdata   ),
        .waddr  	(rd   ),
        .wen    	(wen     ),
        .raddr1 	(rf_raddr1  ),
        .raddr2 	(rf_raddr2  ),
        .rdata1 	(rf_rdata1  ),
        .rdata2 	(rf_rdata2  ),
        .ren    	(1'b1     )
    );
    
    assign ALU_A = ALUsrc1 ? pc : rf_rdata1;
    assign ALU_B = ALUsrc2 ? imm : rf_rdata2;
    ALU u_ALU(
        .mode(ALU_op),
        .A(ALU_A),
        .B(ALU_B),
        .Cin(ALU_Cin),
        .zero(ALU_zero),
        .overflow(ALU_overflow),
        .Cout(ALU_Cout),
        .result(ALU_result)
    );
    assign equal = ALU_zero;
    assign signed_less = (~ALU_overflow & ALU_result[31]) | (ALU_overflow & ~ALU_result[31]);
    assign unsigned_less = ~ALU_Cout;
    assign cmp_result = cmp_type==0 ? {31'b0, equal} :
                        cmp_type==1 ? {31'b0, ~equal} :
                        cmp_type==2 ? {31'b0, signed_less} : {31'b0, unsigned_less};
    
    assign ivalid = ~rst;
    /* instruction memory */
    memory inst_mem(
        .raddr 	(pc  ),
        .waddr 	(0    ),
        .wdata 	(0    ),
        .wmask 	(0    ),
        .wen   	(0    ),
        .valid 	(ivalid  ),
        .rdata 	(inst  )
    );

    assign draddr = ALU_result;
    assign dwaddr = ALU_result;
    assign dwdata = rf_rdata2;
    /* data memory */
    memory data_mem(
        .raddr 	(draddr  ),
        .waddr 	(dwaddr  ),
        .wdata 	(dwdata  ),
        .wmask 	(dwmask  ),
        .wen   	(dwen    ),
        .valid 	(dvalid  ),
        .rdata 	(drdata  )
    );
    assign drdata_ext = funct3 == 3'b000 ? {{24{drdata[7]}}, drdata[7:0]} : //lb
                        funct3 == 3'b100 ? {24'b0, drdata[7:0]} : //lbu
                        funct3 == 3'b001 ? {{16{drdata[15]}}, drdata[15:0]} : //lh
                        funct3 == 3'b101 ? {16'b0, drdata[15:0]} : //lhu
                                  drdata; //lw

    export "DPI-C" function get_pc_inst;
    function void get_pc_inst();
        output int cpu_pc;
        output int cpu_inst;
        cpu_pc = pc;
        cpu_inst = inst;
    endfunction

    import "DPI-C" function void ebreak();
    always @ (posedge clk) begin
        if(stop_sim) begin
            ebreak();
        end
    end

endmodule
