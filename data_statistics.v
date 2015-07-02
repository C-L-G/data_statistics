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

localparam		WR_LAT	= 5,
				RD_LAT	= 2;

reg [DSIZE-1:0]		pre_data [WR_LAT-1:0];
reg [31:0]			pre_dcnt [WR_LAT-1:0];

reg [DSIZE-1:0]		post_data[RD_LAT-1:0];
reg [31:0]			post_dcnt[RD_LAT-1:0];

reg[WR_LAT-1:0]		pre_dont_exist; 
reg[WR_LAT-1:0]		pre_add_en;
wire				dont_exist;
reg [WR_LAT-1:0]	protect;

integer 			II;
integer 			JJ;

always@(*)begin:GEN_PRE_DONT_EXIST
	if(vld)
		for(II=0;II<WR_LAT;II=II+1)
			pre_dont_exist[II]	= ((pre_data[II] != data) && !protect[II]) || &protect;
	else
			pre_dont_exist	= {WR_LAT{1'b0}};
end

always@(*)begin:GEN_PRE_ADD_EN
	if(vld)
		for(II=0;II<WR_LAT;II=II+1)
			pre_add_en[II]	= (pre_data[II] == data) && !protect[II];
	else
			pre_add_en	= {WR_LAT{1'b0}};
end


assign	dont_exist = &{pre_dont_exist | protect};


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

//---->>  <<-------
always@(posedge clock,negedge rst_n)begin
	if(~rst_n)	
		for(JJ=0;JJ<WR_LAT;JJ=JJ+1)
			pre_dcnt[JJ]	<= 32'd0;
	else if(start)	
		for(JJ=0;JJ<WR_LAT;JJ=JJ+1)
			pre_dcnt[JJ]	<= 32'd0; 
	else if(pro_post)begin
		for(JJ=1;JJ<WR_LAT;JJ=JJ+1)
			pre_dcnt[JJ]	<= pre_dcnt[JJ-1];
		pre_dcnt[0]	<= 32'd0;
	end else if(dont_exist)begin
		if(vld)begin
			for(JJ=1;JJ<WR_LAT;JJ=JJ+1)
				pre_dcnt[JJ]	<= pre_dcnt[JJ-1];
			pre_dcnt[0]	<= 32'd1;
		end else begin
			for(JJ=0;JJ<WR_LAT;JJ=JJ+1)
				pre_dcnt[JJ]	<= pre_dcnt[JJ];
		end
	end else begin
		for(JJ=0;JJ<WR_LAT;JJ=JJ+1)
			pre_dcnt[JJ]	<= pre_dcnt[JJ] + (pre_add_en[JJ] );
end end

always@(posedge clock,negedge rst_n)begin
	if(~rst_n)	
		for(JJ=0;JJ<WR_LAT;JJ=JJ+1)
			pre_data[JJ]	<= {DSIZE{1'b0}};
	else if(start)		
		for(JJ=0;JJ<WR_LAT;JJ=JJ+1)
			pre_data[JJ]	<= {DSIZE{1'b0}}; 
	else if(pro_post)begin
		for(JJ=1;JJ<WR_LAT;JJ=JJ+1)
			pre_data[JJ]	<= pre_data[JJ-1];
		pre_data[0]	<= pre_data[0];
	end else if(dont_exist)begin
		if(vld)begin
			for(JJ=1;JJ<WR_LAT;JJ=JJ+1)
				pre_data[JJ]	<= pre_data[JJ-1];
			pre_data[0]	<= data;
		end else begin
			for(JJ=0;JJ<WR_LAT;JJ=JJ+1)
				pre_data[JJ]	<= pre_data[JJ];
		end
	end else begin
		for(JJ=0;JJ<WR_LAT;JJ=JJ+1)
			pre_data[JJ]	<= pre_data[JJ];
end end

always@(posedge clock,negedge rst_n)begin
	if(~rst_n)			protect			<= ~({WR_LAT{1'b0}} + 1'b0);
	else if(start)		protect			<= ~({WR_LAT{1'b0}} + 1'b0); 
	else if(pro_post)	protect			<= ~({WR_LAT{1'b0}} + 1'b0);
	else if(dont_exist)	protect			<= vld? (protect<<1) : protect;
	else 				protect			<= protect;
end
							
//---<<  >>-----------
//--->>  <<-----------
reg [WR_LAT-1:0]	pre_data_vld;
always@(posedge clock,negedge rst_n)begin
	if(~rst_n)		pre_data_vld	<= {WR_LAT{1'b0}};
	else begin
		if(start)
				pre_data_vld	<= {WR_LAT{1'b0}};
		else if(pro_post)
				pre_data_vld	<= pre_data_vld << 1;
		else if(dont_exist)
				pre_data_vld	<= vld? {pre_data_vld[WR_LAT-2:0],1'b1} : pre_data_vld;
		else	pre_data_vld	<= {pre_data_vld[WR_LAT-1:1],vld};
end end

always@(posedge clock)begin:POST_SHIFT
	for(JJ=1;JJ<WR_LAT;JJ=JJ+1)begin
		post_data[JJ]	<= post_data[JJ-1];
		post_dcnt[JJ]	<= post_dcnt[JJ-1];
	end
	post_data[0]	<= pre_data[WR_LAT-1];
	post_dcnt[0]	<= pre_dcnt[WR_LAT-1];
end

reg[RD_LAT-1:0]			post_data_vld;
always@(posedge clock)begin:POST_VLD_SHIFT
	for(JJ=1;JJ<WR_LAT;JJ=JJ+1)begin
		post_data_vld[JJ]	<= post_data_vld[JJ-1];
	end
	post_data_vld[0]	<= (pre_data_vld[WR_LAT-1] && vld && dont_exist) || (|pre_dcnt[WR_LAT-1] && pro_post);
end

reg [DSIZE-1:0]		mix_data;
reg [31:0]			mix_dcnt;
reg					mix_data_vld;
always@(posedge clock,negedge rst_n)begin
	if(~rst_n)begin
		mix_data	<= {DSIZE{1'b0}};
		mix_dcnt	<= 32'd0; 
		mix_data_vld<= 1'b0;
	end else begin
		mix_data	<= post_data[RD_LAT-1];
		mix_dcnt	<= post_dcnt[RD_LAT-1];
		mix_data_vld<= post_data_vld[RD_LAT-1];
end end

reg					wr_en;

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
	.wren           (wr_en              ),
	.q              (ram_data           )
);

always@(post_data[0],index)
	rd_addr	= get_summary? index : post_data[0];

wire[32:0]			sum_cnt;
assign	sum_cnt = ram_data + mix_dcnt;

always@(posedge clock,negedge rst_n)
	if(~rst_n)	sum_data	<= 32'd0;
	else		sum_data	<= sum_cnt[32]? {32{1'b1}} : sum_cnt[31:0];	

always@(posedge clock,negedge rst_n)
	if(~rst_n)	wr_addr		<= 10'd0;
	else		wr_addr		<= mix_data;

always@(posedge clock,negedge rst_n)
	if(~rst_n)	wr_en		<= 1'b0;
	else		wr_en		<= mix_data_vld;

assign	summary	= ram_data;

endmodule



