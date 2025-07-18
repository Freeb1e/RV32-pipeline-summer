module memory
#(
    parameter IS_IF = 0
)
(
    input wire [31:0] raddr,
    input wire [31:0] waddr,
    input wire [31:0] wdata,
    input wire [7:0] wmask,
    input wire wen,
    input wire valid,
    output reg [31:0] rdata
);
    import "DPI-C" function int pmem_read(input int raddr, input byte is_IF);
    import "DPI-C" function void pmem_write(input int waddr, input int wdata, input byte wmask, input byte is_IF);

    always @(*) begin
        if (valid) begin // read or write is requested
            rdata = pmem_read(raddr, IS_IF);
            if (wen) begin // write is requested
                // $display("addr: %h", waddr);
                pmem_write(waddr, wdata, wmask, IS_IF);
            end
        end
        else begin
            rdata = 0;
        end
    end

endmodule
