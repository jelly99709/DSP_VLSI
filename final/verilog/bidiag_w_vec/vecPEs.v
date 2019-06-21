module vecPEs (
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
    PE1_Y1_o, 

    angle0_i, 
    angle1_i
);

    parameter BITWIDTH   = 18;
    parameter CORDIC_NUM = 14;
    localparam PIPE_NUM  = 4;

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

    output signed [BITWIDTH-1:0] PE0_X0_o;
    output signed [BITWIDTH-1:0] PE0_Y0_o;
    output signed [BITWIDTH-1:0] PE0_X1_o;
    output signed [BITWIDTH-1:0] PE0_Y1_o;
    output signed [BITWIDTH-1:0] PE1_X0_o;
    output signed [BITWIDTH-1:0] PE1_Y0_o;
    output signed [BITWIDTH-1:0] PE1_X1_o;
    output signed [BITWIDTH-1:0] PE1_Y1_o;

    input signed [CORDIC_NUM-1:0] angle0_i;
    input signed [CORDIC_NUM-1:0] angle1_i;

    wire [1:0] PE0_idle;
    wire [1:0] PE0_scheme;
    wire signed [BITWIDTH-1:0] PE0_X0_in;
    wire signed [BITWIDTH-1:0] PE0_Y0_in;
    wire signed [BITWIDTH-1:0] PE0_X1_in;
    wire signed [BITWIDTH-1:0] PE0_Y1_in;
    reg [CORDIC_NUM-1:0] PE0_angle_d0_in;
    reg [CORDIC_NUM-1:0] PE0_angle_d1_in;

    wire signed [BITWIDTH-1:0] PE0_X0_out;
    wire signed [BITWIDTH-1:0] PE0_Y0_out;
    wire signed [BITWIDTH-1:0] PE0_X1_out;
    wire signed [BITWIDTH-1:0] PE0_Y1_out;
    wire [CORDIC_NUM-1:0] PE0_angle_d0_out;
    wire [CORDIC_NUM-1:0] PE0_angle_d1_out;
    wire [PIPE_NUM-2:0] PE0_angle_val0_out;
    wire [PIPE_NUM-2:0] PE0_angle_val1_out;

    wire [1:0] PE1_idle;
    wire [1:0] PE1_scheme;
    wire signed [BITWIDTH-1:0] PE1_X0_in;
    wire signed [BITWIDTH-1:0] PE1_Y0_in;
    wire signed [BITWIDTH-1:0] PE1_X1_in;
    wire signed [BITWIDTH-1:0] PE1_Y1_in;
    reg [CORDIC_NUM-1:0] PE1_angle_d0_in;
    reg [CORDIC_NUM-1:0] PE1_angle_d1_in;

    wire signed [BITWIDTH-1:0] PE1_X0_out;
    wire signed [BITWIDTH-1:0] PE1_Y0_out;
    wire signed [BITWIDTH-1:0] PE1_X1_out;
    wire signed [BITWIDTH-1:0] PE1_Y1_out;
    wire [CORDIC_NUM-1:0] PE1_angle_d0_out;
    wire [CORDIC_NUM-1:0] PE1_angle_d1_out;
    wire [PIPE_NUM-2:0] PE1_angle_val0_out;
    wire [PIPE_NUM-2:0] PE1_angle_val1_out;

    reg [CORDIC_NUM-1:0] angle0_reg, angle0_reg_n;
    reg [CORDIC_NUM-1:0] angle1_reg, angle1_reg_n;

    integer i;

    assign angle0_o = PE1_angle_d0_in;
    assign angle1_o = PE0_angle_d1_in;

    assign PE0_X0_o = PE0_X0_out;
    assign PE0_Y0_o = PE0_Y0_out;
    assign PE0_X1_o = PE0_X1_out;
    assign PE0_Y1_o = PE0_Y1_out;

    assign PE1_X0_o = PE1_X0_out;
    assign PE1_Y0_o = PE1_Y0_out;
    assign PE1_X1_o = PE1_X1_out;
    assign PE1_Y1_o = PE1_Y1_out;
    

    assign PE0_idle   = ~PE0_valid_i;
    assign PE0_scheme = PE0_scheme_i;
    assign PE0_X0_in  = PE0_X0_i;
    assign PE0_Y0_in  = PE0_Y0_i;
    assign PE0_X1_in  = PE0_X1_i;
    assign PE0_Y1_in  = PE0_Y1_i;

    /*
    always @(*) begin
        PE0_angle_d0_in = angle0_reg;
        PE0_angle_d1_in = angle1_reg;
    end
    */


    always @(*) begin
        PE0_angle_d0_in = angle0_i;
        PE0_angle_d1_in = angle1_i;
    end



    assign PE1_idle   = ~PE1_valid_i;
    assign PE1_scheme = PE1_scheme_i;
    assign PE1_X0_in  = PE1_X0_i;
    assign PE1_Y0_in  = PE1_Y0_i;
    assign PE1_X1_in  = PE1_X1_i;
    assign PE1_Y1_in  = PE1_Y1_i;

    always @(*) begin
        PE1_angle_d0_in = angle0_i;
        PE1_angle_d1_in = angle1_i;
    end

    VEC_PE #(BITWIDTH,CORDIC_NUM) PE0(
        .clk(clk),
        .rst_n(rst_n),
        .idle(PE0_idle),
        .scheme(PE0_scheme), 

        .X0_i(PE0_X0_in),
        .Y0_i(PE0_Y0_in),
        .X1_i(PE0_X1_in),
        .Y1_i(PE0_Y1_in),
        .angle_d0_i(PE0_angle_d0_in),
        .angle_d1_i(PE0_angle_d1_in), 

        .X0_o(PE0_X0_out),
        .Y0_o(PE0_Y0_out),
        .X1_o(PE0_X1_out),
        .Y1_o(PE0_Y1_out),
        .angle_d0_o(PE0_angle_d0_out),
        .angle_d1_o(PE0_angle_d1_out),
        .angle_val0_o(PE0_angle_val0_out),
        .angle_val1_o(PE0_angle_val1_out)  

    );

    VEC_PE #(BITWIDTH,CORDIC_NUM) PE1(
        .clk(clk),
        .rst_n(rst_n),
        .idle(PE1_idle),
        .scheme(PE1_scheme), 

        .X0_i(PE1_X0_in),
        .Y0_i(PE1_Y0_in),
        .X1_i(PE1_X1_in),
        .Y1_i(PE1_Y1_in),
        .angle_d0_i(PE1_angle_d0_in),
        .angle_d1_i(PE1_angle_d1_in), 

        .X0_o(PE1_X0_out),
        .Y0_o(PE1_Y0_out),
        .X1_o(PE1_X1_out),
        .Y1_o(PE1_Y1_out),
        .angle_d0_o(PE1_angle_d0_out),
        .angle_d1_o(PE1_angle_d1_out),
        .angle_val0_o(PE1_angle_val0_out),
        .angle_val1_o(PE1_angle_val1_out)  

    );


    always @(*) begin
        for(i=0;i<4;i=i+1) begin
            if(PE0_angle_val0_out[0]) begin
                angle0_reg_n[i] = PE0_angle_d0_out[i];
            end
            else begin
                angle0_reg_n[i] = angle0_reg[i];
            end
            if(PE0_angle_val1_out[0]) begin
                angle1_reg_n[i] = PE0_angle_d1_out[i];
            end
            else begin
                angle1_reg_n[i] = angle1_reg[i];
            end
        end
        for(i=4;i<9;i=i+1) begin
            if(PE0_angle_val0_out[1]) begin
                angle0_reg_n[i] = PE0_angle_d0_out[i];
            end
            else begin
                angle0_reg_n[i] = angle0_reg[i];
            end
            if(PE0_angle_val1_out[1]) begin
                angle1_reg_n[i] = PE0_angle_d1_out[i];
            end
            else begin
                angle1_reg_n[i] = angle1_reg[i];
            end
        end
        for(i=9;i<14;i=i+1) begin
            if(PE0_angle_val0_out[2]) begin
                angle0_reg_n[i] = PE0_angle_d0_out[i];
            end
            else begin
                angle0_reg_n[i] = angle0_reg[i];
            end
            if(PE0_angle_val1_out[2]) begin
                angle1_reg_n[i] = PE0_angle_d1_out[i];
            end
            else begin
                angle1_reg_n[i] = angle1_reg[i];
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            angle0_reg <= 0;
            angle1_reg <= 0;
        end 
        else begin
            angle0_reg <= angle0_reg_n;
            angle1_reg <= angle1_reg_n;
        end
    end

