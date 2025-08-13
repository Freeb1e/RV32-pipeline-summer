module uart_tx_fifo(
	input 			sys_clk,		//50M系统时钟
	input 			sys_rst_n,		//系统复位
	input	[31:0]	cpu_addr,		//CPU访存地址
	input 			cpu_wr_en_buf,		//CPU写使能
	input	[7:0] 	cpu_wr_data_buf,	//CPU写数据
	output reg 		uart_txd,		//串口发送数据线
	output reg 		tx_done,		//发送完成标志
	output wire		fifo_full		//FIFO满标志，告诉CPU不再接受写入
);

parameter 	SYS_CLK_FRE = 50_000_000;    //50M系统时钟 
//parameter 	BPS = 9_600;                 //波特率9600bps
parameter 	BPS = 25000000;               //波特率115200bps
//localparam	BPS_CNT = SYS_CLK_FRE/BPS;   //传输一位数据所需要的时钟个数
localparam	BPS_CNT = 10; 

// FIFO参数
localparam FIFO_DEPTH = 16;
localparam ADDR_WIDTH = 4;
logic cpu_wr_en; // CPU写使能信号
logic [7:0] cpu_wr_data; // CPU写数据
// always @(posedge sys_clk or negedge sys_rst_n) begin
// 	if (!sys_rst_n) begin
// 		cpu_wr_en <= 1'b0;
// 		cpu_wr_data <= 8'd0;
// 	end else begin
// 		cpu_wr_en <= cpu_wr_en_buf;
// 		cpu_wr_data <= cpu_wr_data_buf;
// 	end
// end
assign cpu_wr_en = cpu_wr_en_buf;
assign cpu_wr_data = cpu_wr_data_buf;
// FIFO缓冲区
reg [7:0] fifo_buffer [FIFO_DEPTH-1:0];
reg [ADDR_WIDTH-1:0] fifo_wr_ptr;
reg [ADDR_WIDTH-1:0] fifo_rd_ptr;
reg [ADDR_WIDTH:0] fifo_cnt;

// UART发送控制信号
reg uart_tx_en;
reg [7:0] uart_tx_data;
wire uart_tx_busy;

// UART发送模块内部信号
reg	uart_tx_en_d0;
reg uart_tx_en_d1;
reg tx_flag;
reg [7:0] uart_data_reg;
reg [15:0] clk_cnt;
reg [3:0] tx_cnt;
wire pos_uart_en_txd;

