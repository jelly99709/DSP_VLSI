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
