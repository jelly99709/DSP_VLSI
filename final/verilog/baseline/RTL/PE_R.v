module PE_R(
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


    //out_valid

);

    parameter BITWIDTH   = 18;
    parameter CORDIC_NUM = 14;
    localparam PIPE_NUM  = 4;

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
    input [CORDIC_NUM-1:0] angle_d0_i, angle_d1_i;

    output signed [BITWIDTH-1:0] X0_o;
    output signed [BITWIDTH-1:0] Y0_o;
    output signed [BITWIDTH-1:0] X1_o;
    output signed [BITWIDTH-1:0] Y1_o;


    //output out_valid;



    wire COR_start_0, COR_start_1;
    wire signed [BITWIDTH-1:0] COR_Xin_0, COR_Xin_1;
    wire signed [BITWIDTH-1:0] COR_Yin_0, COR_Yin_1;
    wire [CORDIC_NUM-1:0] COR_din_0, COR_din_1;
    wire signed [BITWIDTH-1:0] COR_Xout_0, COR_Xout_1;
    wire signed [BITWIDTH-1:0] COR_Yout_0, COR_Yout_1;
    reg COR_mode_0, COR_mode_1;

    reg [PIPE_NUM-1:0] isswap, isswap_n;

    integer i;

    assign {COR_start_1, COR_start_0} = (~idle);
    assign COR_Xin_0 = X0_i;
    assign COR_Yin_0 = (isswap_n[0])? X1_i : Y0_i;
    assign COR_Xin_1 = (isswap_n[0])? Y0_i : X1_i;
    assign COR_Yin_1 = Y1_i;
    assign COR_din_0 = angle_d0_i;
    assign COR_din_1 = angle_d1_i;


    assign X0_o = COR_Xout_0;
    assign Y0_o = (isswap[PIPE_NUM-1])?  COR_Xout_1 : COR_Yout_0;
    assign X1_o = (isswap[PIPE_NUM-1])?  COR_Yout_0 : COR_Xout_1;
    assign Y1_o = COR_Yout_1;

    CORDIC_R #(BITWIDTH,CORDIC_NUM) CORDIC0(
        .clk(clk),   
        .rst_n(rst_n),
        .start_i(COR_start_0),
        .X_i(COR_Xin_0),
        .Y_i(COR_Yin_0),
        .d_i(COR_din_0),
        .X_o(COR_Xout_0),
        .Y_o(COR_Yout_0)
    );

    CORDIC_R #(BITWIDTH,CORDIC_NUM) CORDIC1(
        .clk(clk),   
        .rst_n(rst_n),
        .start_i(COR_start_1),
        .X_i(COR_Xin_1),
        .Y_i(COR_Yin_1),
        .d_i(COR_din_1),
        .X_o(COR_Xout_1),
        .Y_o(COR_Yout_1)
    );



    always @(*) begin
        case(scheme)
            SCHEME0: begin
                isswap_n[0] = 0;
                COR_mode_0 = 0;
                COR_mode_1 = 0;
            end
            SCHEME1: begin
                isswap_n[0] = 0;
                COR_mode_0 = 1;
                COR_mode_1 = 1;
            end
            SCHEME2: begin
                isswap_n[0] = 1;
                COR_mode_0 = 0;
                COR_mode_1 = 1;
            end
            SCHEME3: begin
                isswap_n[0] = 1;
                COR_mode_0 = 1;
                COR_mode_1 = 1;
            end
        endcase

        for(i=1;i<PIPE_NUM;i=i+1) begin
            isswap_n[i] = isswap[i-1];
        end
 
    end

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            for(i=0;i<PIPE_NUM;i=i+1) begin
                isswap[i] <= 0;
            end
        end 
        else begin
            for(i=0;i<PIPE_NUM;i=i+1) begin
                isswap[i] <= isswap_n[i];
            end
        end
    end

    
endmodule // PE


