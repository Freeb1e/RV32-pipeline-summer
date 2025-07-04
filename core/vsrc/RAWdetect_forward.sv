module RAWdetect_forward(
    input logic [4:0] type_D,
    input logic [4:0] type_E,
    input logic [4:0] type_M,
    input logic [4:0] type_W,


    input logic [4:0] rs1_D,
    input logic [4:0] rs2_D,
    input logic [4:0] rd_E,
    input logic [4:0] rd_M,
    input logic [4:0] rd_W,

    input logic valid_E,
    input logic ready_E,
    input logic valid_M,
    input logic ready_M,
    input logic valid_W,
    input logic ready_W,

    input logic load_E,
    input logic load_M,

    output logic stall_D,

    input logic [31:0] ALUResult_E,
    input logic [31:0] ALUResult_M,
    input logic [31:0] rdata_M,
    input logic [31:0] wdata,

    output logic [31:0] forward_rs1,
    output logic [31:0] forward_rs2,
    output logic valid_forward_rs1,
    output logic valid_forward_rs2
);

    wire RC_rs1, RC_rs2; // RAW Condition for rs1 and rs2
    wire FC_rs1, FC_rs2; // Forwarding Condition for rs1 and rs2

    wire no_rs2 = |(type_D[2:0]); // I-type, U-type, J-type does not have rs2
    
    wire no_rd_E = |(type_E[4:3]); 
    wire no_rd_M = |(type_M[4:3]);
    wire no_rd_W = |(type_W[4:3]); 

    wire conflict_rs1_E = (rs1_D == rd_E) && (rd_E != 0) && (~no_rd_E);
    wire conflict_rs1_M = (rs1_D == rd_M) && (rd_M != 0) && (~no_rd_M);
    wire conflict_rs1_W = (rs1_D == rd_W) && (rd_W != 0) && (~no_rd_W);
    wire conflict_rs2_E = (rs2_D == rd_E) && (rd_E != 0) && (~no_rd_E);
    wire conflict_rs2_M = (rs2_D == rd_M) && (rd_M != 0) && (~no_rd_M);
    wire conflict_rs2_W = (rs2_D == rd_W) && (rd_W != 0) && (~no_rd_W);

    wire idle_E = (~valid_E) & ready_E;
    wire idle_M = (~valid_M) & ready_M;
    wire idle_W = (~valid_W) & ready_W;

    wire RC_rs1_E = (~idle_E) & conflict_rs1_E;
    wire RC_rs1_M = (~idle_M) & conflict_rs1_M;
    wire RC_rs1_W = (~idle_W) & conflict_rs1_W;
    wire RC_rs2_E = (~no_rs2) & (~idle_E) & conflict_rs2_E;
    wire RC_rs2_M = (~no_rs2) & (~idle_M) & conflict_rs2_M;
    wire RC_rs2_W = (~no_rs2) & (~idle_W) & conflict_rs2_W;

    assign RC_rs1 = RC_rs1_E | RC_rs1_M | RC_rs1_W;
    assign RC_rs2 = RC_rs2_E | RC_rs2_M | RC_rs2_W;

    wire FC_rs1_E = RC_rs1_E & (~load_E);
    wire FC_rs1_M = RC_rs1_M & valid_M;
    wire FC_rs1_W = RC_rs1_W;
    wire FC_rs2_E = RC_rs2_E & (~load_E);
    wire FC_rs2_M = RC_rs2_M & valid_M;
    wire FC_rs2_W = RC_rs2_W;

    assign FC_rs1 = FC_rs1_E | FC_rs1_M | FC_rs1_W;
    assign FC_rs2 = FC_rs2_E | FC_rs2_M | FC_rs2_W;

    // Stall condition: if any of the rs1 or rs2 is in conflict and not forwarded
    assign stall_D = (RC_rs1_E & (~FC_rs1_E)) | 
                     (RC_rs1_M & (~FC_rs1_M)) | 
                     (RC_rs1_W & (~FC_rs1_W)) |
                     (RC_rs2_E & (~FC_rs2_E)) | 
                     (RC_rs2_M & (~FC_rs2_M)) | 
                     (RC_rs2_W & (~FC_rs2_W));
    
    wire [31:0] wdata_E = ALUResult_E;
    wire [31:0] wdata_M = load_M ? rdata_M : ALUResult_M;
    wire [31:0] wdata_W = wdata;

    assign forward_rs1 = (FC_rs1_E) ? wdata_E :
                        (FC_rs1_M) ? wdata_M :
                        (FC_rs1_W) ? wdata_W : 32'b0;
    
    assign forward_rs2 = (FC_rs2_E) ? wdata_E :
                        (FC_rs2_M) ? wdata_M :
                        (FC_rs2_W) ? wdata_W : 32'b0;
    
    assign valid_forward_rs1 = FC_rs1;
    assign valid_forward_rs2 = FC_rs2;

endmodule
