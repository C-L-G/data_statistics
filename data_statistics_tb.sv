/*******************************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________

--Module Name:
--Project Name:
--Chinese Description:
	
--English Description:
	
--Version:VERA.1.0.0
--Data modified:
--author:Young-ÎâÃ÷
--E-mail: wmy367@Gmail.com
--Data created:2015/7/1 17:42:44
________________________________________________________
********************************************************/
`timescale 1ns/1ps
module data_statistics_tb;

bit		clock;

clock_rst clk_c0(
	.clock		(clock),
	.rst		(rst_n)
);

defparam clk_c0.ACTIVE = 0;
initial begin:INITIAL_CLOCK
	clk_c0.run(1 , 1000/100 ,0);		//100	
end

bit			start	= 0;
bit			finish	= 0;
bit			valid	= 0;
logic[9:0]	data;

initial begin
	start	= 1;
	valid	= 0;
	repeat(3)	@(posedge clock);
	start	= 0;
	repeat(100)begin
		data = $urandom_range(0,10);
		valid	= 1;
		@(posedge clock);
	end
	valid	= 0;
	repeat(10) @(posedge clock);
	finish	= 1;
	repeat(3) @(posedge clock);
	finish	= 0;
end

data_statistics #(
	.DSIZE		(10)
)data_statistics_inst(
	.clock			(clock			),		
	.rst_n          (rst_n          ),
	.start          (start          ),
	.finish         (finish         ),
	.data  			(data           ),
	.vld			(valid	        ),
    
	.index			(				),
	.summary		(	            ),
	.get_summary	(1'b0	        )
);


endmodule


