module PEs (
    clk,   
    rst_n,
    valid_i,
    PE0_scheme, 
    PE1_scheme,

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
    input valid_i;
    input [1:0] PE0_scheme; 
    input [1:0] PE1_scheme;
    input signed [BITWIDTH-1:0] PE0_X0_i;
    input signed [BITWIDTH-1:0] PE0_Y0_i;
    input signed [BITWIDTH-1:0] PE0_X1_i;
    input signed [BITWIDTH-1:0] PE0_Y1_i;
    input signed [BITWIDTH-1:0] PE1_X0_i;
    input signed [BITWIDTH-1:0] PE1_Y0_i;
    input signed [BITWIDTH-1:0] PE1_X1_i;
    input signed [BITWIDTH-1:0] PE1_Y1_i;

    output signed [BITWIDTH-1:0] PE0_X0_o;
    output signed [BITWIDTH-1:0] PE0_Y0_o;
    output signed [BITWIDTH-1:0] PE0_X1_o;
    output signed [BITWIDTH-1:0] PE0_Y1_o;
    output signed [BITWIDTH-1:0] PE1_X0_o;
    output signed [BITWIDTH-1:0] PE1_Y0_o;
    output signed [BITWIDTH-1:0] PE1_X1_o;
    output signed [BITWIDTH-1:0] PE1_Y1_o;
    output valid_o;

    wire [1:0] PE0_idle;
    wire [1:0] PE0_scheme;
    wire signed [BITWIDTH-1:0] PE0_X0_in;
    wire signed [BITWIDTH-1:0] PE0_Y0_in;
    wire signed [BITWIDTH-1:0] PE0_X1_in;
    wire signed [BITWIDTH-1:0] PE0_Y1_in;
    reg [CORDIC_NUM-1:0] PE_angle_d0_in;
    reg [CORDIC_NUM-1:0] PE_angle_d1_in;

    wire signed [BITWIDTH-1:0] PE0_X0_out;
    wire signed [BITWIDTH-1:0] PE0_Y0_out;
    wire signed [BITWIDTH-1:0] PE0_X1_out;
    wire signed [BITWIDTH-1:0] PE0_Y1_out;
    wire [CORDIC_NUM-1:0] PE0_angle_d0_out;
    wire [CORDIC_NUM-1:0] PE0_angle_d1_out;
    wire [CORDIC_NUM/2-1:0] PE0_angle_val0_out;
    wire [CORDIC_NUM/2-1:0] PE0_angle_val1_out;

    reg [CORDIC_NUM/2:0] val, val_n;
    reg [CORDIC_NUM-1:0] PE0_angle0, PE0_angle0_n;
    reg [CORDIC_NUM-1:0] PE0_angle1, PE0_angle1_n;

    integer i;

    assign PE0_idle = {2{~valid_i}};
    assign PE0_scheme = 2'b11;

    assign PE0_X0_in = R_i;
    assign PE0_Y0_in = I_i;

    assign R_o = PE0_X0_out;
    assign I_o = PE0_Y0_out;
    assign valid_o = val[CORDIC_NUM/2];

    PE #(BITWIDTH,CORDIC_NUM) PE0(
        .clk(clk),
        .rst_n(rst_n),
        .idle(PE0_idle),
        .scheme(PE0_scheme), 

        .X0_i(PE0_X0_in),
        .Y0_i(PE0_Y0_in),
        .X1_i(0),
        .Y1_i(0),
        .angle_d0_i(PE0_angle_d0_in),
        .angle_d1_i(0), 

        .X0_o(PE0_X0_out),
        .Y0_o(PE0_Y0_out),
        .X1_o(PE0_X1_out),
        .Y1_o(PE0_Y1_out),
        .angle_d0_o(PE0_angle_d0_out),
        .angle_d1_o(PE0_angle_d1_out),
        .angle_val0_o(PE0_angle_val0_out),
        .angle_val1_o(PE0_angle_val1_out)  

    );

    always @(*) begin
        for(i=0;i<CORDIC_NUM/2;i=i+1) begin
            PE0_angle_d0_in[2*i]   = PE0_angle0[2*i] & (~PE0_angle_val0_out[i]) + PE0_angle_d0_out[2*i] & (PE0_angle_val0_out[i]) ;
            PE0_angle_d0_in[2*i+1] = PE0_angle0[2*i+1] & (~PE0_angle_val0_out[i]) + PE0_angle_d0_out[2*i+1] & (PE0_angle_val0_out[i]) ;
        end
    end


    always @(*) begin
        val_n[0] = valid_i;
        for(i=1;i<CORDIC_NUM/2+1;i=i+1) begin
            val_n[i] = val[i-1];
        end
        for(i=0;i<CORDIC_NUM;i=i+1) begin
            if(PE0_angle_val1_out[i]) begin
                PE0_angle0_n[i] = PE0_angle_d0_out[i];
            end
            else begin
                PE0_angle0_n[i] = PE0_angle0[i];
            end
        end
        for(i=0;i<CORDIC_NUM;i=i+1) begin
            if(PE0_angle_val1_out[i]) begin
                PE0_angle1_n[i] = PE0_angle_d1_out[i];
            end
            else begin
                PE0_angle1_n[i] = PE0_angle1[i];
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            val        <= 0;
            PE0_angle0 <= 0;
            PE0_angle1 <= 0;
        end 
        else begin
            val        <= val_n;
            PE0_angle0 <= PE0_angle0_n;
            PE0_angle1 <= PE0_angle1_n;
        end
    end

