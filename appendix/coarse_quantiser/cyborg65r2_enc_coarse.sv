module cyborg65r2_enc_coarse(clk, clk_del, cco_pulse, resetb, grey_out, grey_out_del);
input clk, clk_del, cco_pulse, resetb;
output [5:0] grey_out, grey_out_del;

reg resetb_presync_clk;
reg resetb_sync_clk;

reg resetb_presync_clk_del;
reg resetb_sync_clk_del;

reg resetb_presync_cco_pulse;
reg resetb_sync_cco_pulse;

reg d_del_flag;
reg q_del_flag;

reg [5:0] d_out;
reg [5:0] q_out;

reg [5:0] q_out_ccosamp;

reg [5:0] d_out_del;
reg [5:0] q_out_del;

wire [5:0] grey_out;
wire [5:0] grey_out_del;

assign grey_out = q_out_ccosamp;
assign grey_out_del = q_out_del;


always @(posedge cco_pulse or negedge resetb)
begin
	if(!resetb)
	begin
		resetb_presync_cco_pulse	<= 1'b0;
		resetb_sync_cco_pulse		<= 1'b0;
	end
	else
	begin
		resetb_presync_cco_pulse	<= 1'b1;
		resetb_sync_cco_pulse		<= resetb_presync_cco_pulse;
	end
end

always @(posedge clk or negedge resetb_sync_cco_pulse)
begin
	if(!resetb_sync_cco_pulse)
	begin
		resetb_presync_clk	<= 1'b0;
		resetb_sync_clk		<= 1'b0;
	end
	else
	begin
		resetb_presync_clk	<= 1'b1;
		resetb_sync_clk		<= resetb_presync_clk;
	end
end

always @(posedge clk_del or negedge resetb_sync_cco_pulse)
begin
	if(!resetb_sync_cco_pulse)
	begin
		resetb_presync_clk_del	<= 1'b0;
		resetb_sync_clk_del	<= 1'b0;
	end
	else
	begin
		resetb_presync_clk_del	<= 1'b1;
		resetb_sync_clk_del	<= resetb_presync_clk_del;
	end
end


always @(posedge clk or negedge resetb_sync_clk)
begin
	if(!resetb_sync_clk)
	begin
		q_out	<= 6'b0;
	end
	else
	begin
		q_out	<= d_out;
	end
end

always @(posedge clk_del or negedge resetb_sync_clk_del)
begin
	if(!resetb_sync_clk_del)
	begin
		q_out_del	<= 6'b0;
		q_del_flag	<= 1'b0;
	end
	else
	begin
		q_out_del	<= d_out_del;
		q_del_flag	<= d_del_flag;
	end
end

always @(posedge cco_pulse or negedge resetb_sync_cco_pulse)
begin
	if(!resetb_sync_cco_pulse)
	begin
		q_out_ccosamp	<= 6'b0;
		d_del_flag	<= 1'b0;		
	end
	else
	begin
		d_del_flag	<= ~q_del_flag;
		q_out_ccosamp	<= q_out;
	end
end


always @(*)
begin
	d_out_del = (d_del_flag != q_del_flag)? q_out : q_out_del;
end

