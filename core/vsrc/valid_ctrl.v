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
        output valid_WB_rise,
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
    // Load-Word数据冲突检测
    assign lwstall = (ResultSrc_E && RegWrite_E && ((Rs1_D == Rd_E) || (Rs2_D == Rd_E)));


    wire mem_waiting;  // RAMBUFFER启用时，使用寄存器来跟踪访存等待状态

    reg mem_waiting_buf; 
    reg mem_waiting_bufbuf ;// 用于跟踪当前访存操作状态
    always @(posedge clk) begin
        if (rst) begin
            mem_waiting_buf <= 1'b0;
            mem_waiting_bufbuf <= 1'b0;
        end
        else begin
            mem_waiting_buf <= mem_waiting;
            mem_waiting_bufbuf <= mem_waiting_buf;  // 更新buf状态
        end
    end
    assign mem_waiting =MemRead_M&&(~(mem_waiting_bufbuf&&mem_waiting_buf));

    wire ready_W, ready_M, ready_E, ready_D, ready_F;

    assign ready_W = ~mem_waiting;

    assign ready_M = ready_W;

    assign ready_E = (~lwstall) & ready_M;

    assign ready_D = ready_E;

    // Fetch级ready条件：后级(Decode)必须ready
    assign ready_F = ready_D;

    // valid信号：控制流水线寄存器的使能
    // 当ready时，对应的流水线寄存器可以更新
    assign valid_PC = ready_F;      // PC寄存器使能
    assign valid_F = ready_D;       // F/D寄存器使能
    assign valid_D = ready_E;       // D/E寄存器使能
    assign valid_E = ready_M;       // E/M寄存器使能
    assign valid_M = ready_W;       // M/W寄存器使能

    // flash信号的握手逻辑：
    // flash条件：当前级不ready且数据能流向下级时，会产生重复指令，需要冲刷
    // 分支跳转导致的冲刷（优先级最高）
    assign flash_D = PCSrc_E | (~ready_D & ready_E);   // 分支跳转 或 (D级不ready且E级ready)
    assign flash_E = (PCSrc_E&&ready_E) | (~ready_E & ready_M);   // 分支跳转 或 (E级不ready且M级ready)
    assign flash_W = (~ready_W & 1'b1);                // W级不ready且总是有数据要写回
    //assign valid_WB_rise = ready_W;
assign valid_WB_rise=1'b1;
`else
    // assign valid_F = ~(lwstall);
    // assign valid_PC = ~(lwstall);
    // assign lwstall= (ResultSrc_E && RegWrite_E && ((Rs1_D == Rd_E) || (Rs2_D == Rd_E)));
    // assign valid_D = 1'b1;
    // assign valid_E = 1'b1;
    // assign valid_M = 1'b1;
    // assign flash_D = PCSrc_E;
    // assign flash_E = lwstall|PCSrc_E;


    // Load-Word数据冲突检测
    assign lwstall = (ResultSrc_E && RegWrite_E && ((Rs1_D == Rd_E) || (Rs2_D == Rd_E)));

    wire mem_waiting;

    assign mem_waiting = 1'b0;  // RAMBUFFER未启用时，默认没有等待状态

    wire ready_W, ready_M, ready_E, ready_D, ready_F;

    assign ready_W = ~mem_waiting;

    assign ready_M = ready_W;

    assign ready_E = (~lwstall) & ready_M;

    assign ready_D = ready_E;

    // Fetch级ready条件：后级(Decode)必须ready
    assign ready_F = ready_D;

    // valid信号：控制流水线寄存器的使能
    // 当ready时，对应的流水线寄存器可以更新
    assign valid_PC = ready_F;      // PC寄存器使能
    assign valid_F = ready_D;       // F/D寄存器使能
    assign valid_D = ready_E;       // D/E寄存器使能
    assign valid_E = ready_M;       // E/M寄存器使能
    assign valid_M = ready_W;       // M/W寄存器使能

    // flash信号的握手逻辑：
    // flash条件：当前级不ready且数据能流向下级时，会产生重复指令，需要冲刷
    // 分支跳转导致的冲刷（优先级最高）
    assign flash_D = PCSrc_E | (~ready_D & ready_E);   // 分支跳转 或 (D级不ready且E级ready)
    assign flash_E = PCSrc_E | (~ready_E & ready_M);   // 分支跳转 或 (E级不ready且M级ready)
    //assign flash_W = (~ready_W & 1'b1);                // W级不ready且总是有数据要写回
    //assign valid_WB_rise = ready_W;
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
