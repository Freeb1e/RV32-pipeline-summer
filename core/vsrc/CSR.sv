
module CSR (
    input  logic         clk,
    input  logic         rst,
    input  logic         csr_we,        // CSR写使能
    input  logic [4:0]   csr_addr,      // CSR地址（序号，0~31）
    input  logic [31:0]  csr_wdata,     // CSR写数据
    output logic [31:0]  csr_rdata,    // CSR读数据
    input logic        exception_we,  // 异常写使能
    input logic        mret_en,
    input logic [31:0]  epc_in,        // 异常发生时的程序计数器
    input logic [31:0]  cause_in,       // 异常原因
    input logic [31:0]  mstatus_in,      // JALR指令的目标地址
    output logic [31:0]  mtvec_out,      // CSR读数据
    output logic [31:0]  mstatus_out,        // CSR读数据
    output logic [31:0]  mepc_out        // CSR读数据
);

    // 例化32个CSR寄存器
    logic [31:0] csr_regs [31:0];

    // 定义特殊寄存器序号
    localparam MTVEC_IDX   = 5'd1;
    localparam MSTATUS_IDX = 5'd2;
    localparam MEPC_IDX    = 5'd3;
    localparam MCAUSE_IDX  = 5'd4;

    // 初始化和写操作
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < 32; i++) begin
                csr_regs[i] <= 32'h0;
            end
        end else begin
            // CSR写操作
            if (csr_we) begin
                csr_regs[csr_addr] <= csr_wdata;
            end

            if (exception_we) begin
            csr_regs[MEPC_IDX]   <= epc_in;
            csr_regs[MCAUSE_IDX] <= cause_in;

            if(mret_en) begin
                csr_regs[MTVEC_IDX] <= mstatus_in; // MRET指令时将MTVEC寄存器设置为MSTATUS寄存器的值
            end 
        end
        end
    end

    // CSR读操作
    always_comb begin
        csr_rdata = csr_regs[csr_addr];
        mtvec_out = csr_regs[MTVEC_IDX]; // 输出MEPC寄存器的值
        mepc_out = csr_regs[MEPC_IDX];   // 输出MTVEC寄存器的值
        mstatus_out = csr_regs[MSTATUS_IDX]; // 输出MSTATUS寄存器的值
    end

endmodule