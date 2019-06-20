`timescale 1ns/10ps
`define CYCLE 10.0
`ifdef A
	`define REAL_PAT "./dat/4x4/patternR_a.dat"
	`define IMAG_PAT "./dat/4x4/patternI_a.dat"
	`define REAL_GOLD "./dat/4x4/goldenR_a.dat"
	`define IMAG_GOLD "./dat/4x4/goldenI_a.dat"
`elsif B
	`define REAL_PAT "./dat/4x4/patternR_b.dat"
	`define IMAG_PAT "./dat/4x4/patternI_b.dat"
	`define REAL_GOLD "./dat/4x4/goldenR_b.dat"
	`define IMAG_GOLD "./dat/4x4/goldenI_b.dat"
`elsif C
	`define REAL_PAT "./dat/4x4/patternR_c.dat"
	`define IMAG_PAT "./dat/4x4/patternI_c.dat"
	`define REAL_GOLD "./dat/4x4/goldenR_c.dat"
	`define IMAG_GOLD "./dat/4x4/goldenI_c.dat"
`elsif D
	`define REAL_PAT "./dat/bidiag/patternR.dat"
	`define IMAG_PAT "./dat/bidiag/patternI.dat"
	`define REAL_GOLD "./dat/bidiag/goldenR.dat"
	`define IMAG_GOLD "./dat/bidiag/goldenI.dat"
