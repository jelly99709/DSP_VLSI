`timescale 1ns/10ps
`define CYCLE 10.0
`ifdef A
	`define REAL_PAT "./dat/4x4/patternR_a.dat"
	`define IMAG_PAT "./dat/4x4/patternI_a.dat"
	`define REAL_GOLD "./dat/4x4/goldenR_a.dat"
	`define IMAG_GOLD "./dat/4x4/goldenI_a.dat"
`endif
`ifdef B
	`define REAL_PAT "./dat/4x4/patternR_b.dat"
	`define IMAG_PAT "./dat/4x4/patternI_b.dat"
	`define REAL_GOLD "./dat/4x4/goldenR_b.dat"
	`define IMAG_GOLD "./dat/4x4/goldenI_b.dat"
`endif
`ifdef C
	`define REAL_PAT "./dat/4x4/patternR_c.dat"
	`define IMAG_PAT "./dat/4x4/patternI_c.dat"
	`define REAL_GOLD "./dat/4x4/goldenR_c.dat"
	`define IMAG_GOLD "./dat/4x4/goldenI_c.dat"
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

	integer i, j, k, err;
	
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
	end

	always #(`CYCLE*0.5) begin
		clk = ~clk;
	end

	initial begin
		rst = 1;
		valid_i = 0;

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
						if(R_o != GoldR[j] || I_o != GoldI[j]) begin
							err = err + 1;
							if(R_o != GoldR[j]) begin
								$display("ERROR!!! Index %d: Expect real %d, Get %d", j, GoldR[j], R_o);
							end
							if(I_o != GoldI[j]) begin
								$display("ERROR!!! Index %d: Expect imag %d, Get %d", j, GoldI[j], I_o);
							end
						end
						j = j + 1;
					end
					if(j == CHANNEL_SIZE) begin
						disable output_check;
					end
				end
			end
		end
		
		//Finish
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
	        $finish;
	    end
	    else begin
	        $display("------------------------------------------------------------\n");
		    $display("    FAIL! There are %d errors at functional simulation !    \n", err);
		    $display("---------- The test result is ..... FAIL -------------------\n");
	    end
	    $finish;
	end

endmodule