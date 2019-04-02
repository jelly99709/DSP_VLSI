module FFT(
	input clk,
	input rst_n,
	input in_valid,
	input signed [11:0] din_r,
	input signed [11:0] din_i,
	output out_valid,
	output signed [15:0] dout_r,
	output signed [15:0] dout_i
	);
	
	//parameter declaration
	parameter DECIMAL = 6;
	localparam LENGTH = DECIMAL + 2;
	integer k;

	//First stage input extension
	wire signed [LENGTH+15:0] s1_R_in, s1_I_in;
	assign s1_R_in = {{6{din_r[11]}},din_r,{DECIMAL{1'b0}}};
	assign s1_I_in = {{6{din_i[11]}},din_i,{DECIMAL{1'b0}}};

	//Data transfer
	wire signed [LENGTH+15:0] s1_R_out, s2_R_out, s3_R_out, s4_R_out, s5_R_out;
	wire signed [LENGTH+15:0] s1_I_out, s2_I_out, s3_I_out, s4_I_out, s5_I_out;
	
	//Rearangement shift register
	reg signed [LENGTH+15:0] rearange_R   [0:31];
	reg signed [LENGTH+15:0] rearange_R_n [0:31];
	reg signed [LENGTH+15:0] rearange_I   [0:31];
	reg signed [LENGTH+15:0] rearange_I_n [0:31];
	
	//Run flag
	reg run, run_n;

	//Output valid signal
	reg valid_o, valid_o_n;
	assign out_valid = valid_o;

	//Output rounding
	assign dout_r = s5_R_out[DECIMAL-1] ? s5_R_out[DECIMAL+15:DECIMAL] + 1 : s5_R_out[DECIMAL+15:DECIMAL];
	assign dout_i = s5_I_out[DECIMAL-1] ? s5_I_out[DECIMAL+15:DECIMAL] + 1 : s5_I_out[DECIMAL+15:DECIMAL];

	//counter
	reg  [5:0] cnt, cnt_n;
	wire [4:0] cnt_s1, cnt_s2, cnt_s3, cnt_s4, cnt_s5;
	reg  [4:0] cnt_re;
	assign cnt_s1 = cnt[4:0] + 5'd16; //-16
	assign cnt_s2 = cnt[4:0] + 5'd8;  //-24
	assign cnt_s3 = cnt[4:0] + 5'd4;  //-28
	assign cnt_s4 = cnt[4:0] + 5'd2;  //-30
	assign cnt_s5 = cnt[4:0] + 5'd1;  //-31
	always@(*) begin
		for(k = 0; k < 5; k = k + 1) begin
			cnt_re[k] = cnt_s5[4-k];
		end
	end

	//twiddle factor
	wire signed [7:0] twf_R [0:15];
	wire signed [7:0] twf_I [0:15];
	assign twf_R[0] = 8'sb01000000;   assign twf_I[0] = 8'sb00000000;
	assign twf_R[1] = 8'sb00111111;   assign twf_I[1] = 8'sb11110100;
	assign twf_R[2] = 8'sb00111011;   assign twf_I[2] = 8'sb11101000;
	assign twf_R[3] = 8'sb00110101;   assign twf_I[3] = 8'sb11011100;
	assign twf_R[4] = 8'sb00101101;   assign twf_I[4] = 8'sb11010011;
	assign twf_R[5] = 8'sb00100100;   assign twf_I[5] = 8'sb11001011;
	assign twf_R[6] = 8'sb00011000;   assign twf_I[6] = 8'sb11000101;
	assign twf_R[7] = 8'sb00001100;   assign twf_I[7] = 8'sb11000001;
	assign twf_R[8] = 8'sb00000000;   assign twf_I[8] = 8'sb11000000;
	assign twf_R[9] = 8'sb11110100;   assign twf_I[9] = 8'sb11000001;
	assign twf_R[10] = 8'sb11101000;   assign twf_I[10] = 8'sb11000101;
	assign twf_R[11] = 8'sb11011100;   assign twf_I[11] = 8'sb11001011;
	assign twf_R[12] = 8'sb11010011;   assign twf_I[12] = 8'sb11010011;
	assign twf_R[13] = 8'sb11001011;   assign twf_I[13] = 8'sb11011100;
	assign twf_R[14] = 8'sb11000101;   assign twf_I[14] = 8'sb11101000;
	assign twf_R[15] = 8'sb11000001;   assign twf_I[15] = 8'sb11110100;

	//Butterfly stages
	butterfly #(.DELAY(16), .DECIMAL(DECIMAL)) s1(
		.clk(clk), .rst_n(rst_n), .cnt_i(cnt_s1), .twfR_i(twf_R[cnt_s1[3:0]]), .twfI_i(twf_I[cnt_s1[3:0]]),
		.data_R_i(s1_R_in), .data_I_i(s1_I_in), .data_R_o(s1_R_out), .data_I_o(s1_I_out)
		);
	butterfly #(.DELAY(8), .DECIMAL(DECIMAL)) s2(
		.clk(clk), .rst_n(rst_n), .cnt_i(cnt_s2), .twfR_i(twf_R[{1'd0,cnt_s2[3:0]}]), .twfI_i(twf_I[{1'd0,cnt_s2[3:0]}]),
		.data_R_i(s1_R_out), .data_I_i(s1_I_out), .data_R_o(s2_R_out), .data_I_o(s2_I_out)
		);
	butterfly #(.DELAY(4), .DECIMAL(DECIMAL)) s3(
		.clk(clk), .rst_n(rst_n), .cnt_i(cnt_s3), .twfR_i(twf_R[{2'd0,cnt_s3[2:0]}]), .twfI_i(twf_I[{2'd0,cnt_s3[2:0]}]),
		.data_R_i(s2_R_out), .data_I_i(s2_I_out), .data_R_o(s3_R_out), .data_I_o(s3_I_out)
		);
	butterfly #(.DELAY(2), .DECIMAL(DECIMAL)) s4(
		.clk(clk), .rst_n(rst_n), .cnt_i(cnt_s4), .twfR_i(twf_R[{3'd0,cnt_s4[1:0]}]), .twfI_i(twf_I[{3'd0,cnt_s4[1:0]}]),
		.data_R_i(s3_R_out), .data_I_i(s3_I_out), .data_R_o(s4_R_out), .data_I_o(s4_I_out)
		);
	butterfly #(.DELAY(1), .DECIMAL(DECIMAL)) s5(
		.clk(clk), .rst_n(rst_n), .cnt_i(cnt_s5), .twfR_i(twf_R[4'd0]), .twfI_i(twf_I[4'd0]),
		.data_R_i(s4_R_out), .data_I_i(s4_I_out), .data_R_o(s5_R_out), .data_I_o(s5_I_out)
		);

	//Conbinational circuit for control signal
	always@(*) begin
		run_n = in_valid || run ? 1 : 0;
		cnt_n = in_valid || run ? cnt + 1 : cnt;
		valid_o_n = &cnt ? 1 : valid_o;

		for(k = 0; k < 31; k = k + 1) begin
			if(valid_o) begin
				//Shift register
				rearange_R_n[k] = rearange_R[k+1];
				rearange_I_n[k] = rearange_I[k+1];
			end
			else begin
				if(k == cnt_re) begin
					rearange_R_n[k] = s5_R_out;
					rearange_I_n[k] = s5_I_out;
				end
				else begin
					rearange_R_n[k] = rearange_R[k];
					rearange_I_n[k] = rearange_I[k];
				end
			end
		end
		rearange_R_n[31] = &cnt_s5 ? s5_R_out : rearange_R[31];
		rearange_I_n[31] = &cnt_s5 ? s5_I_out : rearange_I[31];

	end

	//sequential circuit
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n) begin
			run <= 0;
			cnt <= 0;
			valid_o <= 0;
			for(k = 0; k < 32; k = k + 1) begin
				rearange_R[k] <= 0;
				rearange_I[k] <= 0;
			end
		end
		else begin
			run <= run_n;
			cnt <= cnt_n;
			valid_o <= valid_o_n;
			for(k = 0; k < 32; k = k + 1) begin
				rearange_R[k] <= rearange_R_n[k];
				rearange_I[k] <= rearange_I_n[k];
			end
		end
	end