endmodule

module PE(
    clk,
    rst_n,
    idle,
    scheme,

    X0_i,
    Y0_i,
    X1_i,
    Y1_i,
    angle_d0_i,
    angle_d1_i,

    X0_o,
    Y0_o,
    X1_o,
    Y1_o,
    angle_d0_o,
    angle_d1_o,
    angle_val0_o,
    angle_val1_o 

    //out_valid

);

    parameter BITWIDTH   = 18;
    parameter CORDIC_NUM = 14;

    localparam SCHEME0 = 2'b00;
    localparam SCHEME1 = 2'b01;
    localparam SCHEME2 = 2'b10;
    localparam SCHEME3 = 2'b11;

    input clk;
    input rst_n;
    input [1:0] idle;
    input [1:0] scheme;

    input signed [BITWIDTH-1:0] X0_i;
    input signed [BITWIDTH-1:0] Y0_i;
    input signed [BITWIDTH-1:0] X1_i;
    input signed [BITWIDTH-1:0] Y1_i;
    input [CORDIC_NUM-1:0] COR_din_0, COR_din_1;
    input [CORDIC_NUM-1:0] COR_dout_0, COR_dout_1;

    output signed [BITWIDTH-1:0] X0_o;
    output signed [BITWIDTH-1:0] Y0_o;
    output signed [BITWIDTH-1:0] X1_o;
    output signed [BITWIDTH-1:0] Y1_o;
    output [CORDIC_NUM-1:0] angle_d0_o, angle_d1_o;
    output [CORDIC_NUM/2-1:0] angle_val0_o, angle_val1_o;

    //output out_valid;



    wire COR_start_0, COR_start_1;
    wire COR_mode_0, COR_mode_1;
    wire signed [BITWIDTH-1:0] COR_Xin_0, COR_Xin_1;
    wire signed [BITWIDTH-1:0] COR_Yin_0, COR_Yin_1;
    wire signed [BITWIDTH-1:0] COR_Xout_0, COR_Xout_1;
    wire signed [BITWIDTH-1:0] COR_Yout_0, COR_Yout_1;

    reg [CORDIC_NUM/2:0]   isswap, isswap_n;
    reg [CORDIC_NUM/2-1:0] a0_val, a0_val_n;
    reg [CORDIC_NUM/2-1:0] a1_val, a1_val_n;

    integer i;

    assign {COR_start_1, COR_start_0} = ~idle;
    assign COR_Xin_0 = (isswap_n[0])? Y1_i : X0_i;
    assign COR_Yin_0 = Y0_i;
    assign COR_Xin_1 = X1_i;
    assign COR_Yin_1 = (isswap_n[0])? X0_i : Y1_i;
    assign COR_din_0 = angle_d0_i;
    assign COR_din_1 = angle_d1_i;


    assign X0_o = (isswap[CORDIC_NUM/2])? COR_Yout_1 : COR_Xout_0;
    assign Y0_o = COR_Yout_0;
    assign X1_o = COR_Xout_1;
    assign Y1_o = (isswap[CORDIC_NUM/2])? COR_Xout_0 : COR_Yout_1;
    assign angle_d0_o = COR_dout_0;
    assign angle_d1_o = COR_dout_1;
    assign angle_val0_o = a0_val;
    assign angle_val1_o = a1_val; 

    CORDIC_VR #(BITWIDTH,CORDIC_NUM) CORDIC0(
        .clk(clk),   
        .rst_n(rst_n),
        .start_i(COR_start_0),
        .mode_i(COR_mode_0),
        .X_i(COR_Xin_0),
        .Y_i(COR_Yin_0),
        .d_i(COR_din_0),
        .X_o(COR_Xout_0),
        .Y_o(COR_Yout_0),
        .d_o(COR_dout_0),
    );

    CORDIC_VR #(BITWIDTH,CORDIC_NUM) CORDIC1(
        .clk(clk),   
        .rst_n(rst_n),
        .start_i(COR_start_1),
        .mode_i(COR_mode_1),
        .X_i(COR_Xin_1),
        .Y_i(COR_Yin_1),
        .d_i(COR_din_1),
        .X_o(COR_Xout_1),
        .Y_o(COR_Yout_1),
        .d_o(COR_dout_1),
    );

    always @(*) begin
        case(scheme)
            SCHEME0: begin
                isswap_n[0] = 0;
            end
            SCHEME1: begin
                isswap_n[0] = 0;
            end
            SCHEME2: begin
                isswap_n[0] = 1;
            end
            SCHEME3: begin
                isswap_n[0] = 1;
            end
        endcase

        for(i=1;i<CORDIC_NUM/2+1;i=i+1) begin
            isswap_n[i] = isswap[i-1];
        end

        a0_val_n[i] = COR_start_0 & (~COR_mode_0);
        a1_val_n[i] = COR_start_1 & (~COR_mode_1);
        for(i=1;i<CORDIC_NUM/2;i=i+1) begin
            a0_val_n[i] = a0_val[i-1];
            a1_val_n[i] = a1_val[i-1];
        end    
    end

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            for(i=0;i<CORDIC_NUM/2+1;i=i+1) begin
                isswap[i] <= 0;
            end
            for(i=0;i<CORDIC_NUM/2;i=i+1) begin
                a0_val[i] = 0;
                a1_val[i] = 0;
            end
        end 
        else begin
            for(i=0;i<CORDIC_NUM/2+1;i=i+1) begin
                isswap[i] <= isswap_n[i];
            end
            for(i=0;i<CORDIC_NUM/2;i=i+1) begin
                a0_val[i] = a0_val_n[i];
                a1_val[i] = a1_val_n[i];
            end
        end
    end

    
