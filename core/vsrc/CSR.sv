
module CSR (
    input  logic         clk,
    input  logic         rst,
    input  logic         csr_we,        
    input  logic [11:0]   csr_waddr,      
    input  logic [31:0]  csr_wdata,  

    input  logic [11:0]   csr_raddr,
    output logic [31:0]  csr_rdata
);
    localparam MTVEC_IDX   = 2'd0;
    localparam MSTATUS_IDX = 2'd1;
    localparam MEPC_IDX    = 2'd2;
    localparam MCAUSE_IDX  = 2'd3;

    localparam MTVEC_ADDR = 12'h305;
    localparam MSTATUS_ADDR = 12'h300;
    localparam MEPC_ADDR = 12'h341;
    localparam MCAUSE_ADDR = 12'h342;

    reg [31:0] mtvec, mstatus, mepc, mcause;
    reg [1:0]  csr_ridx, csr_widx;
    always_comb begin
        case(csr_raddr)
            MTVEC_ADDR: csr_ridx = MTVEC_IDX;
            MSTATUS_ADDR: csr_ridx = MSTATUS_IDX;
            MEPC_ADDR: csr_ridx = MEPC_IDX;
            MCAUSE_ADDR: csr_ridx = MCAUSE_IDX;
            default: csr_ridx = 2'd0;
        endcase
        case(csr_waddr)
            MTVEC_ADDR: csr_widx = MTVEC_IDX;
            MSTATUS_ADDR: csr_widx = MSTATUS_IDX;
            MEPC_ADDR: csr_widx = MEPC_IDX;
            MCAUSE_ADDR: csr_widx = MCAUSE_IDX;
            default: csr_widx = 2'd0;
        endcase
    end

    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            mtvec <= 32'h0000_0000;
            mstatus <= 32'h0000_1800;
            mepc <= 32'h0000_0000;
            mcause <= 32'h0000_0000;
        end else begin
            if(csr_we) begin
                case(csr_widx)
                    MTVEC_IDX: mtvec <= csr_wdata;
                    MSTATUS_IDX: mstatus <= csr_wdata;
                    MEPC_IDX: mepc <= csr_wdata;
                    MCAUSE_IDX: mcause <= csr_wdata;
                    default: ;
                endcase
            end
        end
    end

    // CSR读操作
    always_comb begin
        case(csr_ridx)
            MTVEC_IDX: csr_rdata = mtvec;
            MSTATUS_IDX: csr_rdata = mstatus;
            MEPC_IDX: csr_rdata = mepc;
            MCAUSE_IDX: csr_rdata = mcause;
            default: csr_rdata = 32'h0000_0000;
        endcase
    end

`ifdef SIMULATION
    export "DPI-C" function get_CSR;
    function void get_CSR();
        output int csr_mtvec;
        output int csr_mstatus;
        output int csr_mepc;
        output int csr_mcause;
        csr_mtvec = mtvec;
        csr_mstatus = mstatus;
        csr_mepc = mepc;
        csr_mcause = mcause;
    endfunction
`endif
endmodule
