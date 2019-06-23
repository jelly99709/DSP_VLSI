`timescale 1ns/10ps
`define CYCLE 7.0
`ifdef A
	`define REAL_PAT "../../dat/4x4/patternR_a.dat"
	`define IMAG_PAT "../../dat/4x4/patternI_a.dat"
	`define REAL_GOLD "../../dat/4x4/goldenR_a.dat"
	`define IMAG_GOLD "../../dat/4x4/goldenI_a.dat"
`elsif B
	`define REAL_PAT "../../dat/4x4/patternR_b.dat"
	`define IMAG_PAT "../../dat/4x4/patternI_b.dat"
	`define REAL_GOLD "../../dat/4x4/goldenR_b.dat"
	`define IMAG_GOLD "../../dat/4x4/goldenI_b.dat"
`elsif C
	`define REAL_PAT "../../dat/4x4/patternR_c.dat"
	`define IMAG_PAT "../../dat/4x4/patternI_c.dat"
	`define REAL_GOLD "../../dat/4x4/goldenR_c.dat"
	`define IMAG_GOLD "../../dat/4x4/goldenI_c.dat"
`elsif D
	`define REAL_PAT "../../dat/bidiag/patternR.dat"
	`define IMAG_PAT "../../dat/bidiag/patternI.dat"
	`define REAL_GOLD "../../dat/bidiag/goldenR.dat"
	`define IMAG_GOLD "../../dat/bidiag/goldenI.dat"
`endif
`define SDF_FILE "../SYN/netlist/SVD_syn.sdf"