always @(*)
begin
	case(q_out)
		6'b000000:	d_out = 6'b000001; // 0 --> 1 
     		6'b000001:	d_out = 6'b000011; // 1 --> 2 
     		6'b000011:	d_out = 6'b000010; // 2 --> 3 
     		6'b000010:	d_out = 6'b000110; // 3 --> 4 
     		6'b000110:	d_out = 6'b000111; // 4 --> 5 
     		6'b000111:	d_out = 6'b000101; // 5 --> 6 
     		6'b000101:	d_out = 6'b000100; // 6 --> 7 
     		6'b000100:	d_out = 6'b001100; // 7 --> 8 
     		6'b001100:	d_out = 6'b001101; // 8 --> 9 
     		6'b001101:	d_out = 6'b001111; // 9 --> 10 
     		6'b001111:	d_out = 6'b001110; // 10 --> 11 
     		6'b001110:	d_out = 6'b001010; // 11 --> 12 
     		6'b001010:	d_out = 6'b001011; // 12 --> 13 
     		6'b001011:	d_out = 6'b001001; // 13 --> 14 
     		6'b001001:	d_out = 6'b001000; // 14 --> 15 
     		6'b001000:	d_out = 6'b011000; // 15 --> 16 
     		6'b011000:	d_out = 6'b011001; // 16 --> 17 
     		6'b011001:	d_out = 6'b011011; // 17 --> 18 
     		6'b011011:	d_out = 6'b011010; // 18 --> 19 
     		6'b011010:	d_out = 6'b011110; // 19 --> 20 
     		6'b011110:	d_out = 6'b011111; // 20 --> 21 
     		6'b011111:	d_out = 6'b011101; // 21 --> 22 
     		6'b011101:	d_out = 6'b011100; // 22 --> 23 
     		6'b011100:	d_out = 6'b010100; // 23 --> 24 
     		6'b010100:	d_out = 6'b010101; // 24 --> 25 
     		6'b010101:	d_out = 6'b010111; // 25 --> 26 
     		6'b010111:	d_out = 6'b010110; // 26 --> 27 
     		6'b010110:	d_out = 6'b010010; // 27 --> 28 
     		6'b010010:	d_out = 6'b010011; // 28 --> 29 
     		6'b010011:	d_out = 6'b010001; // 29 --> 30 
     		6'b010001:	d_out = 6'b010000; // 30 --> 31 
     		6'b010000:	d_out = 6'b110000; // 31 --> 32 
     		6'b110000:	d_out = 6'b110001; // 32 --> 33 
     		6'b110001:	d_out = 6'b110011; // 33 --> 34 
     		6'b110011:	d_out = 6'b110010; // 34 --> 35 
     		6'b110010:	d_out = 6'b110110; // 35 --> 36 
     		6'b110110:	d_out = 6'b110111; // 36 --> 37 
     		6'b110111:	d_out = 6'b110101; // 37 --> 38 
     		6'b110101:	d_out = 6'b110100; // 38 --> 39 
     		6'b110100:	d_out = 6'b111100; // 39 --> 40 
     		6'b111100:	d_out = 6'b111101; // 40 --> 41 
     		6'b111101:	d_out = 6'b111111; // 41 --> 42 
     		6'b111111:	d_out = 6'b111110; // 42 --> 43 
     		6'b111110:	d_out = 6'b111010; // 43 --> 44 
     		6'b111010:	d_out = 6'b111011; // 44 --> 45 
     		6'b111011:	d_out = 6'b111001; // 45 --> 46 
     		6'b111001:	d_out = 6'b111000; // 46 --> 47 
     		6'b111000:	d_out = 6'b101000; // 47 --> 48 
     		6'b101000:	d_out = 6'b101001; // 48 --> 49 
     		6'b101001:	d_out = 6'b101011; // 49 --> 50 
     		6'b101011:	d_out = 6'b101010; // 50 --> 51 
     		6'b101010:	d_out = 6'b101110; // 51 --> 52 
     		6'b101110:	d_out = 6'b101111; // 52 --> 53 
     		6'b101111:	d_out = 6'b101101; // 53 --> 54 
     		6'b101101:	d_out = 6'b101100; // 54 --> 55 
     		6'b101100:	d_out = 6'b100100; // 55 --> 56 
     		6'b100100:	d_out = 6'b100101; // 56 --> 57 
     		6'b100101:	d_out = 6'b100111; // 57 --> 58 
     		6'b100111:	d_out = 6'b100110; // 58 --> 59 
     		6'b100110:	d_out = 6'b100010; // 59 --> 60 
     		6'b100010:	d_out = 6'b100011; // 60 --> 61 
     		6'b100011:	d_out = 6'b100001; // 61 --> 62 
     		6'b100001:	d_out = 6'b100000; // 62 --> 63 
     		6'b100000: 	d_out = 6'b000000; // 63 --> 0 
	endcase
end

endmodule
