module PEs(
    clk,   
    rst_n,
    PE0_valid_i,
    PE1_valid_i,
    PE0_scheme_i, 
    PE1_scheme_i,

    PE0_X0_i,
    PE0_Y0_i,
    PE0_X1_i,
    PE0_Y1_i,
    PE1_X0_i,
    PE1_Y0_i,
    PE1_X1_i,
    PE1_Y1_i,

    PE0_X0_o,
    PE0_Y0_o,
    PE0_X1_o,
    PE0_Y1_o,
    PE1_X0_o,
    PE1_Y0_o,
    PE1_X1_o,
    PE1_Y1_o
);

	parameter BITWIDTH   = 18;
    parameter CORDIC_NUM = 14;

    input clk;
    input rst_n;
    input [1:0] PE0_valid_i;
    input [1:0] PE1_valid_i;
    input [1:0] PE0_scheme_i; 
    input [1:0] PE1_scheme_i;
    input signed [BITWIDTH-1:0] PE0_X0_i;
    input signed [BITWIDTH-1:0] PE0_Y0_i;
    input signed [BITWIDTH-1:0] PE0_X1_i;
    input signed [BITWIDTH-1:0] PE0_Y1_i;
    input signed [BITWIDTH-1:0] PE1_X0_i;
    input signed [BITWIDTH-1:0] PE1_Y0_i;
    input signed [BITWIDTH-1:0] PE1_X1_i;
    input signed [BITWIDTH-1:0] PE1_Y1_i;

    output reg signed [BITWIDTH-1:0] PE0_X0_o;
    output reg signed [BITWIDTH-1:0] PE0_Y0_o;
    output reg signed [BITWIDTH-1:0] PE0_X1_o;
    output reg signed [BITWIDTH-1:0] PE0_Y1_o;
    output reg signed [BITWIDTH-1:0] PE1_X0_o;
    output reg signed [BITWIDTH-1:0] PE1_Y0_o;
    output reg signed [BITWIDTH-1:0] PE1_X1_o;
    output reg signed [BITWIDTH-1:0] PE1_Y1_o;

    wire valid = &PE1_valid_i & (&PE0_valid_i);

    reg signed [BITWIDTH-1:0] x_v1_i,y_v1_i,x_v2_i,y_v2_i;
    reg signed [BITWIDTH-1:0] x_r1_i,y_r1_i,x_r2_i,y_r2_i;
    reg signed [BITWIDTH-1:0] x_r3_i,y_r3_i,x_r4_i,y_r4_i;
    reg signed [CORDIC_NUM-1:0] d1_i,d2_i,d3_i,d4_i;

    wire signed [BITWIDTH-1:0] x_v1_o,y_v1_o,x_v2_o,y_v2_o;
    wire signed [BITWIDTH-1:0] x_r1_o,y_r1_o,x_r2_o,y_r2_o;
    wire signed [BITWIDTH-1:0] x_r3_o,y_r3_o,x_r4_o,y_r4_o;
    wire signed [CORDIC_NUM-1:0] d1_o,d2_o;

    vector v1(x_v1_i,y_v1_i,x_v1_o,y_v1_o,d1_o);
    vector v2(x_v2_i,y_v2_i,x_v2_o,y_v2_o,d2_o);

    rotate r1(x_r1_i,y_r1_i,x_r1_o,y_r1_o,d1_i);
    rotate r2(x_r2_i,y_r2_i,x_r2_o,y_r2_o,d2_i);
    rotate r3(x_r3_i,y_r3_i,x_r3_o,y_r3_o,d3_i);
    rotate r4(x_r4_i,y_r4_i,x_r4_o,y_r4_o,d4_i);

    always@(*) begin
    	if(valid) begin
    		case(PE0_scheme_i)
    			2'd0: begin
    				x_v1_i = PE0_X0_i;
    				y_v1_i = PE0_Y0_i;
    				x_v2_i = PE0_X1_i;
    				y_v2_i = PE0_Y1_i;
    				PE0_X0_o <= #(`CYCLE*8) x_v1_o;
    				PE0_Y0_o <= #(`CYCLE*8) y_v1_o;
    				PE0_X1_o <= #(`CYCLE*8) x_v2_o;
    				PE0_Y1_o <= #(`CYCLE*8) y_v2_o;
    			end
    			2'd1: begin
    				x_r3_i = PE0_X0_i;
    				y_r3_i = PE0_Y0_i;
    				x_r4_i = PE0_X1_i;
    				y_r4_i = PE0_Y1_i;
    				d3_i = d1_o;
    				d4_i = d2_o;
    				PE0_X0_o <= #(`CYCLE*8) x_r3_o;
    				PE0_Y0_o <= #(`CYCLE*8) y_r3_o;
    				PE0_X1_o <= #(`CYCLE*8) x_r4_o;
    				PE0_Y1_o <= #(`CYCLE*8) y_r4_o;
    			end
    			2'd2: begin
    				x_v1_i = PE0_X0_i;
    				y_v1_i = PE0_X1_i;
    				x_r3_i = PE0_Y0_i;
    				y_r3_i = PE0_Y1_i;
    				d3_i = d1_o;
    				PE0_X0_o <= #(`CYCLE*8) x_v1_o;
    				PE0_Y0_o <= #(`CYCLE*8) x_r3_o;
    				PE0_X1_o <= #(`CYCLE*8) y_v1_o;
    				PE0_Y1_o <= #(`CYCLE*8) y_r3_o;
    			end
    			2'd3: begin
    				x_r4_i = PE0_X0_i;
    				y_r4_i = PE0_X1_i;
    				x_r3_i = PE0_Y0_i;
    				y_r3_i = PE0_Y1_i;
    				d3_i = d1_o;
    				d4_i = d1_o;
    				PE0_X0_o <= #(`CYCLE*8) x_r4_o;
    				PE0_Y0_o <= #(`CYCLE*8) x_r3_o;
    				PE0_X1_o <= #(`CYCLE*8) y_r4_o;
    				PE0_Y1_o <= #(`CYCLE*8) y_r3_o;
    			end
    		endcase
    		case(PE1_scheme_i)
    			2'd0: begin
    				x_r1_i = PE1_X0_i;
    				y_r1_i = PE1_Y0_i;
    				x_r2_i = PE1_X1_i;
    				y_r2_i = PE1_Y1_i;
    				d1_i = d1_o;
    				d2_i = d2_o;
    				PE1_X0_o <= #(`CYCLE*8) x_r1_o;
    				PE1_Y0_o <= #(`CYCLE*8) y_r1_o;
    				PE1_X1_o <= #(`CYCLE*8) x_r2_o;
    				PE1_Y1_o <= #(`CYCLE*8) y_r2_o;
    			end
    			2'd1: begin
    				x_r1_i = PE1_X0_i;
    				y_r1_i = PE1_Y0_i;
    				x_r2_i = PE1_X1_i;
    				y_r2_i = PE1_Y1_i;
    				d1_i = d1_o;
    				d2_i = d2_o;
    				PE1_X0_o <= #(`CYCLE*8) x_r1_o;
    				PE1_Y0_o <= #(`CYCLE*8) y_r1_o;
    				PE1_X1_o <= #(`CYCLE*8) x_r2_o;
    				PE1_Y1_o <= #(`CYCLE*8) y_r2_o;
    			end
    			2'd2: begin
    				x_r1_i = PE1_X0_i;
    				y_r1_i = PE1_X1_i;
    				x_r2_i = PE1_Y0_i;
    				y_r2_i = PE1_Y1_i;
    				d1_i = d1_o;
    				d2_i = d1_o;
    				PE1_X0_o <= #(`CYCLE*8) x_r1_o;
    				PE1_Y0_o <= #(`CYCLE*8) x_r2_o;
    				PE1_X1_o <= #(`CYCLE*8) y_r1_o;
    				PE1_Y1_o <= #(`CYCLE*8) y_r2_o;
    			end
    			2'd3: begin
    				x_r1_i = PE1_X0_i;
    				y_r1_i = PE1_X1_i;
    				x_r2_i = PE1_Y0_i;
    				y_r2_i = PE1_Y1_i;
    				d1_i = d1_o;
    				d2_i = d1_o;
    				PE1_X0_o <= #(`CYCLE*8) x_r1_o;
    				PE1_Y0_o <= #(`CYCLE*8) x_r2_o;
    				PE1_X1_o <= #(`CYCLE*8) y_r1_o;
    				PE1_Y1_o <= #(`CYCLE*8) y_r2_o;
    			end
    		endcase
    	end
    end