endmodule // PE


module CORDIC_VR(
    // Input
    clk,   
    rst_n,
    start_i,
    mode_i,
    X_i,
    Y_i,
    d_i,
    // Output
    X_o,
    Y_o,
    d_o,
);
    
    parameter BITWIDTH   = 18;
    parameter CORDIC_NUM = 14;

    localparam VECTOR = 1'b0;
    localparam ROTATE = 1'b1;

    localparam K = 15'b010011011011101;

    input clk;
    input rst_n;

    input start_i;
    input mode_i;
    input signed [BITWIDTH-1:0] X_i; 
    input signed [BITWIDTH-1:0] Y_i;
    input wire [CORDIC_NUM-1:0] d_i; 
    
    output signed [BITWIDTH-1:0] X_o; 
    output signed [BITWIDTH-1:0] Y_o;
    output reg [CORDIC_NUM-1:0] d_o;

    // Register
    reg [1:0] state, state_n;
    reg [CORDIC_NUM/2-1:0] mode, mode_n;
    reg signed [BITWIDTH:0] X_reg   [0:CORDIC_NUM/2+1];
    reg signed [BITWIDTH:0] X_reg_n [0:CORDIC_NUM/2+1];
    reg signed [BITWIDTH:0] Y_reg   [0:CORDIC_NUM/2+1];
    reg signed [BITWIDTH:0] Y_reg_n [0:CORDIC_NUM/2+1];
    reg signed [BITWIDTH:0] X_tmp   [0:CORDIC_NUM/2];
    reg signed [BITWIDTH:0] Y_tmp   [0:CORDIC_NUM/2];

    wire signed [15+BITWIDTH-1:0] scaling_X, scaling_Y;

    integer i;

    assign scaling_X = $signed(X_reg[14]) * $signed(K);
    assign scaling_Y = $signed(Y_reg[14]) * $signed(K);
    assign X_o = X_reg[CORDIC_NUM/2+1];
    assign Y_o = Y_reg[CORDIC_NUM/2+1];

    always @(*) begin

        if(start_i) begin
            mode_n[0] = mode_i;
            X_reg_n[0] = X_i;
            Y_reg_n[0] = Y_i;
        end
        else begin
            mode_n[0] = ROTATE;
            X_reg_n[0] = 0;
            Y_reg_n[0] = 0;
        end

        for(i=0;i<CORDIC_NUM/2;i=i+1) begin
            case (mode[i])
                VECTOR: begin
                    if(X_reg[i][BITWIDTH] ^ Y_reg[i][BITWIDTH]) begin
                        X_tmp[i] = X_reg[i] - (Y_reg[i] >>> 2*i);
                        Y_tmp[i] = Y_reg[i] + (X_reg[i] >>> 2*i);
                    end
                    else begin
                        X_tmp[i] = X_reg[i] + (Y_reg[i] >>> 2*i);
                        Y_tmp[i] = Y_reg[i] - (X_reg[i] >>> 2*i);
                    end
                end
                ROTATE: begin
                    if(d_i[2*i]) begin
                        X_tmp[i] = X_reg[i] - (Y_reg[i] >>> 2*i);
                        Y_tmp[i] = Y_reg[i] + (X_reg[i] >>> 2*i);
                    end
                    else begin
                        X_tmp[i] = X_reg[i] + (Y_reg[i] >>> 2*i);
                        Y_tmp[i] = Y_reg[i] - (X_reg[i] >>> 2*i);
                    end
                end
            endcase
        end

        for(i=1;i<CORDIC_NUM/2+1;i=i+1) begin
            case (mode[i])
                VECTOR: begin
                    if(X_tmp[i-1][BITWIDTH] ^ Y_tmp[i-1][BITWIDTH]) begin
                        X_reg_n[i] = X_tmp[i-1] - (Y_tmp[i-1] >>> 2*i-1);
                        Y_reg_n[i] = Y_tmp[i-1] + (X_tmp[i-1] >>> 2*i-1);
                    end
                    else begin
                        X_reg_n[i] = X_tmp[i-1] + (Y_tmp[i-1] >>> 2*i-1);
                        Y_reg_n[i] = Y_tmp[i-1] - (X_tmp[i-1] >>> 2*i-1);
                    end
                end
                ROTATE: begin
                    if(d_i[2*i-1]) begin
                        X_reg_n[i] = X_tmp[i-1] - (Y_tmp[i-1] >>> 2*i-1);
                        Y_reg_n[i] = Y_tmp[i-1] + (X_tmp[i-1] >>> 2*i-1);
                    end
                    else begin
                        X_reg_n[i] = X_tmp[i-1] + (Y_tmp[i-1] >>> 2*i-1);
                        Y_reg_n[i] = Y_tmp[i-1] - (X_tmp[i-1] >>> 2*i-1);
                    end
                end
            endcase
        end
        for(i=1;i<CORDIC_NUM/2;i=i+1) begin
            mode_n[i] = mode[i-1];
        end
        X_reg_n[CORDIC_NUM/2+1] = {scaling_X[15+BITWIDTH-1], scaling_X[15+BITWIDTH-3:BITWIDTH-4]} + scaling_X[BITWIDTH-5];
        Y_reg_n[CORDIC_NUM/2+1] = {scaling_Y[15+BITWIDTH-1], scaling_Y[15+BITWIDTH-3:BITWIDTH-4]} + scaling_Y[BITWIDTH-5];
    end

    always @(*) begin
        for(i=0;i<CORDIC_NUM/2;i=i+1) begin
            case (mode[i])
                VECTOR: begin
                    if(X_reg[i][BITWIDTH] ^ Y_reg[i][BITWIDTH]) begin
                        d_o[i] = 1'b1;
                    end
                    else begin
                        d_o[i] = 1'b0;
                    end
                    if(X_tmp[i][BITWIDTH] ^ Y_tmp[i][BITWIDTH]) begin
                        d_o[i+1] = 1'b1;
                    end
                    else begin
                        d_o[i+1] = 1'b0;
                    end
                end
                ROTATE: begin
                    d_o[i] = 1'b0;
                    d_o[i+1] = 1'b0;
                end
            
                default : begin
                    d_o[i] = 1'b0;
                    d_o[i+1] = 1'b0;
                end
            endcase
        end
        
    end

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            for(i=0;i<CORDIC_NUM/2+1;i=i+1) begin
                X_reg[i] <= 0;
                Y_reg[i] <= 0;
            end
            for(i=0;i<CORDIC_NUM/2;i=i+1) begin
                mode[i]  <= 0;
            end
        end 
        else begin
            for(i=0;i<CORDIC_NUM/2+1;i=i+1) begin
                X_reg[i] <= X_reg_n[i];
                Y_reg[i] <= Y_reg_n[i];
            end
            for(i=0;i<CORDIC_NUM/2;i=i+1) begin
                mode[i]  <= mode_n[i];
            end
        end
    end

endmodule