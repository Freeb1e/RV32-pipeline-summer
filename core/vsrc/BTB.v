// Branch Target Buffer - Set-Associative Cache
// 用于建立PC值与跳转指令及其跳转地址之间的映射关系
/* verilator lint_off UNUSEDSIGNAL */
module BTB(
        input wire clk,
        input wire rst,

        /* 时序逻辑， 更新buffer */
        input wire valid_in, // 是否有新的跳转指令
        input wire [31:0] branch_PC, // 跳转指令的PC值
        input wire [32:0] branch_target, // 跳转指令的目标地址

        /* 组合逻辑 */
        input wire [31:0] PC_in, // 需要判断的PC值
        output wire hit, // 是否命中跳转
        output wire [32:0] target_addr // 跳转目标地址
    );
    /* verilator lint_on UNUSEDSIGNAL */

    // BTB参数定义 - 组相联配置
    parameter SETS = 32;           // 组数，必须是2的幂
    parameter WAYS = 4;            // 每组的路数 (4路组相联)
    /* verilator lint_off UNUSEDPARAM */
    parameter BTB_SIZE = SETS * WAYS;  // 总大小 = 32 * 4 = 128
    /* verilator lint_on UNUSEDPARAM */
    parameter SET_WIDTH = $clog2(SETS);  // 组索引位宽
    parameter TAG_WIDTH = 32 - SET_WIDTH - 2;  // 标签位宽

    // BTB表项定义 - 分组存储
    reg [TAG_WIDTH-1:0] btb_tags [SETS-1:0][WAYS-1:0];    // 标签数组
    reg [32:0] btb_targets [SETS-1:0][WAYS-1:0];          // 目标地址数组
    reg btb_valid [SETS-1:0][WAYS-1:0];                   // 有效位数组
    reg [1:0] lru_counter [SETS-1:0][WAYS-1:0];           // LRU计数器 (2位)

    // Wire信号声明
    wire [SET_WIDTH-1:0] lookup_set;
    wire [TAG_WIDTH-1:0] lookup_tag;
    wire [SET_WIDTH-1:0] update_set;
    wire [TAG_WIDTH-1:0] update_tag;

    // 各路的命中信号
    wire [WAYS-1:0] way_hits;
    wire [WAYS-1:0] way_valid;
    reg [1:0] hit_way;
    reg [32:0] hit_target;

    // Wire信号赋值
    // BTB组索引计算 (使用PC的低位，忽略字节偏移)
    assign lookup_set = PC_in[SET_WIDTH+1:2];
    assign lookup_tag = PC_in[31:SET_WIDTH+2];

    assign update_set = branch_PC[SET_WIDTH+1:2];
    assign update_tag = branch_PC[31:SET_WIDTH+2];

    // 查找逻辑 - 检查各路是否命中
    genvar way;
    generate
        for (way = 0; way < WAYS; way = way + 1) begin : way_check
            assign way_valid[way] = btb_valid[lookup_set][way];
            assign way_hits[way] = way_valid[way] && (btb_tags[lookup_set][way] == lookup_tag);
        end
    endgenerate

    // 命中检测和目标地址选择
    always @(*) begin
        hit_way = 2'b0;
        hit_target = 33'b0;

        // 优先级编码器：检查哪一路命中
        if (way_hits[0]) begin
            hit_way = 2'd0;
            hit_target = btb_targets[lookup_set][0];
        end
        else if (way_hits[1]) begin
            hit_way = 2'd1;
            hit_target = btb_targets[lookup_set][1];
        end
        else if (way_hits[2]) begin
            hit_way = 2'd2;
            hit_target = btb_targets[lookup_set][2];
        end
        else if (way_hits[3]) begin
            hit_way = 2'd3;
            hit_target = btb_targets[lookup_set][3];
        end
    end

    // 输出赋值
    assign hit = |way_hits;  // 任意一路命中即为命中
    assign target_addr = hit_target;

    // LRU替换策略：找到最久未使用的路
    reg [1:0] replace_way;
    always @(*) begin
        replace_way = 2'd0;  // 默认替换第0路

        // 找到LRU计数器值最大的路（最久未使用）
        if (lru_counter[update_set][1] >= lru_counter[update_set][0] &&
                lru_counter[update_set][1] >= lru_counter[update_set][2] &&
                lru_counter[update_set][1] >= lru_counter[update_set][3]) begin
            replace_way = 2'd1;
        end
        else if (lru_counter[update_set][2] >= lru_counter[update_set][0] &&
                 lru_counter[update_set][2] >= lru_counter[update_set][1] &&
                 lru_counter[update_set][2] >= lru_counter[update_set][3]) begin
            replace_way = 2'd2;
        end
        else if (lru_counter[update_set][3] >= lru_counter[update_set][0] &&
                 lru_counter[update_set][3] >= lru_counter[update_set][1] &&
                 lru_counter[update_set][3] >= lru_counter[update_set][2]) begin
            replace_way = 2'd3;
        end

        // 如果有无效的路，优先使用无效路
        if (!btb_valid[update_set][0]) begin
            replace_way = 2'd0;
        end
        else if (!btb_valid[update_set][1]) begin
            replace_way = 2'd1;
        end
        else if (!btb_valid[update_set][2]) begin
            replace_way = 2'd2;
        end
        else if (!btb_valid[update_set][3]) begin
            replace_way = 2'd3;
        end
    end

    // BTB更新逻辑
    integer i, j;
    always @(posedge clk) begin
        if (rst) begin
            // 复位时清空BTB表
            for (i = 0; i < SETS; i = i + 1) begin
                for (j = 0; j < WAYS; j = j + 1) begin
                    btb_valid[i][j] <= 1'b0;
                    btb_tags[i][j] <= {TAG_WIDTH{1'b0}};
                    btb_targets[i][j] <= 33'b0;
                    lru_counter[i][j] <= 2'b0;
                end
            end
        end
        else begin
            // 更新LRU计数器 - 访问时重置命中路的计数器，其他路+1
            if (hit) begin
                for (j = 0; j < WAYS; j = j + 1) begin
                    if (j[1:0] == hit_way) begin
                        lru_counter[lookup_set][j] <= 2'b0;  // 命中路重置为0
                    end
                    else if (lru_counter[lookup_set][j] < 2'b11) begin
                        lru_counter[lookup_set][j] <= lru_counter[lookup_set][j] + 1'b1;  // 其他路+1
                    end
                end
            end

            // 有新的跳转指令时，更新BTB表
            if (valid_in) begin
                // 检查是否已经存在该PC的表项
                reg [1:0] existing_way;
                reg found_existing;

                found_existing = 1'b0;
                existing_way = 2'd0;

                // 查找是否已存在
                for (j = 0; j < WAYS; j = j + 1) begin
                    if (btb_valid[update_set][j] &&
                            btb_tags[update_set][j] == update_tag) begin
                        found_existing = 1'b1;
                        existing_way = j[1:0];
                    end
                end

                if (found_existing) begin
                    // 更新已存在的表项
                    btb_targets[update_set][existing_way] <= branch_target;
                    // 重置该路的LRU计数器
                    lru_counter[update_set][existing_way] <= 2'b0;
                    for (j = 0; j < WAYS; j = j + 1) begin
                        if (j[1:0] != existing_way && lru_counter[update_set][j] < 2'b11) begin
                            lru_counter[update_set][j] <= lru_counter[update_set][j] + 1'b1;
                        end
                    end
                end
                else begin
                    // 添加新表项，使用LRU替换策略
                    btb_valid[update_set][replace_way] <= 1'b1;
                    btb_tags[update_set][replace_way] <= update_tag;
                    btb_targets[update_set][replace_way] <= branch_target;
                    // 重置新添加路的LRU计数器
                    lru_counter[update_set][replace_way] <= 2'b0;
                    for (j = 0; j < WAYS; j = j + 1) begin
                        if (j[1:0] != replace_way && lru_counter[update_set][j] < 2'b11) begin
                            lru_counter[update_set][j] <= lru_counter[update_set][j] + 1'b1;
                        end
                    end
                end
            end
        end
    end

    always @(hit) begin
        if(hit) begin
            // $display("BTB Hit: PC = %h, Target = %h", PC_in, target_addr);
        end
    end

    // 未使用信号位注释
    // PC_in[1:0] 和 branch_PC[1:0] 未使用是正常的，因为是字节偏移
    /* verilator lint_off UNUSEDSIGNAL */

endmodule