endmodule

module VEC_PE(
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
    output [CORDIC_NUM-1:0] angle_d0_o, angle_d1_o;
    output [PIPE_NUM-2:0] angle_val0_o, angle_val1_o;

    //output out_valid;



    wire COR_start_0, COR_start_1;
    wire signed [BITWIDTH-1:0] COR_Xin_0, COR_Xin_1;
    wire signed [BITWIDTH-1:0] COR_Yin_0, COR_Yin_1;
    wire [CORDIC_NUM-1:0] COR_din_0, COR_din_1;
    wire signed [BITWIDTH-1:0] COR_Xout_0, COR_Xout_1;
    wire signed [BITWIDTH-1:0] COR_Yout_0, COR_Yout_1;
    wire [CORDIC_NUM-1:0] COR_dout_0, COR_dout_1;
    reg COR_mode_0, COR_mode_1;

    reg [PIPE_NUM-1:0] isswap, isswap_n;
    reg [PIPE_NUM-2:0] a0_val, a0_val_n;
    reg [PIPE_NUM-2:0] a1_val, a1_val_n;
    reg [CORDIC_NUM-1:0] same_dout;

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
    assign angle_d0_o = COR_dout_0;
    assign angle_d1_o = (COR_dout_1 & (~same_dout)) | (COR_dout_0 & (same_dout));
    assign angle_val0_o = {a0_val, COR_start_0 & (~COR_mode_0)};
    assign angle_val1_o = ({a1_val, COR_start_1 & (~COR_mode_1)} & ~{isswap[PIPE_NUM-3:0], isswap_n[0]}) | ({a0_val, COR_start_0 & (~COR_mode_0)} & {isswap[PIPE_NUM-3:0], isswap_n[0]}); 

    VEC_CORDIC_VR #(BITWIDTH,CORDIC_NUM) CORDIC0(
        .clk(clk),   
        .rst_n(rst_n),
        .start_i(COR_start_0),
        .mode_i(COR_mode_0),
        .X_i(COR_Xin_0),
        .Y_i(COR_Yin_0),
        .d_i(COR_din_0),
        .X_o(COR_Xout_0),
        .Y_o(COR_Yout_0),
        .d_o(COR_dout_0)
    );

    VEC_CORDIC_VR #(BITWIDTH,CORDIC_NUM) CORDIC1(
        .clk(clk),   
        .rst_n(rst_n),
        .start_i(COR_start_1),
        .mode_i(COR_mode_1),
        .X_i(COR_Xin_1),
        .Y_i(COR_Yin_1),
        .d_i(COR_din_1),
        .X_o(COR_Xout_1),
        .Y_o(COR_Yout_1),
        .d_o(COR_dout_1)
    );

    always @(*) begin
        for(i=0;i<4;i=i+1) begin
            same_dout[i] = isswap_n[0];
        end
        for(i=4;i<9;i=i+1) begin
            same_dout[i] = isswap[0];
        end
        for(i=9;i<14;i=i+1) begin
            same_dout[i] = isswap[1];
        end
    end

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

        a0_val_n[0] = COR_start_0 & (~COR_mode_0);
        a1_val_n[0] = COR_start_1 & (~COR_mode_1);

        for(i=1;i<PIPE_NUM-1;i=i+1) begin
            a0_val_n[i] = a0_val[i-1];
            a1_val_n[i] = a1_val[i-1];
        end    
    end

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            for(i=0;i<PIPE_NUM;i=i+1) begin
                isswap[i] <= 0;
            end
            for(i=0;i<PIPE_NUM-1;i=i+1) begin
                a0_val[i] = 0;
                a1_val[i] = 0;
            end
        end 
        else begin
            for(i=0;i<PIPE_NUM;i=i+1) begin
                isswap[i] <= isswap_n[i];
            end
            for(i=0;i<PIPE_NUM-1;i=i+1) begin
                a0_val[i] = a0_val_n[i];
                a1_val[i] = a1_val_n[i];
            end
        end
    end

    
