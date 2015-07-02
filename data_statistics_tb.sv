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
int			orgin_summary [];
int			rep_summary [];
bit			get_summary;
logic[9:0]	index;
logic[31:0]	osum;

localparam	RANGE			= 20,
			TATLE_NUM		= 1000;


task count_task;
	start	= 1;
	valid	= 0;
	orgin_summary	= new[RANGE];
	orgin_summary	= {RANGE{0}};
	repeat(3)	@(posedge clock);
	start	= 0;
	repeat(TATLE_NUM)begin
		data = $urandom_range(0,RANGE-1);
		//data	= 1;
		valid	= 1;
		@(posedge clock);
	end
	valid	= 0;
	repeat(10) @(posedge clock);
	finish	= 1;
	repeat(30) @(posedge clock);
	finish	= 0;
endtask: count_task

task report_task;
	get_summary	= 0;
	index		= 0;
	rep_summary	= new[RANGE];
	rep_summary = {RANGE{0}};
	repeat(3)	@(posedge clock);
	get_summary	= 1;
	repeat(RANGE)begin
		@(posedge clock);
		index	+= 1;
	end
	repeat(10) @(posedge clock);
	get_summary	= 0;
endtask: report_task
	
initial begin
	count_task;
	report_task;
end

logic[9:0]	index_lat;

cross_clk_sync #(       
	.DSIZE    	(10),    
	.LAT		(2)     
)latency_inst0(    
	clock,              
	get_summary,               
	index,       
	index_lat        
);          

always@(posedge clock) 
	if(valid)	orgin_summary[data] += 1;
always_comb if(get_summary) rep_summary[index_lat] = osum; 


data_statistics #(
	.DSIZE		(10)
)data_statistics_inst(
	.clock			(clock			),		
	.rst_n          (rst_n          ),
	.start          (start          ),
	.finish         (finish         ),
	.data  			(data           ),
	.vld			(valid	        ),
    
	.index			(index			),
	.summary		(osum           ),
	.get_summary	(get_summary    )
);


endmodule


