/*
module PE(
    clk,
    rst_n,
    scheme,

    X1_i,
    Y1_i,
    X2_i,
    Y2_i,
    angle_d1_i,
    angle_d2_i,
    angle_val_i, 

    X1_o,
    Y1_o,
    X2_o,
    Y2_o,
    angle_d1_o,
    angle_d2_o,
    angle_val_o, 

    out_valid

);

    input clk;
    input rst_n;
    input [1:0] scheme;

    input signed [16:0] X1_i;
    input signed [16:0] Y1_i;
    input signed [16:0] X2_i;
    input signed [16:0] Y2_i;
    input angle_d1_i;
    input angle_d2_i;
    input angle_val_i; 

    output signed [16:0] X1_o;
    output signed [16:0] Y1_o;
    output signed [16:0] X2_o;
    output signed [16:0] Y2_o;
    output angle_d1_o;
    output angle_d2_o;
    output angle_val_o; 

    output out_valid;

    localparam SCHEME0 = 2'b00;
    localparam SCHEME1 = 2'b01;
    localparam SCHEME2 = 2'b10;
    localparam SCHEME3 = 2'b11;

    localparam IDLE = 2'b00;
    localparam WORK = 2'b01;


    reg [1:0] state, state_n;
    reg [1:0] mode, mode_n;

    wire COR_start_0, COR_start_1;
    wire COR_mode_0, COR_mode_1;

    CORDIC_VR #(17,14) CORDIC0(
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
        .finish_o(COR_fin_0),
    );

    CORDIC_VR #(17,14) CORDIC1(
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
        .finish_o(COR_fin_1),
    );

    
endmodule // PE
*/

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
    finish_o,
);
    
    parameter BITWIDTH   = 18;
    parameter CORDIC_NUM = 14;

    localparam VECTOR = 1'b0;
    localparam ROTATE = 1'b1;

    localparam WAIT      = 2'b00;
    localparam CALCULATE = 2'b01;
    localparam SCALING   = 2'b10;
    localparam FINISH    = 2'b11;

    localparam K = 15'b010011011011101;

    input clk;
    input rst_n;

    input start_i;
    input mode_i;
    input signed [BITWIDTH-1:0] X_i; 
    input signed [BITWIDTH-1:0] Y_i;
    input d_i; 
    
    output reg signed [BITWIDTH-1:0] X_o; 
    output reg signed [BITWIDTH-1:0] Y_o;
    output reg d_o;
    output reg finish_o;

    // Register
    reg [1:0] state, state_n;
    reg mode, mode_n;
    reg [3:0] counter, counter_n;
    reg signed [BITWIDTH-1:0] X_reg, X_reg_n;
    reg signed [BITWIDTH-1:0] Y_reg, Y_reg_n;

    wire signed [15+BITWIDTH-1:0] scaling_X, scaling_Y;

    assign scaling_X = $signed(X_reg) * $signed(K);
    assign scaling_Y = $signed(Y_reg) * $signed(K);
    assign check = X_reg[17] ^ Y_reg[17];


    always @(*) begin
        case (state)
            WAIT: begin
                if(start_i) begin
                    state_n = CALCULATE;
                end
                else begin
                    state_n = state;
                end
            end

            CALCULATE: begin
                if(counter == CORDIC_NUM-1) begin
                    state_n = SCALING;
                end
                else begin
                    state_n = state;
                end
            end

           SCALING: begin
                state_n = FINISH;
            end

            FINISH: begin
                if(start_i) begin
                    state_n = CALCULATE;
                end
                else begin
                    state_n = WAIT;
                end
            end
        endcase
    
    end

    always @(*) begin

        case(state)
            WAIT: begin
                if(start_i) begin
                    mode_n = mode_i;
                    X_reg_n = X_i;
                    Y_reg_n = Y_i;
                end
                else begin
                    mode_n = mode;
                    X_reg_n = X_reg;
                    Y_reg_n = Y_reg;
                end
                counter_n = 0;
            end

            CALCULATE: begin
                case (mode)
                    VECTOR: begin
                        if(X_reg[BITWIDTH-1] ^ Y_reg[BITWIDTH-1]) begin
                            X_reg_n = X_reg - (Y_reg >>> counter);
                            Y_reg_n = Y_reg + (X_reg >>> counter);
                        end
                        else begin
                        	X_reg_n = X_reg + (Y_reg >>> counter);
                            Y_reg_n = Y_reg - (X_reg >>> counter);
                        end
                    end
                    ROTATE: begin
                        if(d_i) begin
                            X_reg_n = X_reg - (Y_reg >>> counter);
                            Y_reg_n = Y_reg + (X_reg >>> counter);
                        end
                        else begin
                            X_reg_n = X_reg + (Y_reg >>> counter);
                            Y_reg_n = Y_reg - (X_reg >>> counter);
                        end
                    end
                endcase // mode

                mode_n = mode;
                counter_n = counter + 1;
            end

            SCALING: begin
                X_reg_n = scaling_X[BITWIDTH-5] ? {scaling_X[15+BITWIDTH-1], scaling_X[15+BITWIDTH-3:BITWIDTH-4]} + 1 : {scaling_X[15+BITWIDTH-1], scaling_X[15+BITWIDTH-3:BITWIDTH-4]};
                Y_reg_n = scaling_Y[BITWIDTH-5] ? {scaling_Y[15+BITWIDTH-1], scaling_Y[15+BITWIDTH-3:BITWIDTH-4]} + 1 : {scaling_Y[15+BITWIDTH-1], scaling_Y[15+BITWIDTH-3:BITWIDTH-4]};
                mode_n = mode;
                counter_n = 0;
            end

            FINISH: begin
            	if(start_i) begin
                    mode_n = mode_i;
                    X_reg_n = X_i;
                    Y_reg_n = Y_i;
                    counter_n = 0;
                end
                else begin
                	mode_n = mode;
                	X_reg_n = X_reg;
                	Y_reg_n = Y_reg;
                	counter_n = counter;
                end
            end

            default : begin
                mode_n = mode;
                X_reg_n = X_reg;
                Y_reg_n = Y_reg;
                counter_n = counter;
            end
        endcase // state
    end

    always @(*) begin
        case(state)
            WAIT: begin
                d_o = 1'b0;
                finish_o = 1'b0;
                X_o = X_reg;
                Y_o = Y_reg;
            end

            CALCULATE: begin
                case (mode)
                    VECTOR: begin
                        if(X_reg[BITWIDTH-1] ^ Y_reg[BITWIDTH-1]) begin
                            d_o = 1'b1;
                        end
                        else begin
                            d_o = 1'b0;
                        end
                        finish_o = 1'b0;
                        X_o = X_reg;
                        Y_o = Y_reg;
                    end
                    ROTATE: begin
                        d_o = 1'b0;
                        finish_o = 1'b0;
                        X_o = X_reg;
                        Y_o = Y_reg;
                    end
                endcase // mode
            end

            SCALING: begin
                d_o = 1'b0;
                finish_o = 1'b0;
                X_o = X_reg;
                Y_o = Y_reg;
            end

            FINISH: begin
                d_o = 1'b0;
                finish_o = 1'b1;
                X_o = X_reg;
                Y_o = Y_reg;
            end
            default : begin
                d_o = 1'b0;
                finish_o = 1'b0;
                X_o = X_reg;
                Y_o = Y_reg;
            end
        endcase // state
    end

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            state   <= 2'd0;
            mode    <= 1'd0;
            X_reg   <= 17'd0;
            Y_reg   <= 17'd0;
            counter <= 4'd0;
        end 
        else begin
            state   <= state_n;
            mode    <= mode_n;
            X_reg   <= X_reg_n;
            Y_reg   <= Y_reg_n;
            counter <= counter_n;
        end
    end

endmodule