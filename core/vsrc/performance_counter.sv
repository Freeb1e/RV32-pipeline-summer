module performance_counter_top (
    input logic clk,
    input logic reset,

    // if fetch
    input logic IF_fetched

    // load/store fetch

);

endmodule



module performance_counter (
    input logic clk,
    input logic reset,

    input logic IF_fetched,
    input logic LS_fetched,
    input logic EX_done,
    input logic instr_calc,
    input logic instr_mem,

    input stop_sim
);

    // IF取到指令
    logic [31:0] IF_count;
    always @(posedge clk) begin
        if (reset) begin
            IF_count <= 0;
        end else if (IF_fetched) begin
            IF_count <= IF_count + 1;
        end
    end

    // LS取到数据
    logic [31:0] LS_count;
    always @(posedge clk) begin
        if (reset) begin
            LS_count <= 0;
        end else if (LS_fetched) begin
            LS_count <= LS_count + 1;
        end
    end

    // EX完成计算
    logic [31:0] EX_count;
    always @(posedge clk) begin
        if (reset) begin
            EX_count <= 0;
        end else if (EX_done) begin
            EX_count <= EX_count + 1;
        end
    end

    // 指令计算
    logic [31:0] instr_calc_count;
    always @(posedge clk) begin
        if (reset) begin
            instr_calc_count <= 0;
        end else if (instr_calc) begin
            instr_calc_count <= instr_calc_count + 1;
        end
    end

    // 访存指令计数
    logic [31:0] instr_mem_count;
    always @(posedge clk) begin
        if (reset) begin
            instr_mem_count <= 0;
        end else if (instr_mem) begin
            instr_mem_count <= instr_mem_count + 1;
        end
    end

    // CPU停止时输出数据
    always @(posedge clk) begin
        if (stop_sim) begin
            $display("Performance Counter Results:");
            $display("IF Fetched Instructions: %d", IF_count);
            $display("LS Fetched Data: %d", LS_count);
            $display("EX Completed Instructions: %d", EX_count);
            $display("Instruction Calculations: %d", instr_calc_count);
            $display("Instruction Memory Accesses: %d", instr_mem_count);
            $finish;
        end
    end

endmodule