endmodule

module butterfly(
	clk,
	rst_n,
	cnt_i,
	twfR_i,
	twfI_i,
	data_R_i,
	data_I_i,
	data_R_o,
	data_I_o
	);
	
	//parameter declaration
	parameter DELAY = 16;
	parameter DECIMAL = 6;
	localparam LENGTH = DECIMAL + 2;
	integer d;

	//port definition
	input clk, rst_n;
	input [4:0] cnt_i;
	input signed [LENGTH-1:0] twfR_i;
	input signed [LENGTH-1:0] twfI_i;
	input signed [LENGTH+15:0] data_R_i;
	input signed [LENGTH+15:0] data_I_i;
	output signed [LENGTH+15:0] data_R_o;
	output signed [LENGTH+15:0] data_I_o;	

	//Delay blocks
	reg signed [LENGTH+15:0] delay_R   [0:DELAY-1];
	reg signed [LENGTH+15:0] delay_I   [0:DELAY-1];

	//Flag to determine upper half and lower half
	wire upper;
	assign upper = ~cnt_i[$clog2(DELAY)];

	//Radix-2 butterfly circuit 
	wire signed [LENGTH-1:0] loop_R, loop_I;
	wire signed [LENGTH-1:0] prog_R, prog_I;
	assign loop_R = upper ? data_R_i : delay_R[DELAY-1] - data_R_i;
	assign loop_I = upper ? data_I_i : delay_I[DELAY-1] - data_I_i;
	assign prog_R = upper ? delay_R[DELAY-1] + data_R_i : delay_R[DELAY-1];
	assign prog_I = upper ? delay_I[DELAY-1] + data_I_i : delay_I[DELAY-1];

	//output complex multiplication
	wire signed [LENGTH*2+15:0] out_R;
	wire signed [LENGTH*2+15:0] out_I;
	assign out_R = (prog_R * twfR_i) - (prog_I * twfI_i);
	assign out_I = (prog_R * twfI_i) + (prog_I * twfR_i);

	//output rounding
	assign data_R_o = out_R[DECIMAL-1] ? out_R[LENGTH+DECIMAL+15:DECIMAL] + 1 : out_R[LENGTH+DECIMAL+15:DECIMAL];
	assign data_I_o = out_I[DECIMAL-1] ? out_I[LENGTH+DECIMAL+15:DECIMAL] + 1 : out_I[LENGTH+DECIMAL+15:DECIMAL];

	//Sequential circuit
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n) begin
			for(d = 0; d < DELAY; d = d + 1) begin
				delay_R[d] <= 0;
				delay_I[d] <= 0;
			end
		end
		else begin
			//Shift register for delay blocks
			delay_R[0] <= loop_R;
			delay_I[0] <= loop_I;
			for(d = 1; d < DELAY; d = d + 1) begin
				delay_R[d] <= delay_R[d-1];
				delay_I[d] <= delay_I[d-1];
			end
		end
	end

endmodule
