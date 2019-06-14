`timescale 1ns/10ps
`define CYCLE 10.0
`define INFILE_X "./dat/cordic/patternX.dat"
`define INFILE_Y "./dat/cordic/patternY.dat"
`define INFILE_D "./dat/cordic/patternD.dat"
`ifdef VECTOR
	`define GOLDEN_X "./dat/cordic/goldenX_vec.dat"
	`define GOLDEN_Y "./dat/cordic/goldenY_vec.dat"
	`define GOLDEN_D "./dat/cordic/goldenD_vec.dat"
`endif
`ifdef ROTATION
	`define GOLDEN_X "./dat/cordic/goldenX_rot.dat"
	`define GOLDEN_Y "./dat/cordic/goldenY_rot.dat"
`endif

module cordic_test;

	parameter FILE_LENGTH = 128;
	parameter ROTATION_NUM = 14;
	parameter BITNUM = 18;

	reg clk, rst;
	reg start;
	wire finish;
	reg [BITNUM-1:0] x_i, y_i;
	reg d_i;
	wire [BITNUM-1:0] x_o, y_o;
	wire d_o;
	reg mode;
	reg truth_angle;

	reg [BITNUM-1:0] memX [0:FILE_LENGTH-1];
	reg [BITNUM-1:0] memY [0:FILE_LENGTH-1];
	reg [BITNUM-1:0] goldX [0:FILE_LENGTH-1];
	reg [BITNUM-1:0] goldY [0:FILE_LENGTH-1];

	reg [BITNUM-1:0] truth_X;
	reg [BITNUM-1:0] truth_Y;

	reg memD [0:FILE_LENGTH*ROTATION_NUM-1];
	reg goldD [0:FILE_LENGTH*ROTATION_NUM-1];

	integer i, j, k, a_num, err_a, err_d;


	CORDIC_VR #(18,14) CORDIC(
        .clk(clk),   
        .rst_n(rst),
        .start_i(start),
        .mode_i(mode),
        .X_i(x_i),
        .Y_i(y_i),
        .d_i(d_i),
        .X_o(x_o),
        .Y_o(y_o),
        .d_o(d_o),
        .finish_o(finish)
    );

	initial begin
		$fsdbDumpfile("./cordic.fsdb");
		$fsdbDumpvars(0,cordic_test,"+mda");
	end

	initial begin
		$readmemb(`INFILE_X, memX);
		$readmemb(`INFILE_Y, memY);
		$readmemb(`INFILE_D, memD);
		$readmemb(`GOLDEN_X, goldX);
		$readmemb(`GOLDEN_Y, goldY);
		`ifdef VECTOR
			$readmemb(`GOLDEN_D, goldD);
		`endif
	end

	initial begin
		i = 0;
		j = 0;
		k = 0;
		err_a = 0;
		err_d = 0;
	end

	initial begin
		clk = 1;
		rst = 1;
		start = 0;

		`ifdef VECTOR
			mode = 0;
		`endif
		`ifdef ROTATION
			mode = 1;
		`endif

		#(`CYCLE*0.2);
		rst = 0;

		#(`CYCLE*0.3); //first negedge
		rst = 1;

		for(i = 0; i < FILE_LENGTH; i = i + 1) begin
			x_i = memX[i];
			y_i = memY[i];
			start = 1;
			#(`CYCLE*0.6);
			start = 0;
			a_num = 0;
			while(a_num<16) begin: loop
				@(negedge clk) begin
					//check angle
					`ifdef VECTOR
						if(a_num > -1 && a_num < 14) begin
							truth_angle = goldD[k];
							if(d_o != goldD[k]) begin
								$display("Index: %d, Number of Angle: %d", i, a_num);
								$display("Expect Angle: %b, Get: %b",goldD[k],d_o);
								err_a = err_a + 1;
							end
							k = k + 1;
						end
					`endif
						//finish
						/*
						if(finish) begin
							if(err_a) begin
								$display("Too many errors!!!");
								//$finish;
							end
							disable loop;
						end
						*/
					//input angle
					if(a_num > -1 && a_num < 14) begin
						d_i = memD[j];
						j = j + 1;
					end
					a_num = a_num + 1;
				end			
			end

			//check output
			truth_X = goldX[i];
			truth_Y = goldY[i];
			if(x_o != goldX[i]) begin
				$display("Expect X: %d, Get: %d", goldX[i], x_o);
				err_d = err_d + 1;
			end
			if(y_o != goldY[i]) begin
				$display("Expect Y: %d, Get: %d", goldY[i], y_o);
				err_d = err_d + 1;
			end
			if(err_d > 1000) begin
				$display("Too many errors!!!");
				$finish;
			end
		end

		$display("======== Congradulations!!! ========");
		$finish;

	end

	always #(`CYCLE*0.5) begin
		clk = ~clk;
	end

endmodule