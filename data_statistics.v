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
--Data created: 2015/7/1 15:42:50
________________________________________________________
********************************************************/
`timescale 1ns/1ps
module data_statistics #(
	parameter	DSIZE	= 8
)(
	input					clock			,
	input					rst_n           ,
	input					start           ,
	input					finish          ,
	input [DSIZE-1:0]		data  			,
	input					vld				,

	input [DSIZE-1:0]		index			,
	output[31:0]			summary			,
	input					get_summary		

);

localparam		WR_LAT	= 2,
				RD_LAT	= 2;

reg [DSIZE-1:0]		pre_data [WR_LAT-1:0];
reg [31:0]			pre_dcnt [WR_LAT-1:0];

reg [DSIZE-1:0]		post_data[RD_LAT-1:0];
reg [31:0]			post_dcnt[RD_LAT-1:0];

wire[WR_LAT-1:0]	pre_dont_exist; 
wire[RD_LAT-1:0]	post_dont_exist;
wire				dont_exist;
genvar II;
generate
for(II=0;II<WR_LAT;II=II+1)
	assign	pre_dont_exist	= pre_data != data;
endgenerate

generate
for(II=0;II<RD_LAT;II=II+1)
	assign	post_dont_exist	= post_data != data;
endgenerate

assign	dont_exist = (&{pre_dont_exist,post_dont_exist}) && vld;


reg		pro_post;

always@(posedge clock,negedge rst_n)begin:POST_TAIL
reg [WR_LAT-1:0]		post_tail;
	if(~rst_n)begin
		post_tail	<= {WR_LAT{1'b0}};
		pro_post	<= 1'b0;
	end else if(finish)begin
		post_tail	<= {WR_LAT{1'b1}};
		pro_post	<= 1'b1;
	end else begin
		post_tail	<= post_tail >> 1;
		pro_post	<= |post_tail;
end end

always@(posedge clock,negedge rst_n)begin:PRE_SHIFT
integer JJ;
reg [WR_LAT-1:0]	protect;
	if(~rst_n || start)begin
		for(JJ=0;JJ<WR_LAT;JJ=JJ+1)begin
			pre_data[JJ]	<= {DSIZE{1'b0}};
			pre_dcnt[JJ]	<= 32'd0;
			protect			<= ~({WR_LAT{1'b0}} + 1'b1);
		end
	else if (pro_post) begin
		for(JJ=1;JJ<WR_LAT;JJ=JJ+1)begin
			pre_data[JJ]	<= pre_data[JJ-1];
			pre_dcnt[JJ]	<= pre_dcnt[JJ-1];
		end
		pre_data[0]	<= pre_data[0];
		pre_dcnt[0]	<= 32'd0;
		protect		<= {WR_LAT{1'b1}};
	end else if(dont_exist)begin
		for(JJ=1;JJ<WR_LAT;JJ=JJ+1)begin
			pre_data[JJ]	<= pre_data[JJ-1];
			pre_dcnt[JJ]	<= pre_dcnt[JJ-1];
		end
		pre_data[0]	<= data;
		pre_dcnt[0]	<= 32'd1;
		protect		<= protect >> 1;
	end else begin
		for(JJ=0;JJ<WR_LAT;JJ=JJ+1)begin
			pre_dcnt[JJ]	<= pre_dcnt[JJ] + (pre_dont_exist[JJ] && !protect[JJ]);
		end
end end

always@(posedge clock)begin:POST_SHIFT
integer JJ;
	for(JJ=1;JJ<WR_LAT;JJ=JJ+1)begin
		post_data[JJ]	<= post_data[JJ-1];
		post_dcnt[JJ]	<= post_dcnt[JJ-1];
	end
	post_data[0]	<= pre_data[WR_LAT];
	post_dcnt[0]	<= pre_dcnt[WR_LAT];
end end

wire [31:0]			ram_data;
reg  [31:0]			sum_data;
reg  [9:0]			wr_addr;

reg	 [9:0]			rd_addr;

p2_ram p2_ram_inst(
	.aclr			(!rst_n || start	),
	.clock          (clock              ),
	.data           (sum_data           ),
	.rdaddress      (rd_addr	        ),
	.wraddress      (wr_addr            ),
	.wren           (1'b1               ),
	.q              (ram_data           )
);

always@(post_data[0],index)
	rd_addr	= get_summary? index : post_data[0])

wire[32:0]			sum_cnt;
assign	sum_cnt = ram_data + post_dcnt[RA_LAT];

always@(posedge clock,negedge rst_n)
	if(~rst_n)	sum_data	<= 32'd0;
	else		sum_data	<= sum_cnt[32]? {32{1'b1}} : sum_cnt[31:0];	

always@(posedge clock,negedge rst_n)
	if(~rst_n)	wr_addr		<= 10'd0;
	else		wr_addr		<= post_data[RD_LAT];

assign	summary	= ram_data;

endmodule