// CPU写入控制逻辑
wire cpu_write_valid;
assign cpu_write_valid = cpu_wr_en && (cpu_addr == 32'ha00003f8) && (fifo_cnt < FIFO_DEPTH);

// FIFO满标志信号
assign fifo_full = (fifo_cnt >= FIFO_DEPTH);

// FIFO写入逻辑
always @(posedge sys_clk or negedge sys_rst_n) begin
	if (!sys_rst_n) begin
		fifo_wr_ptr <= 0;
		fifo_cnt <= 0;
		fifo_rd_ptr <= 0;
		// FIFO缓冲区初始化
		for (integer i = 0; i < FIFO_DEPTH; i = i + 1) begin
			fifo_buffer[i] <= 8'd0;
		end
	end else if (cpu_write_valid) begin
		fifo_buffer[fifo_wr_ptr] <= cpu_wr_data;
		fifo_wr_ptr <= fifo_wr_ptr + 1;
		fifo_cnt <= fifo_cnt + 1;
	end else if (uart_tx_en  && fifo_cnt > 0) begin
		fifo_cnt <= fifo_cnt - 1;
	end
end

// FIFO读取和发送控制逻辑
assign uart_tx_busy = tx_flag|uart_tx_en|uart_tx_en_d0;

always @(posedge sys_clk or negedge sys_rst_n) begin
	if (!sys_rst_n) begin
		uart_tx_en <= 0;
		uart_tx_data <= 0;
		fifo_rd_ptr <= 0;
	end else if (!uart_tx_busy && fifo_cnt > 1) begin
		uart_tx_data <= fifo_buffer[fifo_rd_ptr];
		uart_tx_en <= 1;
		fifo_rd_ptr <= fifo_rd_ptr + 1;
	end else begin
		uart_tx_en <= 0;
	end
end

// UART发送模块实现（与原uart_tx模块相同）
assign pos_uart_en_txd = uart_tx_en_d0 && (~uart_tx_en_d1);

always @(posedge sys_clk or negedge sys_rst_n) begin
	if (!sys_rst_n) begin
		uart_tx_en_d0 <= 1'b0;
		uart_tx_en_d1 <= 1'b0;		
	end else begin
		uart_tx_en_d0 <= uart_tx_en;
		uart_tx_en_d1 <= uart_tx_en_d0;
	end	
end

always @(posedge sys_clk or negedge sys_rst_n) begin
	if (!sys_rst_n) begin
		tx_flag <= 1'b0;
		uart_data_reg <= 8'd0;
	end else if (pos_uart_en_txd) begin
		uart_data_reg <= uart_tx_data;
		tx_flag <= 1'b1;
	end else if ((tx_cnt == 4'd9) && (clk_cnt == BPS_CNT/2)) begin
		tx_flag <= 1'b0;
		uart_data_reg <= 8'd0;
	end else begin
		uart_data_reg <= uart_data_reg;
		tx_flag <= tx_flag;	
	end
end

always @(posedge sys_clk or negedge sys_rst_n) begin
	if (!sys_rst_n) begin
		clk_cnt <= 16'd0;
		tx_cnt <= 4'd0;
	end else if (tx_flag) begin
		if (clk_cnt < BPS_CNT-1) begin
			clk_cnt <= clk_cnt + 1'b1;
			tx_cnt <= tx_cnt;
		end else begin
			clk_cnt <= 16'd0;
			tx_cnt <= tx_cnt + 1'b1;
		end
	end else begin
		clk_cnt <= 16'd0;
		tx_cnt <= 4'd0;
	end
end

always @(posedge sys_clk or negedge sys_rst_n) begin
	if (!sys_rst_n)
		uart_txd <= 1'b1;
	else if (tx_flag)
		case(tx_cnt)
			4'd0:	uart_txd <= 1'b0;
			4'd1:	uart_txd <= uart_data_reg[0];
			4'd2:	uart_txd <= uart_data_reg[1];
			4'd3:	uart_txd <= uart_data_reg[2];
			4'd4:	uart_txd <= uart_data_reg[3];
			4'd5:	uart_txd <= uart_data_reg[4];
			4'd6:	uart_txd <= uart_data_reg[5];
			4'd7:	uart_txd <= uart_data_reg[6];
			4'd8:	uart_txd <= uart_data_reg[7];
			4'd9:	uart_txd <= 1'b1;
			default:uart_txd <= 1'b1;
		endcase
	else 	
		uart_txd <= 1'b1;
end

// 发送完成标志
always @(posedge sys_clk or negedge sys_rst_n) begin
	if (!sys_rst_n)
		tx_done <= 1'b0;
	else if ((tx_cnt == 4'd9) && (clk_cnt == BPS_CNT/2))
		tx_done <= 1'b1;
	else
		tx_done <= 1'b0;
end

endmodule

module uart_top(
	input 	sys_clk,	//系统时钟
	input 	sys_rst_n,	//系统复位
 
	input 	uart_rxd,	//接收端口
	output 	uart_txd	//发送端口
);
parameter	UART_BPS=9600;			//波特率
parameter	CLK_FREQ=50_000_000;	//系统频率50M	
wire uart_en_w;
wire [7:0] uart_data_w; 
 
//例化发送模块
uart_tx#(
	.BPS		    (UART_BPS),
	.SYS_CLK_FRE	(CLK_FREQ))
u_uart_tx(
	.sys_clk		(sys_clk),
	.sys_rst_n	    (sys_rst_n),
	.uart_tx_en		(uart_en_w),
	.uart_data	    (uart_data_w),	
	.uart_txd	    (uart_txd)
);
uart_rx #(
	.BPS				(UART_BPS),
	.SYS_CLK_FRE		(CLK_FREQ))
u_uart_rx(
	.sys_clk			(sys_clk),
	.sys_rst_n		    (sys_rst_n),
	.uart_rxd		    (uart_rxd),	
	.uart_rx_done	    (uart_en_w),
	.uart_rx_data	    (uart_data_w)
);
endmodule



module uart_rx(
	input 			sys_clk,			
	input 			sys_rst_n,			
	input 			uart_rxd,			
	output reg 		uart_rx_done,		
	output reg [7:0]uart_rx_data

);

     parameter	BPS=9600;					
     parameter	SYS_CLK_FRE=50_000_000;		
    // localparam	BPS_CNT=SYS_CLK_FRE/BPS;
	localparam	BPS_CNT=10;	
     
     reg 			uart_rx_d0;		
     reg 			uart_rx_d1;		
     reg [15:0]		clk_cnt;		
     reg [3:0]		rx_cnt;			
     reg 			rx_flag;		
     reg [7:0]		uart_rx_data_reg;
     wire 			neg_uart_rx_data;




assign	neg_uart_rx_data=uart_rx_d1 & (~uart_rx_d0); 

always@(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		uart_rx_d0<=1'b0;
		uart_rx_d1<=1'b0;
	end
	else begin
		uart_rx_d0<=uart_rxd;
		uart_rx_d1<=uart_rx_d0;
	end		
end

always@(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)
		rx_flag<=1'b0;
	else begin 
		if(neg_uart_rx_data)
			rx_flag<=1'b1;
		else if((rx_cnt==4'd9)&&(clk_cnt==BPS_CNT/2))
			rx_flag<=1'b0;
		else 
			rx_flag<=rx_flag;			
	end
end

always@(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		rx_cnt<=4'd0;
		clk_cnt<=16'd0;
	end
	else if(rx_flag)begin
		if(clk_cnt<BPS_CNT-1'b1)begin
			clk_cnt<=clk_cnt+1'b1;
			rx_cnt<=rx_cnt;
		end
		else begin
			clk_cnt<=16'd0;
			rx_cnt<=rx_cnt+1'b1;
		end
	end
	else begin
		rx_cnt<=4'd0;
		clk_cnt<=16'd0;
	end		
end

always@(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)
		uart_rx_data_reg<=8'd0;
	else if(rx_flag)
		if(clk_cnt==BPS_CNT/2) begin
			case(rx_cnt)			
				4'd1:uart_rx_data_reg[0]<=uart_rxd;
				4'd2:uart_rx_data_reg[1]<=uart_rxd;
				4'd3:uart_rx_data_reg[2]<=uart_rxd;
				4'd4:uart_rx_data_reg[3]<=uart_rxd;
				4'd5:uart_rx_data_reg[4]<=uart_rxd;
				4'd6:uart_rx_data_reg[5]<=uart_rxd;
				4'd7:uart_rx_data_reg[6]<=uart_rxd;
				4'd8:uart_rx_data_reg[7]<=uart_rxd;
				default:;
			endcase
		end
		else
			uart_rx_data_reg<=uart_rx_data_reg;
	else
		uart_rx_data_reg<=8'd0;
end	

always@(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		uart_rx_done<=1'b0;
		uart_rx_data<=8'd0;
	end	
	else if(rx_cnt==4'd9)begin
		uart_rx_done<=1'b1;
		uart_rx_data<=uart_rx_data_reg;
	end		
	else begin
		uart_rx_done<=1'b0;
		uart_rx_data<=8'd0;
	end
end



endmodule


module uart_tx(
	input 			sys_clk,	//50M系统时钟
	input 			sys_rst_n,	//系统复位
	input	[7:0] 	uart_data,	//发送的8位置数据
	input			uart_tx_en,	//发送使能信号
	output reg 		uart_txd	//串口发送数据线
 
);
 
parameter 	SYS_CLK_FRE=50_000_000;    //50M系统时钟 
parameter 	BPS=9_600;                 //波特率9600bps，可更改
localparam	BPS_CNT=SYS_CLK_FRE/BPS;   //传输一位数据所需要的时钟个数
 
reg	uart_tx_en_d0;			//寄存1拍
reg uart_tx_en_d1;			//寄存2拍
reg tx_flag;				//发送标志位
reg [7:0]  uart_data_reg;	//发送数据寄存器
reg [15:0] clk_cnt;			//时钟计数器
reg [3:0]  tx_cnt;			//发送个数计数器
 
wire pos_uart_en_txd;		//使能信号的上升沿
//捕捉使能端的上升沿信号，用来标志输出开始传输
assign pos_uart_en_txd= uart_tx_en_d0 && (~uart_tx_en_d1);
 
always @(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		uart_tx_en_d0<=1'b0;
		uart_tx_en_d1<=1'b0;		
	end
	else begin
		uart_tx_en_d0<=uart_tx_en;
		uart_tx_en_d1<=uart_tx_en_d0;
	end	
end
//捕获到使能端的上升沿信号，拉高传输开始标志位，并在第9个数据（终止位）的传输过程正中（数据比较稳定）再将传输开始标志位拉低，标志传输结束
always @(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		tx_flag<=1'b0;
		uart_data_reg<=8'd0;
	end
	else if(pos_uart_en_txd)begin
		uart_data_reg<=uart_data;
		tx_flag<=1'b1;
	end
	else if((tx_cnt==4'd9) && (clk_cnt==BPS_CNT/2))begin//在第9个数据（终止位）的传输过程正中（数据比较稳定）再将传输开始标志位拉低，标志传输结束
		tx_flag<=1'b0;
		uart_data_reg<=8'd0;
	end
	else begin
		uart_data_reg<=uart_data_reg;
		tx_flag<=tx_flag;	
	end
end
always @(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		clk_cnt<=16'd0;
		tx_cnt <=4'd0;
	end
	else if(tx_flag) begin
		if(clk_cnt<BPS_CNT-1)begin
			clk_cnt<=clk_cnt+1'b1;
			tx_cnt <=tx_cnt;
		end
		else begin
			clk_cnt<=16'd0;
			tx_cnt <=tx_cnt+1'b1;
		end
	end
	else begin
		clk_cnt<=16'd0;
		tx_cnt<=4'd0;
	end
end
always @(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)
		uart_txd<=1'b1;
	else if(tx_flag)
		case(tx_cnt)
			4'd0:	uart_txd<=1'b0;
			4'd1:	uart_txd<=uart_data_reg[0];
			4'd2:	uart_txd<=uart_data_reg[1];
			4'd3:	uart_txd<=uart_data_reg[2];
			4'd4:	uart_txd<=uart_data_reg[3];
			4'd5:	uart_txd<=uart_data_reg[4];
			4'd6:	uart_txd<=uart_data_reg[5];
			4'd7:	uart_txd<=uart_data_reg[6];
			4'd8:	uart_txd<=uart_data_reg[7];
			4'd9:	uart_txd<=1'b1;
			default:uart_txd<=1'b1;
		endcase
	else 	
		uart_txd<=1'b1;
end
endmodule


