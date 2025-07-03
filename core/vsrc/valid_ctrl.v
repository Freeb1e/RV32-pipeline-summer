`include "pipeline_config.v"
module valid_ctrl(
        input          clk,
        input          rst,

        input [1:0] ResultSrc_E_raw,
        input RegWrite_E,

        input [4:0] Rs1_D,
        input [4:0] Rs2_D,
        input [4:0] Rd_E,
        input PCSrc_E,

`ifdef RAMBUFFER
        input MemRead_E,
        output flash_W,
        input MemRead_M,
`endif
        output  valid_F,
        output  valid_D,
        output  valid_E,
        output  valid_M,
        output  valid_PC,
        output flash_D,
        output flash_E
    );
`ifdef pipeline_mode

    wire ResultSrc_E;
    assign ResultSrc_E = (ResultSrc_E_raw ==2'b01)? 1'b1:1'b0;
    wire lwstall;
`ifdef RAMBUFFER
    wire lwstall_trig;
    assign lwstall_trig=MemRead_E;
    reg lwstall_buf;
    always @(posedge clk) begin
        if (rst) begin
            lwstall_buf <= 1'b0;
        end else begin
            lwstall_buf <= lwstall_trig;
        end
    end
    assign lwstall = lwstall_buf | lwstall_trig;

    assign valid_F = ~(lwstall);
    assign valid_PC = ~(lwstall);
    assign valid_D =1'b1;
    assign valid_E =~(lwstall_buf);
    assign valid_M =1'b1;

    assign flash_D = PCSrc_E;
    assign flash_E = PCSrc_E| lwstall;
    assign flash_W = lwstall_buf;

`else
    assign valid_F = ~(lwstall);
    assign valid_PC = ~(lwstall);
    assign lwstall= (ResultSrc_E && RegWrite_E && ((Rs1_D == Rd_E) || (Rs2_D == Rd_E)));
    assign valid_D = 1'b1;
    assign valid_E = 1'b1;
    assign valid_M = 1'b1;
    assign flash_D = PCSrc_E;
    assign flash_E = lwstall|PCSrc_E;

`endif

    

`else
    always@(posedge clk) begin
        if (rst) begin
            valid_F1 <= 1'b1;
            valid_D <= 1'b0;
            valid_E <= 1'b0;
            valid_M <= 1'b0;
            valid_PC1 <= 1'b0;
        end
        else begin
            valid_D<= valid_F1;
            valid_E<= valid_D;
            valid_M<= valid_E;
            valid_PC1<= valid_M;
            valid_F1<= valid_PC1;
        end
    end
    reg valid_F1;
    reg valid_PC1;
    assign valid_F = valid_F1;
    assign valid_PC = valid_PC1;
    assign flash_D = 1'b0;
    assign flash_E = 1'b0;
    wire lwstall;
    assign lwstall = 1'b0;
`endif

endmodule
