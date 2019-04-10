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
	integer k;

	//First stage input extension
	wire signed [DECIMAL+15:0] s1_R_in_n, s1_I_in_n;
	reg signed [DECIMAL+15:0] s1_R_in, s1_I_in;
	assign s1_R_in_n = {{4{din_r[11]}},din_r,{DECIMAL{1'b0}}};
	assign s1_I_in_n = {{4{din_i[11]}},din_i,{DECIMAL{1'b0}}};

	//rearrangement shift register
	reg signed [DECIMAL+15:0] rearrange_R   [0:31];
	reg signed [DECIMAL+15:0] rearrange_R_n [0:31];
	reg signed [DECIMAL+15:0] rearrange_I   [0:31];
	reg signed [DECIMAL+15:0] rearrange_I_n [0:31];

	//Data transfer
	wire signed [DECIMAL+15:0] s1_R_out, s2_R_out, s3_R_out, s4_R_out, s5_R_out;
	wire signed [DECIMAL+15:0] s1_I_out, s2_I_out, s3_I_out, s4_I_out, s5_I_out;
	wire signed [DECIMAL+15:0] sL1_R_in, sL2_R_in, sL3_R_in, sL4_R_in, sL5_R_in;
	wire signed [DECIMAL+15:0] sL1_I_in, sL2_I_in, sL3_I_in, sL4_I_in, sL5_I_in;
	wire signed [DECIMAL+15:0] sL1_R_out, sL2_R_out, sL3_R_out, sL4_R_out, sL5_R_out;
	wire signed [DECIMAL+15:0] sL1_I_out, sL2_I_out, sL3_I_out, sL4_I_out, sL5_I_out;
	assign sL1_R_in = rearrange_R[16]; assign sL1_I_in = rearrange_I[16];
	assign sL2_R_in = rearrange_R[24]; assign sL2_I_in = rearrange_I[24];
	assign sL3_R_in = rearrange_R[28]; assign sL3_I_in = rearrange_I[28];
	assign sL4_R_in = rearrange_R[30]; assign sL4_I_in = rearrange_I[30];
	assign sL5_R_in = rearrange_R[31]; assign sL5_I_in = rearrange_I[31];
	
	//Run flag
	reg run, run_n;

	//Output valid signal
	reg valid_o, valid_o_n;
	assign out_valid = valid_o;

	//counter
	reg  [5:0] cnt, cnt_n;
	wire [5:0] cnt_s5;
	reg  [4:0] cnt_re;
	assign cnt_s5 = cnt + 6'd1;
	always@(*) begin
		for(k = 0; k < 5; k = k + 1) begin
			cnt_re[k] = cnt_s5[4-k];
		end
	end

	//hold flag
	reg hold [0:31];
	reg hold_n [0:31];
	reg push [1:31];
	reg push_n [1:31];

	//Output rounding
	//assign dout_r = rearrange_R[0][DECIMAL-1] ? rearrange_R[0][DECIMAL+15:DECIMAL] + 1 : rearrange_R[0][DECIMAL+15:DECIMAL];
	//assign dout_i = rearrange_I[0][DECIMAL-1] ? rearrange_I[0][DECIMAL+15:DECIMAL] + 1 : rearrange_I[0][DECIMAL+15:DECIMAL];
	assign dout_r = rearrange_R[cnt_re][DECIMAL+15:DECIMAL];
	assign dout_i = rearrange_I[cnt_re][DECIMAL+15:DECIMAL];

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
	butterfly #(.DECIMAL(DECIMAL)) s1(
		.upper_i(cnt[4]), .twfR_i(twf_R[cnt[3:0]]), .twfI_i(twf_I[cnt[3:0]]),
		.data_R_i(s1_R_in), .data_I_i(s1_I_in), .data_R_o(s1_R_out), .data_I_o(s1_I_out),
		.loop_R_i(sL1_R_in), .loop_I_i(sL1_I_in), .loop_R_o(sL1_R_out), .loop_I_o(sL1_I_out)
		);
	butterfly #(.DECIMAL(DECIMAL)) s2(
		.upper_i(cnt[3]), .twfR_i(twf_R[{cnt[2:0],1'd0}]), .twfI_i(twf_I[{cnt[2:0],1'd0}]),
		.data_R_i(s1_R_out), .data_I_i(s1_I_out), .data_R_o(s2_R_out), .data_I_o(s2_I_out),
		.loop_R_i(sL2_R_in), .loop_I_i(sL2_I_in), .loop_R_o(sL2_R_out), .loop_I_o(sL2_I_out)
		);
	butterfly #(.DECIMAL(DECIMAL)) s3(
		.upper_i(cnt[2]), .twfR_i(twf_R[{cnt[1:0],2'd0}]), .twfI_i(twf_I[{cnt[1:0],2'd0}]),
		.data_R_i(s2_R_out), .data_I_i(s2_I_out), .data_R_o(s3_R_out), .data_I_o(s3_I_out),
		.loop_R_i(sL3_R_in), .loop_I_i(sL3_I_in), .loop_R_o(sL3_R_out), .loop_I_o(sL3_I_out)
		);
	butterfly #(.DECIMAL(DECIMAL)) s4(
		.upper_i(cnt[1]), .twfR_i(twf_R[{cnt[0],3'd0}]), .twfI_i(twf_I[{cnt[0],3'd0}]),
		.data_R_i(s3_R_out), .data_I_i(s3_I_out), .data_R_o(s4_R_out), .data_I_o(s4_I_out),
		.loop_R_i(sL4_R_in), .loop_I_i(sL4_I_in), .loop_R_o(sL4_R_out), .loop_I_o(sL4_I_out)
		);
	butterfly #(.DECIMAL(DECIMAL)) s5(
		.upper_i(cnt[0]), .twfR_i(twf_R[4'd0]), .twfI_i(twf_I[4'd0]),
		.data_R_i(s4_R_out), .data_I_i(s4_I_out), .data_R_o(s5_R_out), .data_I_o(s5_I_out),
		.loop_R_i(sL5_R_in), .loop_I_i(sL5_I_in), .loop_R_o(sL5_R_out), .loop_I_o(sL5_I_out)
		);

	//Conbinational circuit for control signal
	always@(*) begin
		run_n = in_valid || run ? 1 : 0;
		cnt_n = run ? cnt + 1 : cnt;
		valid_o_n = &{cnt_s5,cnt[5]} ? 1 : valid_o;

		rearrange_R_n[0] = cnt_s5[5] && cnt_s5[4:0] == 5'd0 ? s5_R_out : rearrange_R[0];
		rearrange_I_n[0] = cnt_s5[5] && cnt_s5[4:0] == 5'd0 ? s5_I_out : rearrange_I[0];
		rearrange_R_n[1] = ~hold[1] & push[1] ? s5_R_out : hold[1] ? rearrange_R[1] : sL1_R_out;
		rearrange_I_n[1] = ~hold[1] & push[1] ? s5_I_out : hold[1] ? rearrange_I[1] : sL1_I_out;
		for(k = 2; k <= 16; k = k + 1) begin
			rearrange_R_n[k] = ~hold[k] & push[k] ? s5_R_out : hold[k] ? rearrange_R[k] : rearrange_R[k-1];
			rearrange_I_n[k] = ~hold[k] & push[k] ? s5_I_out : hold[k] ? rearrange_I[k] : rearrange_I[k-1];
		end
		rearrange_R_n[17] =  ~hold[17] & push[17] ? s5_R_out : hold[17] ? rearrange_R[17] : sL2_R_out;
		rearrange_I_n[17] =  ~hold[17] & push[17] ? s5_I_out : hold[17] ? rearrange_I[17] : sL2_I_out;
		for(k = 18; k <= 24; k = k + 1) begin
			rearrange_R_n[k] = ~hold[k] & push[k] ? s5_R_out : hold[k] ? rearrange_R[k] : rearrange_R[k-1];
			rearrange_I_n[k] = ~hold[k] & push[k] ? s5_I_out : hold[k] ? rearrange_I[k] : rearrange_I[k-1];
		end
		rearrange_R_n[25] =  ~hold[25] & push[25] ? s5_R_out : hold[25] ? rearrange_R[25] : sL3_R_out;
		rearrange_I_n[25] =  ~hold[25] & push[25] ? s5_I_out : hold[25] ? rearrange_I[25] : sL3_I_out;
		for(k = 26; k <= 28; k = k + 1) begin
			rearrange_R_n[k] = ~hold[k] & push[k] ? s5_R_out : hold[k] ? rearrange_R[k] : rearrange_R[k-1];
			rearrange_I_n[k] = ~hold[k] & push[k] ? s5_I_out : hold[k] ? rearrange_I[k] : rearrange_I[k-1];
		end
		rearrange_R_n[29] =  ~hold[29] & push[29] ? s5_R_out : hold[29] ? rearrange_R[29] : sL4_R_out;
		rearrange_I_n[29] =  ~hold[29] & push[29] ? s5_I_out : hold[29] ? rearrange_I[29] : sL4_I_out;
		rearrange_R_n[30] =  ~hold[30] & push[30] ? s5_R_out : hold[30] ? rearrange_R[30] : rearrange_R[29];
		rearrange_I_n[30] =  ~hold[30] & push[30] ? s5_I_out : hold[30] ? rearrange_I[30] : rearrange_I[29];
		rearrange_R_n[31] =  ~hold[31] & push[31] ? s5_R_out : hold[31] ? rearrange_R[31] : sL5_R_out;
		rearrange_I_n[31] =  ~hold[31] & push[31] ? s5_I_out : hold[31] ? rearrange_I[31] : sL5_I_out;

		hold_n[0] = cnt_s5[5] && ~|cnt_s5[4:0] || hold[0] ? 1 : 0;
		for(k = 1; k < 32; k = k + 1) begin
			hold_n[k] = hold[k-1];
		end

		push_n[1] = cnt_s5[5] && ~|cnt_s5[4:0] ? 1 : 0;
		for(k = 2; k < 32; k = k + 1) begin
			push_n[k] = push[k-1];
		end

	end

	//sequential circuit
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n) begin
			run <= 0;
			cnt <= 0;
			valid_o <= 0;
			s1_R_in <= 0;
			s1_I_in <= 0;
			for(k = 0; k < 32; k = k + 1) begin
				rearrange_R[k] <= 0;
				rearrange_I[k] <= 0;
				hold[k] <= 0;
				push[k] <= 0;
			end
		end
		else begin
			run <= run_n;
			cnt <= cnt_n;
			valid_o <= valid_o_n;
			s1_R_in <= s1_R_in_n;
			s1_I_in <= s1_I_in_n;
			for(k = 0; k < 32; k = k + 1) begin
				rearrange_R[k] <= rearrange_R_n[k];
				rearrange_I[k] <= rearrange_I_n[k];
				hold[k] <= hold_n[k];
				push[k] <= push_n[k];
			end
		end
	end