module x4_test;

	parameter CHANNEL_SIZE = 16;
	parameter ROTATION_NUM = 14;
	parameter BITNUM = 18;

	reg clk, rst;
	reg valid_i;
	wire[1:0] valid_o;
	reg signed [BITNUM-1:0] R_i, I_i;
	wire signed [BITNUM-1:0] R_o, I_o;

	reg signed [BITNUM-1:0] InR [0:CHANNEL_SIZE-1];
	reg signed [BITNUM-1:0] InI [0:CHANNEL_SIZE-1];
	reg signed [BITNUM-1:0] GoldR [0:CHANNEL_SIZE-1];
	reg signed [BITNUM-1:0] GoldI [0:CHANNEL_SIZE-1];
	reg signed [BITNUM-1:0] OrigR [0:CHANNEL_SIZE-1];
	reg signed [BITNUM-1:0] OrigI [0:CHANNEL_SIZE-1];
	reg signed [BITNUM-1:0] L_vecR [0:CHANNEL_SIZE-1];
	reg signed [BITNUM-1:0] L_vecI [0:CHANNEL_SIZE-1];
	reg signed [BITNUM-1:0] CheckR [0:CHANNEL_SIZE-1];
	reg signed [BITNUM-1:0] CheckI [0:CHANNEL_SIZE-1];
	reg signed [BITNUM-1:0] R_vecR [0:CHANNEL_SIZE-1];
	reg signed [BITNUM-1:0] R_vecI [0:CHANNEL_SIZE-1];

	reg signed [31:0] noise, signal;
	reg [31:0] noise_energy, signal_energy;

	integer i, j, k, err , SNR_ratio, cnt;

	real abc;
	
	TOP  x4(
        .clk(clk),   
        .rst_n(rst),
        .valid_i(valid_i),
        .R_i(R_i),
        .I_i(I_i),
        .R_o(R_o),
        .I_o(I_o),
        .valid_o(valid_o)
    	);

	`ifdef SDF
		initial begin
			$sdf_annotate(`SDF_FILE,x4);
		end
	`endif

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
		cnt = 0;
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
				OrigR[i] = R_i;
				OrigI[i] = I_i;
				if(i == CHANNEL_SIZE - 1) begin //valid_i holds high for CHANNEL_SIZE cycles
					valid_i = 0;
				end
			end
		end

		#(`CYCLE * 200000)
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
						if(valid_o == 1) begin
							CheckR[j] = R_o;
							CheckI[j] = I_o;
						end
						else if(valid_o == 2) begin
							L_vecR[j] = R_o;
							L_vecI[j] = I_o;
						end
						else if(valid_o == 3) begin
							R_vecR[j] = R_o;
							R_vecI[j] = I_o;
						end
						if((j == CHANNEL_SIZE-1 && valid_o != 3) || (j == 3 && valid_o == 1))begin
							j = 0;
							cnt = cnt + 1;
						end
						else begin
							j = j + 1;
						end
					end
					if(j == CHANNEL_SIZE && cnt == 2) begin
						$display("S = [(%d+%dj) (0+0j) (0+0j) (0+0j);", CheckR[0], CheckI[0]);
						$display("(0+0j) (%d+%dj) (0+0j) (0+0j);", CheckR[1], CheckI[1]);
						$display("(0+0j) (0+0j) (%d+%dj) (0+0j);", CheckR[2], CheckI[2]);
						$display("(0+0j) (0+0j) (0+0j) (%d+%dj)]/16384;", CheckR[3], CheckI[3]);
						$display("U = [(%d+%dj) (%d+%dj) (%d+%dj) (%d+%dj);", L_vecR[0], L_vecI[0], L_vecR[1], L_vecI[1], L_vecR[2], L_vecI[2], L_vecR[3], L_vecI[3]);
						$display("(%d+%dj) (%d+%dj) (%d+%dj) (%d+%dj);", L_vecR[4], L_vecI[4], L_vecR[5], L_vecI[5], L_vecR[6], L_vecI[6], L_vecR[7], L_vecI[7]);
						$display("(%d+%dj) (%d+%dj) (%d+%dj) (%d+%dj);", L_vecR[8], L_vecI[8], L_vecR[9], L_vecI[9], L_vecR[10], L_vecI[10], L_vecR[11], L_vecI[11]);
						$display("(%d+%dj) (%d+%dj) (%d+%dj) (%d+%dj)]/16384;", L_vecR[12], L_vecI[12], L_vecR[13], L_vecI[13], L_vecR[14], L_vecI[14], L_vecR[15], L_vecI[15]);
						$display("V = [(%d+%dj) (%d+%dj) (%d+%dj) (%d+%dj);", R_vecR[0], R_vecI[0], R_vecR[1], R_vecI[1], R_vecR[2], R_vecI[2], R_vecR[3], R_vecI[3]);
						$display("(%d+%dj) (%d+%dj) (%d+%dj) (%d+%dj);", R_vecR[4], R_vecI[4], R_vecR[5], R_vecI[5], R_vecR[6], R_vecI[6], R_vecR[7], R_vecI[7]);
						$display("(%d+%dj) (%d+%dj) (%d+%dj) (%d+%dj);", R_vecR[8], R_vecI[8], R_vecR[9], R_vecI[9], R_vecR[10], R_vecI[10], R_vecR[11], R_vecI[11]);
						$display("(%d+%dj) (%d+%dj) (%d+%dj) (%d+%dj)]/16384;", R_vecR[12], R_vecI[12], R_vecR[13], R_vecI[13], R_vecR[14], R_vecI[14], R_vecR[15], R_vecI[15]);
						$display("H = [(%d+%dj) (%d+%dj) (%d+%dj) (%d+%dj);", OrigR[0], OrigI[0], OrigR[1], OrigI[1], OrigR[2], OrigI[2], OrigR[3], OrigI[3]);
						$display("(%d+%dj) (%d+%dj) (%d+%dj) (%d+%dj);", OrigR[4], OrigI[4], OrigR[5], OrigI[5], OrigR[6], OrigI[6], OrigR[7], OrigI[7]);
						$display("(%d+%dj) (%d+%dj) (%d+%dj) (%d+%dj);", OrigR[8], OrigI[8], OrigR[9], OrigI[9], OrigR[10], OrigI[10], OrigR[11], OrigI[11]);
						$display("(%d+%dj) (%d+%dj) (%d+%dj) (%d+%dj)]/16384;", OrigR[12], OrigI[12], OrigR[13], OrigI[13], OrigR[14], OrigI[14], OrigR[15], OrigI[15]);
						$display("H - U*S*V'");
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