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

	parameter BIT_NUM = 18;
	parameter ROTATION_NUM = 14;

	input clk, rst_n;
	input valid_i;
	input signed [BIT_NUM-1:0] R_i, I_i;
	output signed [BIT_NUM-1:0] R_o, I_o;
	output valid_o;

	PE pe1();
	PE pe2();

	//state transfer
	always@(*) begin

	end

	//state function
	always@(*) begin

	end

	//sequential circuit
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n) begin

		end
		else begin

		end
	end

endmodule