endmodule

module vector(x_i,y_i,x_o,y_o,d_o);

	parameter BITWIDTH   = 18;
    parameter CORDIC_NUM = 14;

	input signed [BITWIDTH-1:0] x_i, y_i;
	output reg signed [BITWIDTH-1:0] x_o, y_o;
	output reg [CORDIC_NUM-1:0] d_o;

	reg signed [BITWIDTH-1:0] X [0:CORDIC_NUM];
	reg signed [BITWIDTH-1:0] Y [0:CORDIC_NUM];
	reg sign;
	integer i;

	wire signed [14:0] K = 15'sb010011011011101;
	reg [15+BITWIDTH-1:0] scale_X, scale_Y;

	always@(*) begin
		X[0] = x_i;
		Y[0] = y_i;
		for(i = 1; i < CORDIC_NUM + 1; i = i + 1) begin
			sign = X[i-1][BITWIDTH-1] ^ Y[i-1][BITWIDTH-1];
			if(sign) begin
				X[i] = X[i-1] - (Y[i-1] >>> (i-1));
				Y[i] = Y[i-1] + (X[i-1] >>> (i-1));
			end
			else begin
				X[i] = X[i-1] + (Y[i-1] >>> (i-1));
				Y[i] = Y[i-1] - (X[i-1] >>> (i-1));
			end
			d_o[i-1] = sign;
		end
		scale_X = X[CORDIC_NUM] * K;
		scale_Y = Y[CORDIC_NUM] * K;
		x_o = {scale_X[15+BITWIDTH-1], scale_X[15+BITWIDTH-3:BITWIDTH-4]} + scale_X[BITWIDTH-5];
		y_o = {scale_Y[15+BITWIDTH-1], scale_Y[15+BITWIDTH-3:BITWIDTH-4]} + scale_Y[BITWIDTH-5];
	end