endmodule // PE


module VEC_CORDIC_VR(
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
    localparam PIPE_NUM  = 4;

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
    reg [PIPE_NUM-3:0] mode, mode_n;
    reg signed [BITWIDTH:0] X_reg   [0:PIPE_NUM-1];
    reg signed [BITWIDTH:0] X_reg_n [0:PIPE_NUM-1];
    reg signed [BITWIDTH:0] Y_reg   [0:PIPE_NUM-1];
    reg signed [BITWIDTH:0] Y_reg_n [0:PIPE_NUM-1];
    reg signed [BITWIDTH:0] X_tmp   [0:CORDIC_NUM-PIPE_NUM];
    reg signed [BITWIDTH:0] Y_tmp   [0:CORDIC_NUM-PIPE_NUM];

    wire signed [15+BITWIDTH-1:0] scaling_X, scaling_Y;

    integer i;

    assign scaling_X = $signed(X_reg[PIPE_NUM-2]) * $signed(K);
    assign scaling_Y = $signed(Y_reg[PIPE_NUM-2]) * $signed(K);
    assign X_o = X_reg[PIPE_NUM-1][BITWIDTH-1:0];
    assign Y_o = Y_reg[PIPE_NUM-1][BITWIDTH-1:0];

    always @(*) begin

        if(start_i) begin
            mode_n[0] = mode_i;
        end
        else begin
            mode_n[0] = ROTATE;
        end

        case (mode_i)
            VECTOR: begin
                if(X_i[BITWIDTH-1] ^ Y_i[BITWIDTH-1]) begin
                    X_tmp[0] = X_i - Y_i;
                    Y_tmp[0] = Y_i + X_i;
                end
                else begin
                    X_tmp[0] = X_i + Y_i;
                    Y_tmp[0] = Y_i - X_i;
                end

                for(i=1;i<3;i=i+1) begin
                    if(X_tmp[i-1][BITWIDTH] ^ Y_tmp[i-1][BITWIDTH]) begin
                        X_tmp[i] = X_tmp[i-1] - (Y_tmp[i-1] >>> i);
                        Y_tmp[i] = Y_tmp[i-1] + (X_tmp[i-1] >>> i);
                    end
                    else begin
                        X_tmp[i] = X_tmp[i-1] + (Y_tmp[i-1] >>> i);
                        Y_tmp[i] = Y_tmp[i-1] - (X_tmp[i-1] >>> i);
                    end
                end

                if(X_tmp[2][BITWIDTH] ^ Y_tmp[2][BITWIDTH]) begin
                    X_reg_n[0] = X_tmp[2] - (Y_tmp[2] >>> 3);
                    Y_reg_n[0] = Y_tmp[2] + (X_tmp[2] >>> 3);
                end
                else begin
                    X_reg_n[0] = X_tmp[2] + (Y_tmp[2] >>> 3);
                    Y_reg_n[0] = Y_tmp[2] - (X_tmp[2] >>> 3);
                end
            end

            ROTATE: begin
                if(d_i[0]) begin
                    X_tmp[0] = X_i - Y_i;
                    Y_tmp[0] = Y_i + X_i;
                end
                else begin
                    X_tmp[0] = X_i + Y_i;
                    Y_tmp[0] = Y_i - X_i;
                end

                for(i=1;i<3;i=i+1) begin
                    if(d_i[i]) begin
                        X_tmp[i] = X_tmp[i-1] - (Y_tmp[i-1] >>> i);
                        Y_tmp[i] = Y_tmp[i-1] + (X_tmp[i-1] >>> i);
                    end
                    else begin
                        X_tmp[i] = X_tmp[i-1] + (Y_tmp[i-1] >>> i);
                        Y_tmp[i] = Y_tmp[i-1] - (X_tmp[i-1] >>> i);
                    end
                end

                if(d_i[3]) begin
                    X_reg_n[0] = X_tmp[2] - (Y_tmp[2] >>> 3);
                    Y_reg_n[0] = Y_tmp[2] + (X_tmp[2] >>> 3);
                end
                else begin
                    X_reg_n[0] = X_tmp[2] + (Y_tmp[2] >>> 3);
                    Y_reg_n[0] = Y_tmp[2] - (X_tmp[2] >>> 3);
                end
            end
        endcase


        case (mode[0])
            VECTOR: begin
                if(X_reg[0][BITWIDTH] ^ Y_reg[0][BITWIDTH]) begin
                    X_tmp[3] = X_reg[0] - (Y_reg[0] >>> 4);
                    Y_tmp[3] = Y_reg[0] + (X_reg[0] >>> 4);
                end
                else begin
                    X_tmp[3] = X_reg[0] + (Y_reg[0] >>> 4);
                    Y_tmp[3] = Y_reg[0] - (X_reg[0] >>> 4);
                end

                for(i=4;i<7;i=i+1) begin
                    if(X_tmp[i-1][BITWIDTH] ^ Y_tmp[i-1][BITWIDTH]) begin
                        X_tmp[i] = X_tmp[i-1] - (Y_tmp[i-1] >>> i+1);
                        Y_tmp[i] = Y_tmp[i-1] + (X_tmp[i-1] >>> i+1);
                    end
                    else begin
                        X_tmp[i] = X_tmp[i-1] + (Y_tmp[i-1] >>> i+1);
                        Y_tmp[i] = Y_tmp[i-1] - (X_tmp[i-1] >>> i+1);
                    end
                end

                if(X_tmp[6][BITWIDTH] ^ Y_tmp[6][BITWIDTH]) begin
                    X_reg_n[1] = X_tmp[6] - (Y_tmp[6] >>> 8);
                    Y_reg_n[1] = Y_tmp[6] + (X_tmp[6] >>> 8);
                end
                else begin
                    X_reg_n[1] = X_tmp[6] + (Y_tmp[6] >>> 8);
                    Y_reg_n[1] = Y_tmp[6] - (X_tmp[6] >>> 8);
                end
            end

            ROTATE: begin
                if(d_i[4]) begin
                    X_tmp[3] = X_reg[0] - (Y_reg[0] >>> 4);
                    Y_tmp[3] = Y_reg[0] + (X_reg[0] >>> 4);
                end
                else begin
                    X_tmp[3] = X_reg[0] + (Y_reg[0] >>> 4);
                    Y_tmp[3] = Y_reg[0] - (X_reg[0] >>> 4);
                end

                for(i=4;i<7;i=i+1) begin
                    if(d_i[i+1]) begin
                        X_tmp[i] = X_tmp[i-1] - (Y_tmp[i-1] >>> i+1);
                        Y_tmp[i] = Y_tmp[i-1] + (X_tmp[i-1] >>> i+1);
                    end
                    else begin
                        X_tmp[i] = X_tmp[i-1] + (Y_tmp[i-1] >>> i+1);
                        Y_tmp[i] = Y_tmp[i-1] - (X_tmp[i-1] >>> i+1);
                    end
                end

                if(d_i[8]) begin
                    X_reg_n[1] = X_tmp[6] - (Y_tmp[6] >>> 8);
                    Y_reg_n[1] = Y_tmp[6] + (X_tmp[6] >>> 8);
                end
                else begin
                    X_reg_n[1] = X_tmp[6] + (Y_tmp[6] >>> 8);
                    Y_reg_n[1] = Y_tmp[6] - (X_tmp[6] >>> 8);
                end
            end
        endcase

        case (mode[1])
            VECTOR: begin
                if(X_reg[1][BITWIDTH] ^ Y_reg[1][BITWIDTH]) begin
                    X_tmp[7] = X_reg[1] - (Y_reg[1] >>> 9);
                    Y_tmp[7] = Y_reg[1] + (X_reg[1] >>> 9);
                end
                else begin
                    X_tmp[7] = X_reg[1] + (Y_reg[1] >>> 9);
                    Y_tmp[7] = Y_reg[1] - (X_reg[1] >>> 9);
                end

                for(i=8;i<11;i=i+1) begin
                    if(X_tmp[i-1][BITWIDTH] ^ Y_tmp[i-1][BITWIDTH]) begin
                        X_tmp[i] = X_tmp[i-1] - (Y_tmp[i-1] >>> i+2);
                        Y_tmp[i] = Y_tmp[i-1] + (X_tmp[i-1] >>> i+2);
                    end
                    else begin
                        X_tmp[i] = X_tmp[i-1] + (Y_tmp[i-1] >>> i+2);
                        Y_tmp[i] = Y_tmp[i-1] - (X_tmp[i-1] >>> i+2);
                    end
                end

                if(X_tmp[10][BITWIDTH] ^ Y_tmp[10][BITWIDTH]) begin
                    X_reg_n[2] = X_tmp[10] - (Y_tmp[10] >>> 13);
                    Y_reg_n[2] = Y_tmp[10] + (X_tmp[10] >>> 13);
                end
                else begin
                    X_reg_n[2] = X_tmp[10] + (Y_tmp[10] >>> 13);
                    Y_reg_n[2] = Y_tmp[10] - (X_tmp[10] >>> 13);
                end
            end
            ROTATE: begin
                if(d_i[9]) begin
                    X_tmp[7] = X_reg[1] - (Y_reg[1] >>> 9);
                    Y_tmp[7] = Y_reg[1] + (X_reg[1] >>> 9);
                end
                else begin
                    X_tmp[7] = X_reg[1] + (Y_reg[1] >>> 9);
                    Y_tmp[7] = Y_reg[1] - (X_reg[1] >>> 9);
                end

                for(i=8;i<11;i=i+1) begin
                    if(d_i[i+2]) begin
                        X_tmp[i] = X_tmp[i-1] - (Y_tmp[i-1] >>> i+2);
                        Y_tmp[i] = Y_tmp[i-1] + (X_tmp[i-1] >>> i+2);
                    end
                    else begin
                        X_tmp[i] = X_tmp[i-1] + (Y_tmp[i-1] >>> i+2);
                        Y_tmp[i] = Y_tmp[i-1] - (X_tmp[i-1] >>> i+2);
                    end
                end

                if(d_i[13]) begin
                    X_reg_n[2] = X_tmp[10] - (Y_tmp[10] >>> 13);
                    Y_reg_n[2] = Y_tmp[10] + (X_tmp[10] >>> 13);
                end
                else begin
                    X_reg_n[2] = X_tmp[10] + (Y_tmp[10] >>> 13);
                    Y_reg_n[2] = Y_tmp[10] - (X_tmp[10] >>> 13);
                end
            end
        endcase

        for(i=1;i<PIPE_NUM-2;i=i+1) begin
            mode_n[i] = mode[i-1];
        end

        X_reg_n[PIPE_NUM-1] = {1'b0,{scaling_X[15+BITWIDTH-1], scaling_X[15+BITWIDTH-3:BITWIDTH-4]}};//+ scaling_X[BITWIDTH-5]};
        Y_reg_n[PIPE_NUM-1] = {1'b0,{scaling_Y[15+BITWIDTH-1], scaling_Y[15+BITWIDTH-3:BITWIDTH-4]}};//+ scaling_Y[BITWIDTH-5]};
    end

    always @(*) begin

        case (mode_i)
            VECTOR: begin
                if(X_i[BITWIDTH-1] ^ Y_i[BITWIDTH-1]) begin
                    d_o[0] = 1'b1;
                end
                else begin
                    d_o[0] = 1'b0;
                end
                for(i=1;i<4;i=i+1) begin
                    if(X_tmp[i-1][BITWIDTH] ^ Y_tmp[i-1][BITWIDTH]) begin
                        d_o[i] = 1'b1;
                    end
                    else begin
                        d_o[i] = 1'b0;
                    end
                end
            end
            ROTATE: begin
                for(i=0;i<4;i=i+1) begin
                    d_o[i] = 1'b0;
                end
            end
        endcase

        case(mode[0])
            VECTOR: begin
                if(X_reg[0][BITWIDTH] ^ Y_reg[0][BITWIDTH]) begin
                    d_o[4] = 1'b1;
                end
                else begin
                    d_o[4] = 1'b0;
                end
                for(i=5;i<9;i=i+1) begin
                    if(X_tmp[i-2][BITWIDTH] ^ Y_tmp[i-2][BITWIDTH]) begin
                        d_o[i] = 1'b1;
                    end
                    else begin
                        d_o[i] = 1'b0;
                    end
                end
            end

            ROTATE: begin
                for(i=4;i<9;i=i+1) begin
                    d_o[i] = 1'b0;
                end
            end
        endcase

        case(mode[1])
            VECTOR: begin
                if(X_reg[1][BITWIDTH] ^ Y_reg[1][BITWIDTH]) begin
                    d_o[9] = 1'b1;
                end
                else begin
                    d_o[9] = 1'b0;
                end
                for(i=10;i<14;i=i+1) begin
                    if(X_tmp[i-3][BITWIDTH] ^ Y_tmp[i-3][BITWIDTH]) begin
                        d_o[i] = 1'b1;
                    end
                    else begin
                        d_o[i] = 1'b0;
                    end
                end
            end

            ROTATE: begin
                for(i=9;i<14;i=i+1) begin
                    d_o[i] = 1'b0;
                end
            end
        endcase
        
    end

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            for(i=0;i<PIPE_NUM;i=i+1) begin
                X_reg[i] <= 0;
                Y_reg[i] <= 0;
            end
            for(i=0;i<PIPE_NUM-2;i=i+1) begin
                mode[i]  <= 6'b111111;
            end
        end 
        else begin
            for(i=0;i<PIPE_NUM;i=i+1) begin
                X_reg[i] <= X_reg_n[i];
                Y_reg[i] <= Y_reg_n[i];
            end
            for(i=0;i<PIPE_NUM-2;i=i+1) begin
                mode[i]  <= mode_n[i];
            end
        end
    end

endmodule