`endif

module x4_test;

	parameter CHANNEL_SIZE = 16;
	parameter ROTATION_NUM = 14;
	parameter BITNUM = 18;

	reg clk, rst;
	reg valid_i;
	wire valid_o;
	reg signed [BITNUM-1:0] R_i, I_i;
	wire signed [BITNUM-1:0] R_o, I_o;

	reg signed [BITNUM-1:0] InR [0:CHANNEL_SIZE-1];
	reg signed [BITNUM-1:0] InI [0:CHANNEL_SIZE-1];
	reg signed [BITNUM-1:0] GoldR [0:CHANNEL_SIZE-1];
	reg signed [BITNUM-1:0] GoldI [0:CHANNEL_SIZE-1];
	reg signed [BITNUM-1:0] CheckR [0:CHANNEL_SIZE-1];
	reg signed [BITNUM-1:0] CheckI [0:CHANNEL_SIZE-1];

	reg signed [31:0] noise, signal;
	reg [31:0] noise_energy, signal_energy;

	integer i, j, k, err , SNR_ratio;

	real abc;
	
	TOP #(CHANNEL_SIZE, BITNUM, ROTATION_NUM) x4(
        .clk(clk),   
        .rst_n(rst),
        .valid_i(valid_i),
        .R_i(R_i),
        .I_i(I_i),
        .R_o(R_o),
        .I_o(I_o),
        .valid_o(valid_o)
    	);

	initial begin
		$fsdbDumpfile("./x4_test.fsdb");
		$fsdbDumpvars(0, x4_test, "+mda");
	end

	initial begin
		$readmemb(`REAL_PAT, InR);
		$readmemb(`IMAG_PAT, InI);
		$readmemb(`REAL_GOLD, GoldR);
		$readmemb(`IMAG_GOLD, GoldI);
	end

	initial begin
		j = 0;
		err = 0;
		clk = 1;
		signal_energy = 0;
		noise_energy = 0;
	end

	always #(`CYCLE*0.5) begin
		clk = ~clk;
	end

	initial begin
		rst = 1;
		valid_i = 0;
		$display("========= Start =========");
		#(`CYCLE*0.2);
		rst = 0;

		#(`CYCLE*0.8); //Later than first posedge
		rst = 1;

		#(`CYCLE*0.3) //First negedge after reset
		valid_i = 1;

		#(`CYCLE*0.2) //Send data 1 cycle after valid_i
		for(i = 0; i < CHANNEL_SIZE; i = i + 1) begin
			@(negedge clk) begin
				R_i = InR[i];
				I_i = InI[i];
				if(i == CHANNEL_SIZE - 1) begin //valid_i holds high for CHANNEL_SIZE cycles
					valid_i = 0;
				end
			end
		end

		#(`CYCLE * 200)
		$display("========= Timeout =========");
		$finish;

	end

	//Output check
	initial begin
		begin : output_check
			while(1) begin
				@(negedge clk) begin
					if(valid_o) begin
						`ifdef D
							noise = GoldR[j] - R_o;
							noise_energy = noise_energy + noise*noise;
							noise = GoldI[j] - I_o;
							noise_energy = noise_energy + noise*noise;
						`else
							if(R_o != GoldR[j] || I_o != GoldI[j]) begin
								err = err + 1;
								if(R_o != GoldR[j]) begin
									$display("ERROR!!! Index %d: Expect real %d, Get %d", j, GoldR[j], R_o);
								end
								if(I_o != GoldI[j]) begin
									$display("ERROR!!! Index %d: Expect imag %d, Get %d", j, GoldI[j], I_o);
								end
							end
						`endif
						CheckR[j] = R_o;
						CheckI[j] = I_o;
						j = j + 1;
					end
					if(j == CHANNEL_SIZE) begin
						$display("MyAns = svd([(%d+%dj) (%d+%dj) (%d+%dj) (%d+%dj);", CheckR[0], CheckI[0], CheckR[1], CheckI[1], CheckR[2], CheckI[2], CheckR[3], CheckI[3]);
						$display("(%d+%dj) (%d+%dj) (%d+%dj) (%d+%dj);", CheckR[4], CheckI[4], CheckR[5], CheckI[5], CheckR[6], CheckI[6], CheckR[7], CheckI[7]);
						$display("(%d+%dj) (%d+%dj) (%d+%dj) (%d+%dj);", CheckR[8], CheckI[8], CheckR[9], CheckI[9], CheckR[10], CheckI[10], CheckR[11], CheckI[11]);
						$display("(%d+%dj) (%d+%dj) (%d+%dj) (%d+%dj)])", CheckR[12], CheckI[12], CheckR[13], CheckI[13], CheckR[14], CheckI[14], CheckR[15], CheckI[15]);
						$display("TruthAns = svd([(%d+%dj) (%d+%dj) (%d+%dj) (%d+%dj);", GoldR[0], GoldI[0], GoldR[1], GoldI[1], GoldR[2], GoldI[2], GoldR[3], GoldI[3]);
						$display("(%d+%dj) (%d+%dj) (%d+%dj) (%d+%dj);", GoldR[4], GoldI[4], GoldR[5], GoldI[5], GoldR[6], GoldI[6], GoldR[7], GoldI[7]);
						$display("(%d+%dj) (%d+%dj) (%d+%dj) (%d+%dj);", GoldR[8], GoldI[8], GoldR[9], GoldI[9], GoldR[10], GoldI[10], GoldR[11], GoldI[11]);
						$display("(%d+%dj) (%d+%dj) (%d+%dj) (%d+%dj)])", GoldR[12], GoldI[12], GoldR[13], GoldI[13], GoldR[14], GoldI[14], GoldR[15], GoldI[15]);
						disable output_check;
					end
				end
			end
		end
		
		//Finish
		`ifdef D
			if(noise_energy == 0) begin
				$display("\nSNR = Infinity\n");
				$display("=======================The test result is ..... PASS=========================");
		        $display("\n");
		        $display("        *************************************************              ");
		        $display("        **                                             **      /|__/|");
		        $display("        **             Congratulations !!              **     / O,O  \\");
		        $display("        **                                             **    /_____   \\");
		        $display("        **  All data have been generated successfully! **   /^ ^ ^ \\  |");
		        $display("        **                                             **  |^ ^ ^ ^ |w|");
		        $display("        *************************************************   \\m___m__|_|");
		        $display("\n");
		        $display("============================================================================");
			end
			else begin
				SNR_ratio = signal_energy/noise_energy;
				$display("\nSNR = %2.2f\n", $log10(SNR_ratio)*10.0);

				if(SNR_ratio >= 10000) begin
					$display("=======================The test result is ..... PASS=========================");
			        $display("\n");
			        $display("        *************************************************              ");
			        $display("        **                                             **      /|__/|");
			        $display("        **             Congratulations !!              **     / O,O  \\");
			        $display("        **                                             **    /_____   \\");
			        $display("        **  All data have been generated successfully! **   /^ ^ ^ \\  |");
			        $display("        **                                             **  |^ ^ ^ ^ |w|");
			        $display("        *************************************************   \\m___m__|_|");
			        $display("\n");
			        $display("============================================================================");
				end
				else begin
					$display("------------------------------------------------------------\n");
			  		$display("        FAIL! SNR < 40dB at functional simulation !         \n");
			 		$display("---------- The test result is ..... FAIL -------------------\n");
				end
			end
		`else
			if(err == 0) begin
		        $display("=======================The test result is ..... PASS=========================");
		        $display("\n");
		        $display("        *************************************************              ");
		        $display("        **                                             **      /|__/|");
		        $display("        **             Congratulations !!              **     / O,O  \\");
		        $display("        **                                             **    /_____   \\");
		        $display("        **  All data have been generated successfully! **   /^ ^ ^ \\  |");
		        $display("        **                                             **  |^ ^ ^ ^ |w|");
		        $display("        *************************************************   \\m___m__|_|");
		        $display("\n");
		        $display("============================================================================");
		    end
		    else begin
		        $display("------------------------------------------------------------\n");
			    $display("    FAIL! There are %d errors at functional simulation !    \n", err);
			    $display("---------- The test result is ..... FAIL -------------------\n");
		    end
		`endif
	    $finish;
	end

endmodule