endmodule

module rotate(x_i,y_i,x_o,y_o,d_i);

	parameter BITWIDTH   = 18;
    parameter CORDIC_NUM = 14;

	input signed [BITWIDTH-1:0] x_i, y_i;
	output reg signed [BITWIDTH-1:0] x_o, y_o;
	input [CORDIC_NUM-1:0] d_i;

	reg signed [BITWIDTH-1:0] X [0:CORDIC_NUM];
	reg signed [BITWIDTH-1:0] Y [0:CORDIC_NUM];
	reg sign;
	integer i;

	wire signed [14:0] K = 15'sb010011011011101;
	reg [15+BITWIDTH-1:0] scale_X, scale_Y;

	always@(*) begin
		X[0] = x_i;
		Y[0] = y_i;
		for(i = 1; i < CORDIC_NUM + 1; i = i + 1) begin
			sign = d_i[i-1];
			if(sign) begin
				X[i] = X[i-1] - (Y[i-1] >>> (i-1));
				Y[i] = Y[i-1] + (X[i-1] >>> (i-1));
			end
			else begin
				X[i] = X[i-1] + (Y[i-1] >>> (i-1));
				Y[i] = Y[i-1] - (X[i-1] >>> (i-1));
			end
		end
		scale_X = X[CORDIC_NUM] * K;
		scale_Y = Y[CORDIC_NUM] * K;
		x_o = {scale_X[15+BITWIDTH-1], scale_X[15+BITWIDTH-3:BITWIDTH-4]} + scale_X[BITWIDTH-5];
		y_o = {scale_Y[15+BITWIDTH-1], scale_Y[15+BITWIDTH-3:BITWIDTH-4]} + scale_Y[BITWIDTH-5];

	end
endmodule