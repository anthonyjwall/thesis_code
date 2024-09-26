module cyborg65r2_encoder(
				clk,			// This is the clk from the cco	
				resetb,			// Asynch reset, active LOW	
				count_coarse,		// This is the output of the coarse counter, should have been sampled on last rising edge of clk
				count_coarse_del,	// Output of the coarse counter, but not sampled by clk but a 600ps delayed version, akin to fallingedge of ph27 reference oscillator. Allows for coarse counter delay correction
				count_fine,		// All the fine phases, should have been sampled by rising edge of clk 
				count_enc		// output encoded time value
			);

// ------------------
// Inputs and Outputs
// ------------------

input 		clk;			// Negative Edge triggered clk from the ping-pong oscillator
input 		resetb;			
input [5:0] 	count_coarse;		// Gray coded coarse counter output value
input [5:0] 	count_coarse_del;	// Gray coded coarse counter output value, sampled by phase 16 to ensure value has settled
input [32:0] 	count_fine;		// Pseudo-Thermometer coded fine phase outputs

output [11:0] count_enc;		// Binary encoded outputs, needs to be of length: Nbits = log2(2*Nphases*2**counterWidth)


// ------------------
// Parameters
// ------------------

parameter ENCODER_WRAP_CNT	= 12'd4224; // This is the natural overflow period of the fine + coarse phases: 66 * 2^6 = 4224 
// You'll get a warning about this overflowing. This is intentional, allows you to spec the acutal number of phases in a loop.

// ------------------
// Variable Declarations
// ------------------

integer index;	// Variable used in for loops, currently only used when summing up the fine phases

// ------------------
// Register Declarations
// ------------------

reg 		resetb_presync;		// Registers for resetb synching
reg 		resetb_sync;		

reg [32:0]	q_inp_fine;		// Defining the input regs, d is taken as the input
reg [5:0]	q_inp_coarse;	
reg [5:0]	q_inp_coarse_del;


reg [5:0]	reg_finehigh;		// Register with the sum of high fine bits sum of phases can be up to 32 - need 6 bit to hold it

reg [6:0]	d_finecount;		// Register with the fine output count. Can be up to (2*Nphases)-1 = (2*33)-1 = 65 - need 7 bit to hold it
reg [6:0]	q_finecount;


reg [5:0]	q_coarsebin;		// Register to store the output of the coarse code converted from gray code to binary	



reg [12:0]	d_enc;			// Register to store the encoded output: combined coarse and fine
reg [12:0]	q_enc;			// Needs to be width > log2((2*Nphases)*2**counterWidth) = log2((2*33)*2**6) = log2(8448) = 13 bit

reg [11:0]	d_wrapadd;		// Register to store n*max(q_enc) to help unwrap the output to 4096 instead of n*max(q_enc)
reg [11:0]	q_wrapadd;

reg [11:0]	d_out;			// Register to combine the raw encoded output and the wrap signal to get the full output word width
reg [11:0]	q_out;			

// ------------------
// Output Declarations
// ------------------
assign count_enc	=	q_out;	// Assigning the output as the encoded value

// ------------------
// Wire Assignments
// ------------------
wire [5:0] w_coarsebin;
wire [5:0] w_coarse_gray = (~q_inp_fine[0] & ~q_inp_fine[6] )? q_inp_coarse : q_inp_coarse_del;	// Coarse latency correction:
//	If the sampled fine phase [0] is gone low (second half of cycle), and [6] is also gone low, the coarse counter value is deemed settled settled by the time rising clk sampled coarse edge
//	Otherwise, take the delayed value of the coarse counter which was sampled by the falling edge of fine phase [27], ensuring the coarse counter has had enough time to settle.
//	Since 0.5* Tclk > (33+27)*T_Q, coarse_del will have occured before it is sampled on the falling edge of clk
//	This ensures that the correct value of the coarse counter is always sampled into the gray2bin stage of the conversion

// ------------------
// Module Instantiations 
// ------------------
gray2bin	#(.bus_width(6))	i_GRAY2BIN	(.in_gray(w_coarse_gray), .out_bin(w_coarsebin));	// Module which converts the coarse counts from gray code to binary

