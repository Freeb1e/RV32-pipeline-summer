interface AXI4Lite_Interface #(parameter ADDR_WIDTH = 32, parameter DATA_WIDTH = 32);

    logic [ADDR_WIDTH-1:0]  araddr;
    logic                   arvalid;
    logic                   arready;

    logic [DATA_WIDTH-1:0]  rdata;
    logic [1:0]             rresp;
    logic                   rvalid;
    logic                   rready;

    logic [ADDR_WIDTH-1:0]  awaddr;
    logic                   awvalid;
    logic                   awready;

    logic [DATA_WIDTH-1:0]  wdata;
    logic [3:0]             wstrb;
    logic                   wvalid;
    logic                   wready;

    logic [1:0]             bresp;
    logic                   bvalid;
    logic                   bready;

    modport master (
        output araddr, arvalid, rready, awaddr, awvalid, wdata, wstrb, wvalid, bready,
        input  arready, rdata, rresp, rvalid, awready, wready, bresp, bvalid
    );

    modport slave (
        input  araddr, arvalid, rready, awaddr, awvalid, wdata, wstrb, wvalid, bready,
        output arready, rdata, rresp, rvalid, awready, wready, bresp, bvalid
    );
endinterface
