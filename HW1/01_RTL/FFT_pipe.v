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
	parameter DECIMAL = 8;
	localparam LENGTH = DECIMAL + 2;
	integer k;

	//First stage input extension
	wire signed [LENGTH+15:0] s1_R_in_n, s1_I_in_n;
	reg signed [LENGTH+15:0] s1_R_in, s1_I_in;
	assign s1_R_in_n = in_valid ? {{6{din_r[11]}},din_r,{DECIMAL{1'b0}}} : s1_R_in;
	assign s1_I_in_n = in_valid ? {{6{din_i[11]}},din_i,{DECIMAL{1'b0}}} : s1_I_in;

	//Data transfer
	reg signed [LENGTH+15:0] s1_R_out, s2_R_out, s3_R_out, s4_R_out;
	reg signed [LENGTH+15:0] s1_I_out, s2_I_out, s3_I_out, s4_I_out;
	wire signed [LENGTH+15:0] s1_R_out_n, s2_R_out_n, s3_R_out_n, s4_R_out_n, s5_R_out;
	wire signed [LENGTH+15:0] s1_I_out_n, s2_I_out_n, s3_I_out_n, s4_I_out_n, s5_I_out;

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
	assign dout_r = rearange_R[0][DECIMAL-1] ? rearange_R[0][DECIMAL+15:DECIMAL] + 1 : rearange_R[0][DECIMAL+15:DECIMAL];
	assign dout_i = rearange_I[0][DECIMAL-1] ? rearange_I[0][DECIMAL+15:DECIMAL] + 1 : rearange_I[0][DECIMAL+15:DECIMAL];

	//counter
	reg  [5:0] cnt, cnt_n;
	wire [4:0] cnt_s1, cnt_s2, cnt_s3, cnt_s4;
	wire [5:0] cnt_s5;
	reg  [4:0] cnt_re;
	assign cnt_s1 = cnt[4:0] + 5'd16; //-16
	assign cnt_s2 = cnt[4:0] + 5'd7;  //-24
	assign cnt_s3 = cnt[4:0] + 5'd2;  //-28
	assign cnt_s4 = cnt[4:0] - 5'd1;  //-30
	assign cnt_s5 = cnt      - 6'd3;  //-31
	always@(*) begin
		for(k = 0; k < 5; k = k + 1) begin
			cnt_re[k] = cnt_s5[4-k];
		end
	end

	//twiddle factor
	wire signed [9:0] twf_R [0:15];
	wire signed [9:0] twf_I [0:15];
	assign twf_R[0] = 10'sb0100000000;   assign twf_I[0] = 10'sb0000000000;
	assign twf_R[1] = 10'sb0011111011;   assign twf_I[1] = 10'sb1111001110;
	assign twf_R[2] = 10'sb0011101101;   assign twf_I[2] = 10'sb1110011110;
	assign twf_R[3] = 10'sb0011010101;   assign twf_I[3] = 10'sb1101110010;
	assign twf_R[4] = 10'sb0010110101;   assign twf_I[4] = 10'sb1101001011;
	assign twf_R[5] = 10'sb0010001110;   assign twf_I[5] = 10'sb1100101011;
	assign twf_R[6] = 10'sb0001100010;   assign twf_I[6] = 10'sb1100010011;
	assign twf_R[7] = 10'sb0000110010;   assign twf_I[7] = 10'sb1100000101;
	assign twf_R[8] = 10'sb0000000000;   assign twf_I[8] = 10'sb1100000000;
	assign twf_R[9] = 10'sb1111001110;   assign twf_I[9] = 10'sb1100000101;
	assign twf_R[10] = 10'sb1110011110;   assign twf_I[10] = 10'sb1100010011;
	assign twf_R[11] = 10'sb1101110010;   assign twf_I[11] = 10'sb1100101011;
	assign twf_R[12] = 10'sb1101001011;   assign twf_I[12] = 10'sb1101001011;
	assign twf_R[13] = 10'sb1100101011;   assign twf_I[13] = 10'sb1101110010;
	assign twf_R[14] = 10'sb1100010011;   assign twf_I[14] = 10'sb1110011110;
	assign twf_R[15] = 10'sb1100000101;   assign twf_I[15] = 10'sb1111001110;

	//Butterfly stages
	butterfly #(.DELAY(16), .DECIMAL(DECIMAL)) s1(
		.clk(clk), .rst_n(rst_n), .cnt_i(cnt_s1), .twfR_i(twf_R[cnt_s1[3:0]]), .twfI_i(twf_I[cnt_s1[3:0]]),
		.data_R_i(s1_R_in), .data_I_i(s1_I_in), .data_R_o(s1_R_out_n), .data_I_o(s1_I_out_n), .valid_i(in_valid)
		);
	butterfly #(.DELAY(8), .DECIMAL(DECIMAL)) s2(
		.clk(clk), .rst_n(rst_n), .cnt_i(cnt_s2), .twfR_i(twf_R[{cnt_s2[2:0],1'd0}]), .twfI_i(twf_I[{cnt_s2[2:0],1'd0}]),
		.data_R_i(s1_R_out), .data_I_i(s1_I_out), .data_R_o(s2_R_out_n), .data_I_o(s2_I_out_n), .valid_i(in_valid)
		);
	butterfly #(.DELAY(4), .DECIMAL(DECIMAL)) s3(
		.clk(clk), .rst_n(rst_n), .cnt_i(cnt_s3), .twfR_i(twf_R[{cnt_s3[1:0],2'd0}]), .twfI_i(twf_I[{cnt_s3[1:0],2'd0}]),
		.data_R_i(s2_R_out), .data_I_i(s2_I_out), .data_R_o(s3_R_out_n), .data_I_o(s3_I_out_n), .valid_i(in_valid)
		);
	butterfly #(.DELAY(2), .DECIMAL(DECIMAL)) s4(
		.clk(clk), .rst_n(rst_n), .cnt_i(cnt_s4), .twfR_i(twf_R[{cnt_s4[0],3'd0}]), .twfI_i(twf_I[{cnt_s4[0],3'd0}]),
		.data_R_i(s3_R_out), .data_I_i(s3_I_out), .data_R_o(s4_R_out_n), .data_I_o(s4_I_out_n), .valid_i(in_valid)
		);
	butterfly #(.DELAY(1), .DECIMAL(DECIMAL)) s5(
		.clk(clk), .rst_n(rst_n), .cnt_i(cnt_s5[4:0]), .twfR_i(twf_R[4'd0]), .twfI_i(twf_I[4'd0]),
		.data_R_i(s4_R_out), .data_I_i(s4_I_out), .data_R_o(s5_R_out), .data_I_o(s5_I_out), .valid_i(in_valid)
		);

	//Conbinational circuit for control signal
	always@(*) begin
		run_n = in_valid || run ? 1 : 0;
		cnt_n = run ? cnt + 1 : cnt;
		valid_o_n = &{cnt_s5,~cnt[5],~in_valid} ? 1 : valid_o;

		for(k = 0; k < 31; k = k + 1) begin
			if(valid_o) begin
				//Shift register
				rearange_R_n[k] = rearange_R[k+1];
				rearange_I_n[k] = rearange_I[k+1];
			end
			else begin
				if(cnt_s5[5] && k == cnt_re) begin
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
			s1_R_in <= 0;
			s1_I_in <= 0;
			for(k = 0; k < 32; k = k + 1) begin
				rearange_R[k] <= 0;
				rearange_I[k] <= 0;
			end
			s1_R_out <= 0; s1_I_out <= 0;
			s2_R_out <= 0; s2_I_out <= 0;
			s3_R_out <= 0; s3_I_out <= 0;
			s4_R_out <= 0; s4_I_out <= 0;
		end
		else begin
			run <= run_n;
			cnt <= cnt_n;
			valid_o <= valid_o_n;
			s1_R_in <= s1_R_in_n;
			s1_I_in <= s1_I_in_n;
			for(k = 0; k < 32; k = k + 1) begin
				rearange_R[k] <= rearange_R_n[k];
				rearange_I[k] <= rearange_I_n[k];
			end
			s1_R_out <= s1_R_out_n; s1_I_out <= s1_I_out_n;
			s2_R_out <= s2_R_out_n; s2_I_out <= s2_I_out_n;
			s3_R_out <= s3_R_out_n; s3_I_out <= s3_I_out_n;
			s4_R_out <= s4_R_out_n; s4_I_out <= s4_I_out_n;
		end
	end

endmodule

module butterfly(
	clk,
	rst_n,
	valid_i,
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
	input clk, rst_n, valid_i;
	input [4:0] cnt_i;
	input signed [LENGTH-1:0] twfR_i;
	input signed [LENGTH-1:0] twfI_i;
	input signed [LENGTH+15:0] data_R_i;
	input signed [LENGTH+15:0] data_I_i;
	output signed [LENGTH+15:0] data_R_o;
	output signed [LENGTH+15:0] data_I_o;	

	//Delay blocks
	reg signed [LENGTH+15:0] delay_R [0:15];
	reg signed [LENGTH+15:0] delay_I [0:15];

	//Flag to determine upper half and lower half
	wire upper;
	assign upper = ~cnt_i[$clog2(DELAY)];

	//Radix-2 butterfly circuit 
	wire signed [LENGTH+15:0] loop_R, loop_I;
	wire signed [LENGTH+15:0] prog_R, prog_I;
	assign loop_R = ~upper ? data_R_i : delay_R[DELAY-1] - data_R_i;
	assign loop_I = ~upper ? data_I_i : delay_I[DELAY-1] - data_I_i;
	assign prog_R = upper ? delay_R[DELAY-1] + data_R_i : delay_R[DELAY-1];
	assign prog_I = upper ? delay_I[DELAY-1] + data_I_i : delay_I[DELAY-1];

	//output complex multiplication
	wire signed [LENGTH*2+15:0] out_R;
	wire signed [LENGTH*2+15:0] out_I;
	wire signed [LENGTH*2+15:0] RR, II, RI, IR;
	assign RR = prog_R * twfR_i; assign II = prog_I * twfI_i; assign RI = prog_R * twfI_i; assign IR = prog_I * twfR_i;
	assign out_R = ~upper ? (RR - II) : {{2{prog_R[LENGTH+15]}},prog_R,{DECIMAL{1'b0}}};
	assign out_I = ~upper ? (RI + IR) : {{2{prog_I[LENGTH+15]}},prog_I,{DECIMAL{1'b0}}};

	//output rounding
	assign data_R_o = out_R[DECIMAL-1] ? out_R[LENGTH+DECIMAL+15:DECIMAL] + 1 : out_R[LENGTH+DECIMAL+15:DECIMAL];
	assign data_I_o = out_I[DECIMAL-1] ? out_I[LENGTH+DECIMAL+15:DECIMAL] + 1 : out_I[LENGTH+DECIMAL+15:DECIMAL];

	//Sequential circuit
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n) begin
			for(d = 0; d < 16; d = d + 1) begin
				delay_R[d] <= 0;
				delay_I[d] <= 0;
			end
		end
		else begin
			//Shift register for delay blocks
			delay_R[0] <= loop_R;
			delay_I[0] <= loop_I;
			for(d = 1; d < 16; d = d + 1) begin
				delay_R[d] <= delay_R[d-1];
				delay_I[d] <= delay_I[d-1];
			end
		end
	end

endmodule