module CORDIC_R(
    // Input
    clk,   
    rst_n,
    start_i,
    X_i,
    Y_i,
    d_i,
    // Output
    X_o,
    Y_o,
);
    
    parameter BITWIDTH   = 18;
    parameter CORDIC_NUM = 14;
    localparam PIPE_NUM  = 4;

    localparam VECTOR = 1'b0;
    localparam ROTATE = 1'b1;

    localparam K = 15'b010011011011101;

    input clk;
    input rst_n;

    input start_i;
    input signed [BITWIDTH-1:0] X_i; 
    input signed [BITWIDTH-1:0] Y_i;
    input wire [CORDIC_NUM-1:0] d_i; 
    
    output signed [BITWIDTH-1:0] X_o; 
    output signed [BITWIDTH-1:0] Y_o;

    // Register
    reg signed [BITWIDTH:0] X_reg   [0:PIPE_NUM-1];
    reg signed [BITWIDTH:0] X_reg_n [0:PIPE_NUM-1];
    reg signed [BITWIDTH:0] Y_reg   [0:PIPE_NUM-1];
    reg signed [BITWIDTH:0] Y_reg_n [0:PIPE_NUM-1];
    reg signed [BITWIDTH:0] X_tmp   [0:CORDIC_NUM-PIPE_NUM];
    reg signed [BITWIDTH:0] Y_tmp   [0:CORDIC_NUM-PIPE_NUM];
    reg signed [BITWIDTH:0] X_mid   [0:CORDIC_NUM-1];
    reg signed [BITWIDTH:0] Y_mid   [0:CORDIC_NUM-1];

    wire signed [15+BITWIDTH-1:0] scaling_X, scaling_Y;

    integer i;

    assign scaling_X = $signed(X_reg[PIPE_NUM-2]) * $signed(K);
    assign scaling_Y = $signed(Y_reg[PIPE_NUM-2]) * $signed(K);
    assign X_o = X_reg[PIPE_NUM-1][BITWIDTH-1:0];
    assign Y_o = Y_reg[PIPE_NUM-1][BITWIDTH-1:0];

    always @(*) begin


        if(d_i[0]) begin
            X_mid[0] =  {X_i[BITWIDTH-1], X_i};
            Y_mid[0] = ~{Y_i[BITWIDTH-1], Y_i} + 19'sd1;
        end
        else begin
            X_mid[0] = ~{X_i[BITWIDTH-1], X_i} + 19'sd1;
            Y_mid[0] =  {Y_i[BITWIDTH-1], Y_i};
        end

        X_tmp[0] = {X_i[BITWIDTH-1], X_i} + Y_mid[0];
        Y_tmp[0] = {Y_i[BITWIDTH-1], Y_i} + X_mid[0];

        for(i=1;i<3;i=i+1) begin
            if(d_i[i]) begin
                X_mid[i] =  (X_tmp[i-1] >>> i);
                Y_mid[i] = ~(Y_tmp[i-1] >>> i) + 19'sd1;
            end
            else begin
                X_mid[i] = ~(X_tmp[i-1] >>> i) + 19'sd1;
                Y_mid[i] =  (Y_tmp[i-1] >>> i);
            end
            X_tmp[i] = X_tmp[i-1] + (Y_mid[i]);
            Y_tmp[i] = Y_tmp[i-1] + (X_mid[i]);
        end


        if(d_i[3]) begin
            X_mid[3] =  (X_tmp[2] >>> 3);
            Y_mid[3] = ~(Y_tmp[2] >>> 3) + 19'sd1;
        end
        else begin
            X_mid[3] = ~(X_tmp[2] >>> 3) + 19'sd1;
            Y_mid[3] =  (Y_tmp[2] >>> 3);
        end

        X_reg_n[0] = X_tmp[2] + (Y_mid[3]);
        Y_reg_n[0] = Y_tmp[2] + (X_mid[3]);


        if(d_i[4]) begin
            X_mid[4] =  (X_reg[0] >>> 4);
            Y_mid[4] = ~(Y_reg[0] >>> 4) + 19'sd1;
        end
        else begin
            X_mid[4] = ~(X_reg[0] >>> 4) + 19'sd1;
            Y_mid[4] =  (Y_reg[0] >>> 4);
        end

        X_tmp[3] = X_reg[0] + (Y_mid[4]);
        Y_tmp[3] = Y_reg[0] + (X_mid[4]);

        for(i=4;i<7;i=i+1) begin
            if(d_i[i+1]) begin
                X_mid[i+1] = (X_tmp[i-1] >>> i+1);
                Y_mid[i+1] = ~(Y_tmp[i-1] >>> i+1) + 19'sd1;
            end
            else begin
                X_mid[i+1] = ~(X_tmp[i-1] >>> i+1) + 19'sd1;
                Y_mid[i+1] = (Y_tmp[i-1] >>> i+1);
            end
            X_tmp[i] = X_tmp[i-1] + (Y_mid[i+1]);
            Y_tmp[i] = Y_tmp[i-1] + (X_mid[i+1]);
        end

        if(d_i[8]) begin
            X_mid[8] =  (X_tmp[6] >>> 8);
            Y_mid[8] = ~(Y_tmp[6] >>> 8) + 19'sd1;
        end
        else begin
            X_mid[8] = ~(X_tmp[6] >>> 8) + 19'sd1;
            Y_mid[8] =  (Y_tmp[6] >>> 8);
        end

        X_reg_n[1] = X_tmp[6] + (Y_mid[8]);
        Y_reg_n[1] = Y_tmp[6] + (X_mid[8]);

        if(d_i[9]) begin
            X_mid[9] =  (X_reg[1] >>> 9);
            Y_mid[9] = ~(Y_reg[1] >>> 9) + 19'sd1;
        end
        else begin
            X_mid[9] = ~(X_reg[1] >>> 9) + 19'sd1;
            Y_mid[9] =  (Y_reg[1] >>> 9);
        end

        X_tmp[7] = X_reg[1] + (Y_mid[9]);
        Y_tmp[7] = Y_reg[1] + (X_mid[9]);

        for(i=8;i<11;i=i+1) begin
            if(d_i[i+2]) begin
                X_mid[i+2] =  (X_tmp[i-1] >>> i+2);
                Y_mid[i+2] = ~(Y_tmp[i-1] >>> i+2) + 19'sd1;
            end
            else begin
                X_mid[i+2] = ~(X_tmp[i-1] >>> i+2) + 19'sd1;
                Y_mid[i+2] =  (Y_tmp[i-1] >>> i+2);
            end
            X_tmp[i] = X_tmp[i-1] + (Y_mid[i+2]);
            Y_tmp[i] = Y_tmp[i-1] + (X_mid[i+2]);
        end

        if(d_i[13]) begin
            X_mid[13] =  (X_tmp[10] >>> 13);
            Y_mid[13] = ~(Y_tmp[10] >>> 13) + 19'sd1;
        end
        else begin
            X_mid[13] = ~(X_tmp[10] >>> 13) + 19'sd1;
            Y_mid[13] =  (Y_tmp[10] >>> 13);
        end

        X_reg_n[2] = X_tmp[10] + (Y_mid[13]);
        Y_reg_n[2] = Y_tmp[10] + (X_mid[13]);



        X_reg_n[PIPE_NUM-1] = {1'b0,{scaling_X[15+BITWIDTH-1], scaling_X[15+BITWIDTH-3:BITWIDTH-4]}};//+ scaling_X[BITWIDTH-5]};
        Y_reg_n[PIPE_NUM-1] = {1'b0,{scaling_Y[15+BITWIDTH-1], scaling_Y[15+BITWIDTH-3:BITWIDTH-4]}};//+ scaling_Y[BITWIDTH-5]};
    end



    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            for(i=0;i<PIPE_NUM;i=i+1) begin
                X_reg[i] <= 0;
                Y_reg[i] <= 0;
            end
        end 
        else begin
            for(i=0;i<PIPE_NUM;i=i+1) begin
                X_reg[i] <= X_reg_n[i];
                Y_reg[i] <= Y_reg_n[i];
            end
        end
    end

endmodule