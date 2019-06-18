`include "./PEs.v"

module TOP(
	clk,   
	rst_n,
	valid_i,
	R_i,
	I_i,
	R_o,
	I_o,
	valid_o
	);

	parameter CHANNEL_SIZE = 4*4;
	parameter BIT_NUM = 18;
	parameter ROTATION_NUM = 14;

	//input & output port definition 
	input clk, rst_n;
	input valid_i;
	input signed [BIT_NUM-1:0] R_i, I_i;
	output reg signed [BIT_NUM-1:0] R_o, I_o;
	output reg valid_o;

	//internal port declaration
	reg [1:0] pe0_valid, pe1_valid;
	reg [1:0] pe0_scheme, pe1_scheme;
	reg signed [BIT_NUM-1:0] pe0_x0_i, pe0_y0_i, pe0_x1_i, pe0_y1_i;
	reg signed [BIT_NUM-1:0] pe1_x0_i, pe1_y0_i, pe1_x1_i, pe1_y1_i;
	wire signed [BIT_NUM-1:0] pe0_x0_o, pe0_y0_o, pe0_x1_o, pe0_y1_o;
	wire signed [BIT_NUM-1:0] pe1_x0_o, pe1_y0_o, pe1_x1_o, pe1_y1_o;

	localparam COMPLEX_2_REAL = 2'd0;
	localparam COMPLEX_ROTATE = 2'd1;
	localparam REAL_NULLIFIED = 2'd2;
	localparam RELATED_ROTATE = 2'd3;

	//wire & reg declaration
	reg [BIT_NUM-1:0] dataR   [0:CHANNEL_SIZE-1];
	reg [BIT_NUM-1:0] dataR_n [0:CHANNEL_SIZE-1];
	reg [BIT_NUM-1:0] dataI   [0:CHANNEL_SIZE-1];
	reg [BIT_NUM-1:0] dataI_n [0:CHANNEL_SIZE-1];
	reg [$clog2(CHANNEL_SIZE)-1:0] cnt, cnt_n;
	reg valid_o_n;

	//state definition
	reg [2:0] STATE, STATE_N;
	reg [4:0] PHASE, PHASE_N;
	localparam IDLE    = 3'd0;
	localparam RECIEVE = 3'd1;
	localparam BIDIAG  = 3'd2;
	localparam SEND    = 3'd3;
	localparam DONE    = 3'd4;

	integer i;

	PEs unit(
		.clk(clk),
		.rst_n(rst_n),
		.PE0_valid_i(pe0_valid),
		.PE1_valid_i(pe1_valid),
		.PE0_scheme_i(pe0_scheme),
		.PE1_scheme_i(pe1_scheme),
		.PE0_X0_i(pe0_x0_i), .PE0_Y0_i(pe0_y0_i),
		.PE0_X1_i(pe0_x1_i), .PE0_Y1_i(pe0_y1_i),
		.PE1_X0_i(pe1_x0_i), .PE1_Y0_i(pe1_y0_i),
		.PE1_X1_i(pe1_x1_i), .PE1_Y1_i(pe1_y1_i),
		.PE0_X0_o(pe0_x0_o), .PE0_Y0_o(pe0_y0_o),
		.PE0_X1_o(pe0_x1_o), .PE0_Y1_o(pe0_y1_o),
		.PE1_X0_o(pe1_x0_o), .PE1_Y0_o(pe1_y0_o),
		.PE1_X1_o(pe1_x1_o), .PE1_Y1_o(pe1_y1_o)
		);

	//state transfer
	always@(*) begin
		
		case(STATE)
			IDLE:    STATE_N = valid_i ? RECIEVE : IDLE;
			RECIEVE: STATE_N = ~valid_i ? BIDIAG : RECIEVE;
			BIDIAG:  STATE_N = PHASE == 5'd19 ? SEND : BIDIAG;
			SEND:    STATE_N = cnt == CHANNEL_SIZE ? DONE : SEND;
			DONE:    STATE_N = DONE;
			default: STATE_N = STATE;
		endcase
	end

	//state function
	always@(*) begin

		PHASE_N = PHASE;
		for(i = 0; i < CHANNEL_SIZE; i = i + 1) begin
			dataR_n[i] = dataR[i];
			dataI_n[i] = dataI[i];
		end
		R_o = 0;
		I_o = 0;
		cnt_n = cnt;
		valid_o_n = valid_o;
		pe0_valid = 2'b00;
		pe1_valid = 2'b00;
		pe0_scheme = 0;
		pe1_scheme = 0;
		pe0_x0_i = 0;
		pe0_y0_i = 0;
		pe0_x1_i = 0;
		pe0_y1_i = 0;
		pe1_x0_i = 0;
		pe1_y0_i = 0;
		pe1_x1_i = 0;
		pe1_y1_i = 0;

		case(STATE)
			IDLE: begin	
				cnt_n = 0;
				valid_o_n = 0;
				PHASE_N = 0;
			end
			RECIEVE: begin
				dataR_n[cnt] = R_i;
				dataI_n[cnt] = I_i;
				cnt_n = cnt + 1;
				valid_o_n = 0;
				PHASE_N = 0;
			end
			BIDIAG: begin
				PHASE_N = PHASE + 1;
				cnt_n = 0;
				valid_o_n = PHASE == 5'd19 ? 1 : 0;
				case(PHASE)
					5'd0: begin
						pe0_valid = 2'b11;
						pe1_valid = 2'b11;
						pe0_scheme = COMPLEX_2_REAL;
						pe1_scheme = COMPLEX_ROTATE;
						pe0_x0_i = dataR[{2'd0,2'd0}];
						pe0_y0_i = dataI[{2'd0,2'd0}];
						pe0_x1_i = dataR[{2'd1,2'd0}];
						pe0_y1_i = dataI[{2'd1,2'd0}];
						pe1_x0_i = dataR[{2'd0,2'd1}];
						pe1_y0_i = dataI[{2'd0,2'd1}];
						pe1_x1_i = dataR[{2'd1,2'd1}];
						pe1_y1_i = dataI[{2'd1,2'd1}];
					end
					5'd1: begin
						pe0_valid = 2'b11;
						pe1_valid = 2'b11;
						pe0_scheme = COMPLEX_ROTATE;
						pe1_scheme = COMPLEX_ROTATE;
						pe0_x0_i = dataR[{2'd0,2'd2}];
						pe0_y0_i = dataI[{2'd0,2'd2}];
						pe0_x1_i = dataR[{2'd1,2'd2}];
						pe0_y1_i = dataI[{2'd1,2'd2}];
						pe1_x0_i = dataR[{2'd0,2'd3}];
						pe1_y0_i = dataI[{2'd0,2'd3}];
						pe1_x1_i = dataR[{2'd1,2'd3}];
						pe1_y1_i = dataI[{2'd1,2'd3}];
					end
					5'd2: begin
						pe0_valid = 2'b11;
						pe1_valid = 2'b11;
						pe0_scheme = COMPLEX_2_REAL;
						pe1_scheme = COMPLEX_ROTATE;
						pe0_x0_i = dataR[{2'd2,2'd0}];
						pe0_y0_i = dataI[{2'd2,2'd0}];
						pe0_x1_i = dataR[{2'd3,2'd0}];
						pe0_y1_i = dataI[{2'd3,2'd0}];
						pe1_x0_i = dataR[{2'd2,2'd1}];
						pe1_y0_i = dataI[{2'd2,2'd1}];
						pe1_x1_i = dataR[{2'd3,2'd1}];
						pe1_y1_i = dataI[{2'd3,2'd1}];
					end
					5'd3: begin
						pe0_valid = 2'b11;
						pe1_valid = 2'b11;
						pe0_scheme = COMPLEX_ROTATE;
						pe1_scheme = COMPLEX_ROTATE;
						pe0_x0_i = dataR[{2'd2,2'd2}];
						pe0_y0_i = dataI[{2'd2,2'd2}];
						pe0_x1_i = dataR[{2'd3,2'd2}];
						pe0_y1_i = dataI[{2'd3,2'd2}];
						pe1_x0_i = dataR[{2'd2,2'd3}];
						pe1_y0_i = dataI[{2'd2,2'd3}];
						pe1_x1_i = dataR[{2'd3,2'd3}];
						pe1_y1_i = dataI[{2'd3,2'd3}];
					end
					5'd4: begin
						pe0_valid = 2'd00;
						pe1_valid = 2'd00;
					end
					5'd5: begin
						pe0_valid = 2'd00;
						pe1_valid = 2'd00;
					end
					5'd6: begin
						pe0_valid = 2'd00;
						pe1_valid = 2'd00;
					end
					5'd7: begin
						pe0_valid = 2'd00;
						pe1_valid = 2'd00;
					end
					5'd8: begin
						pe0_valid = 2'b11;
						pe1_valid = 2'b11;
						pe0_scheme = REAL_NULLIFIED;
						pe1_scheme = RELATED_ROTATE;
						dataR_n[{2'd0,2'd0}] = pe0_x0_o;
						dataI_n[{2'd0,2'd0}] = pe0_y0_o;
						dataR_n[{2'd1,2'd0}] = pe0_x1_o;
						dataI_n[{2'd1,2'd0}] = pe0_y1_o;
						dataR_n[{2'd0,2'd1}] = pe1_x0_o;
						dataI_n[{2'd0,2'd1}] = pe1_y0_o;
						dataR_n[{2'd1,2'd1}] = pe1_x1_o;
						dataI_n[{2'd1,2'd1}] = pe1_y1_o;
						pe0_x0_i = pe0_x0_o;
						pe0_y0_i = pe0_y0_o;
						pe0_x1_i = pe0_x1_o;
						pe0_y1_i = pe0_y1_o;
						pe1_x0_i = pe1_x0_o;
						pe1_y0_i = pe1_y0_o;
						pe1_x1_i = pe1_x1_o;
						pe1_y1_i = pe1_y1_o;
					end
					5'd9: begin
						pe0_valid = 2'b11;
						pe1_valid = 2'b11;
						pe0_scheme = RELATED_ROTATE;
						pe1_scheme = RELATED_ROTATE;
						dataR_n[{2'd0,2'd2}] = pe0_x0_o;
						dataI_n[{2'd0,2'd2}] = pe0_y0_o;
						dataR_n[{2'd1,2'd2}] = pe0_x1_o;
						dataI_n[{2'd1,2'd2}] = pe0_y1_o;
						dataR_n[{2'd0,2'd3}] = pe1_x0_o;
						dataI_n[{2'd0,2'd3}] = pe1_y0_o;
						dataR_n[{2'd1,2'd3}] = pe1_x1_o;
						dataI_n[{2'd1,2'd3}] = pe1_y1_o;
						pe0_x0_i = pe0_x0_o;
						pe0_y0_i = pe0_y0_o;
						pe0_x1_i = pe0_x1_o;
						pe0_y1_i = pe0_y1_o;
						pe1_x0_i = pe1_x0_o;
						pe1_y0_i = pe1_y0_o;
						pe1_x1_i = pe1_x1_o;
						pe1_y1_i = pe1_y1_o;
					end
					5'd10: begin
						pe0_valid = 2'b11;
						pe1_valid = 2'b11;
						pe0_scheme = REAL_NULLIFIED;
						pe1_scheme = RELATED_ROTATE;
						dataR_n[{2'd2,2'd0}] = pe0_x0_o;
						dataI_n[{2'd2,2'd0}] = pe0_y0_o;
						dataR_n[{2'd3,2'd0}] = pe0_x1_o;
						dataI_n[{2'd3,2'd0}] = pe0_y1_o;
						dataR_n[{2'd2,2'd1}] = pe1_x0_o;
						dataI_n[{2'd2,2'd1}] = pe1_y0_o;
						dataR_n[{2'd3,2'd1}] = pe1_x1_o;
						dataI_n[{2'd3,2'd1}] = pe1_y1_o;
						pe0_x0_i = pe0_x1_o; //Reverse
						pe0_y0_i = pe0_y1_o; //order
						pe0_x1_i = pe0_x0_o; //row 3 first
						pe0_y1_i = pe0_y0_o; //row 2 second
						pe1_x0_i = pe1_x1_o; //!!!!!!!
						pe1_y0_i = pe1_y1_o;
						pe1_x1_i = pe1_x0_o;
						pe1_y1_i = pe1_y0_o;
					end
					5'd11: begin
						pe0_valid = 2'b11;
						pe1_valid = 2'b11;
						pe0_scheme = RELATED_ROTATE;
						pe1_scheme = RELATED_ROTATE;
						dataR_n[{2'd2,2'd2}] = pe0_x0_o;
						dataI_n[{2'd2,2'd2}] = pe0_y0_o;
						dataR_n[{2'd3,2'd2}] = pe0_x1_o;
						dataI_n[{2'd3,2'd2}] = pe0_y1_o;
						dataR_n[{2'd2,2'd3}] = pe1_x0_o;
						dataI_n[{2'd2,2'd3}] = pe1_y0_o;
						dataR_n[{2'd3,2'd3}] = pe1_x1_o;
						dataI_n[{2'd3,2'd3}] = pe1_y1_o;
						pe0_x0_i = pe0_x1_o; //Reverse
						pe0_y0_i = pe0_y1_o; //order
						pe0_x1_i = pe0_x0_o; //row 3 first
						pe0_y1_i = pe0_y0_o; //row 2 second
						pe1_x0_i = pe1_x1_o; //!!!!!!!
						pe1_y0_i = pe1_y1_o;
						pe1_x1_i = pe1_x0_o;
						pe1_y1_i = pe1_y0_o;
					end
					5'd12: begin
						pe0_valid = 2'd00;
						pe1_valid = 2'd00;
					end
					5'd13: begin
						pe0_valid = 2'd00;
						pe1_valid = 2'd00;
					end
					5'd14: begin
						pe0_valid = 2'd00;
						pe1_valid = 2'd00;
					end
					5'd15: begin
						pe0_valid = 2'd00;
						pe1_valid = 2'd00;
					end
					5'd16: begin
						pe0_valid = 2'd00;
						pe1_valid = 2'd00;
						dataR_n[{2'd0,2'd0}] = pe0_x0_o;
						dataI_n[{2'd0,2'd0}] = pe0_y0_o;
						dataR_n[{2'd1,2'd0}] = pe0_x1_o;
						dataI_n[{2'd1,2'd0}] = pe0_y1_o;
						dataR_n[{2'd0,2'd1}] = pe1_x0_o;
						dataI_n[{2'd0,2'd1}] = pe1_y0_o;
						dataR_n[{2'd1,2'd1}] = pe1_x1_o;
						dataI_n[{2'd1,2'd1}] = pe1_y1_o;
					end
					5'd17: begin
						pe0_valid = 2'd00;
						pe1_valid = 2'd00;
						dataR_n[{2'd0,2'd2}] = pe0_x0_o;
						dataI_n[{2'd0,2'd2}] = pe0_y0_o;
						dataR_n[{2'd1,2'd2}] = pe0_x1_o;
						dataI_n[{2'd1,2'd2}] = pe0_y1_o;
						dataR_n[{2'd0,2'd3}] = pe1_x0_o;
						dataI_n[{2'd0,2'd3}] = pe1_y0_o;
						dataR_n[{2'd1,2'd3}] = pe1_x1_o;
						dataI_n[{2'd1,2'd3}] = pe1_y1_o;
					end
					5'd18: begin
						pe0_valid = 2'd00;
						pe1_valid = 2'd00;
						dataR_n[{2'd2,2'd0}] = pe0_x1_o;
						dataI_n[{2'd2,2'd0}] = pe0_y1_o;
						dataR_n[{2'd3,2'd0}] = pe0_x0_o;
						dataI_n[{2'd3,2'd0}] = pe0_y0_o;
						dataR_n[{2'd2,2'd1}] = pe1_x1_o;
						dataI_n[{2'd2,2'd1}] = pe1_y1_o;
						dataR_n[{2'd3,2'd1}] = pe1_x0_o;
						dataI_n[{2'd3,2'd1}] = pe1_y0_o;
					end
					5'd19: begin
						pe0_valid = 2'd00;
						pe1_valid = 2'd00;
						dataR_n[{2'd2,2'd2}] = pe0_x1_o;
						dataI_n[{2'd2,2'd2}] = pe0_y1_o;
						dataR_n[{2'd3,2'd2}] = pe0_x0_o;
						dataI_n[{2'd3,2'd2}] = pe0_y0_o;
						dataR_n[{2'd2,2'd3}] = pe1_x1_o;
						dataI_n[{2'd2,2'd3}] = pe1_y1_o;
						dataR_n[{2'd3,2'd3}] = pe1_x0_o;
						dataI_n[{2'd3,2'd3}] = pe1_y0_o;
					end
					default: begin
						pe0_valid = 2'd00;
						pe1_valid = 2'd00;
					end
				endcase
			end
			SEND: begin
				cnt_n = cnt + 1;
				R_o = dataR[cnt];
				I_o = dataI[cnt];
				valid_o_n = cnt == 4'd15 ? 0 : 1;
			end
			DONE: begin
				valid_o_n = 0;
			end
		endcase
	end

	//sequential circuit
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n) begin
			STATE <= IDLE;
			PHASE <= 0;
			cnt <= 0;
			valid_o <= 0;
			for(i = 0; i < CHANNEL_SIZE; i = i + 1) begin
				dataR[i] <= 0;
				dataI[i] <= 0;
			end
		end
		else begin
			STATE <= STATE_N;
			PHASE <= PHASE_N;
			cnt <= cnt_n;
			valid_o <= valid_o_n;
			for(i = 0; i < CHANNEL_SIZE; i = i + 1) begin
				dataR[i] <= dataR_n[i];
				dataI[i] <= dataI_n[i];
			end
		end
	end

endmodule