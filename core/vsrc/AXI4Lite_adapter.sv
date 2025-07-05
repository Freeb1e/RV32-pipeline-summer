module AXI4Lite_adapter(
    input master_awready,
    output master_awvalid,
    output [31:0] master_awaddr,
    input master_wready,
    output master_wvalid,
    output [31:0] master_wdata,
    output [3:0] master_wstrb,
    output master_bready,
    input master_bvalid,
    input [1:0] master_bresp,
    input master_arready,
    output master_arvalid,
    output [31:0] master_araddr,
    output master_rready,
    input master_rvalid,
    input [1:0] master_rresp,
    input [31:0] master_rdata,

    output slave_awready,
    input slave_awvalid,
    input [31:0] slave_awaddr,
    output slave_wready,
    input slave_wvalid,
    input [31:0] slave_wdata,
    input [3:0] slave_wstrb,
    input slave_bready,
    output slave_bvalid,
    output [1:0] slave_bresp,
    output slave_arready,
    input slave_arvalid,
    input [31:0] slave_araddr,
    input slave_rready,
    output slave_rvalid,
    output [1:0] slave_rresp,
    output [31:0] slave_rdata,

    AXI4Lite_Interface.slave master,
    AXI4Lite_Interface.master slave
);
    assign master.awready = master_awready;
    assign master_awvalid = master.awvalid;
    assign master_awaddr = master.awaddr;
    assign master.wready = master_wready;
    assign master_wvalid = master.wvalid;
    assign master_wdata = master.wdata;
    assign master_wstrb = master.wstrb;
    assign master_bready = master.bready;
    assign master.bvalid = master_bvalid;
    assign master.bresp = master_bresp;
    assign master.arready = master_arready;
    assign master_arvalid = master.arvalid;
    assign master_araddr = master.araddr;
    assign master_rready = master.rready;
    assign master.rvalid = master_rvalid;
    assign master.rresp = master_rresp;
    assign master.rdata = master_rdata;

    assign slave_awready = slave.awready;
    assign slave.awvalid = slave_awvalid;
    assign slave.awaddr = slave_awaddr;
    assign slave_wready = slave.wready;
    assign slave.wvalid = slave_wvalid;
    assign slave.wdata = slave_wdata;
    assign slave.wstrb = slave_wstrb;
    assign slave.bready = slave_bready;
    assign slave_bvalid = slave.bvalid;
    assign slave_bresp = slave.bresp;
    assign slave_arready = slave.arready;
    assign slave.arvalid = slave_arvalid;
    assign slave.araddr = slave_araddr;
    assign slave.rready = slave_rready;
    assign slave_rvalid = slave.rvalid;
    assign slave_rresp = slave.rresp;
    assign slave_rdata = slave.rdata;

endmodule