// ------------------
// Clocked Processes
// ------------------

// Process for creating a synchronous resetb for the other registers

always @(negedge clk or negedge resetb)		// At the falling edge of clk
begin
	if(!resetb)
	begin
		resetb_presync	<=	1'b0;
		resetb_sync	<=	1'b0;
	end
	else
	begin
		resetb_presync	<=	1'b1;
		resetb_sync	<=	resetb_presync;	// Synchronise the reset
	end
end

// Process for registers clocked from negative edge of clk

always @(negedge clk or negedge resetb_sync)	// Each falling edge of clk or synched reset
begin
	if(!resetb_sync)
	begin
		q_inp_fine		<=	33'b010101010101010101010101010101010;
		q_inp_coarse		<=	6'b0;
		q_inp_coarse_del	<=	6'b0;
		q_finecount		<=	7'b0;
		q_coarsebin		<=	6'b0;
		q_enc			<=	13'b0;
		q_wrapadd		<=	12'b0;
		q_out			<=	12'b0;
	end

	else
	begin
		q_inp_fine		<=	count_fine;		// Take the fine intput and sample it
		q_inp_coarse		<=	count_coarse;		// Take the coarse input and sample it
		q_inp_coarse_del	<=	count_coarse_del;	// Take the delayed coarse input and sample it
		q_finecount		<=	d_finecount;		// The fine count is sampled
		q_coarsebin		<=	w_coarsebin;		// The binary coarse output is sampled (output from gray2bin)
		q_enc			<=	d_enc;			// The combined coarse and fine values are sampled for the encoder output
		q_wrapadd		<=	d_wrapadd;		// If a wrap has occurred, the value of the wrap reg is updated
		q_out			<=	d_out;			// Pass the combined encoder and wrap signal to the output pin
	end
end

// ------------------
// Combinatorial Processes
// ------------------


// Summing up all the high fine phases

always @(*)
begin
	// The fine phases count up in thermometer codes, but with the odd phases inverted.
	// To find the fine position in the ring invert every second phase, and count the high phases in the ring.
	// The thermometer codes count up, then down. To figure out if they're counting up or down, look at if the first phase is high or low.
	reg_finehigh = 6'b0; // Zero out the count of high fine phases
	for(index=0; index<33; index=index+1) // Loop through the fine phase index
	begin
		if(index[0] ==1'b0) // If the first bit of the index is 0 then it's even, otherwise odd. 
		begin
			reg_finehigh = reg_finehigh + q_inp_fine[index];	// If it's even, phase isn't inverted, so simply add the count to the thermo code if high
		end
		else 
		begin
			reg_finehigh = reg_finehigh + !q_inp_fine[index];	// If it's odd, phase IS inverted, so un-invert the phase before adding its count to the thermo code if high.

		end
	end	
end

// Computing the fine output depending if first fine bit is high or not
// i.e. counting up or counting back down

always @(*)
begin

	if(q_inp_fine[0])
	begin
		d_finecount	=	{1'b0,reg_finehigh}; // If the first fine phase is high, the oscillator is counting up, so the output is the sum of phases
	end
	else
	begin
		d_finecount	=	(7'd65) - reg_finehigh; // If the first fine phase is low, the oscillator is counting back down, so the ouput is the 2* the total number of phases minus those still high
	end

end

// Combining the coarse and fine counts, preparing for output

always @(*)
begin
	d_enc		=	13'd66*{6'b0,q_coarsebin} + q_finecount;	//Sum up the coarse output and fine outputs, with coarse weighted by 2*Nphases
end

// Detecting if a wrap has occurred in the combined encoded signal and incrementing the wrap register if so
always @(*)
begin
	if(q_enc > d_enc)
	begin
		d_wrapadd	=	q_wrapadd + ENCODER_WRAP_CNT;
	end
	else
	begin
		d_wrapadd	=	q_wrapadd;	
	end
end

// Combining the wrapped and the unwrapping regs to make the output signal the full output bit width
always @(*)
begin
	d_out	=	q_enc[11:0] + q_wrapadd;	
end

endmodule
