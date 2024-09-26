module gray2bin	#(
		parameter bus_width = 6
		)(
		input		[bus_width-1:0]	in_gray,
		output reg	[bus_width-1:0]	out_bin	
		);

		integer bit_ind;
always @(*)
begin
	out_bin[bus_width-1]		=	in_gray[bus_width-1];

	for(bit_ind=bus_width-2; bit_ind>=0; bit_ind=bit_ind-1)
	begin
		out_bin[bit_ind] = out_bin[bit_ind+1] ^ in_gray[bit_ind];
	end

end

endmodule