endmodule

module butterfly(
	upper_i,
	twfR_i,
	twfI_i,
	data_R_i,
	data_I_i,
	data_R_o,
	data_I_o,
	loop_R_i,
	loop_I_i,
	loop_R_o,
	loop_I_o
	);
	
	//parameter declaration
	parameter DECIMAL = 7;
	integer d;

	//port definition
	input upper_i;
	input signed [DECIMAL+1:0] twfR_i;
	input signed [DECIMAL+1:0] twfI_i;
	input signed [DECIMAL+15:0] data_R_i;
	input signed [DECIMAL+15:0] data_I_i;
	output signed [DECIMAL+15:0] data_R_o;
	output signed [DECIMAL+15:0] data_I_o;
	input signed [DECIMAL+15:0] loop_R_i;
	input signed [DECIMAL+15:0] loop_I_i;
	output signed [DECIMAL+15:0] loop_R_o;
	output signed [DECIMAL+15:0] loop_I_o;

	//complex multiplication
	wire signed [DECIMAL+15:0] sub_R, sub_I;
	wire signed [DECIMAL*2+15:0] mult_R, mult_I;
	wire signed [DECIMAL*2+15:0] RR, II, RI, IR;
	assign sub_R = loop_R_i - data_R_i;
	assign sub_I = loop_I_i - data_I_i;
	assign RR = sub_R * twfR_i; assign II = sub_I * twfI_i; assign RI = sub_R * twfI_i; assign IR = sub_I * twfR_i;
	assign mult_R = RR - II;
	assign mult_I = RI + IR;

	//Radix-2 butterfly circuit 
	wire signed [DECIMAL+15:0] loop_R, loop_I;
	wire signed [DECIMAL+15:0] prog_R, prog_I;
	assign loop_R = ~upper_i ? data_R_i : mult_R[DECIMAL*2+15:DECIMAL];
	assign loop_I = ~upper_i ? data_I_i : mult_I[DECIMAL*2+15:DECIMAL];
	assign prog_R = upper_i ? loop_R_i + data_R_i : loop_R_i;
	assign prog_I = upper_i ? loop_I_i + data_I_i : loop_I_i;

	assign data_R_o = prog_R;
	assign data_I_o = prog_I;
	assign loop_R_o = loop_R;
	assign loop_I_o = loop_I;
	
endmodule
