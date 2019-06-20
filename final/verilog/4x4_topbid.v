//`include "./PEs.v"

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
    reg signed [BIT_NUM-1:0] dataR   [0:CHANNEL_SIZE-1];
    reg signed [BIT_NUM-1:0] dataR_n [0:CHANNEL_SIZE-1];
    reg signed [BIT_NUM-1:0] dataI   [0:CHANNEL_SIZE-1];
    reg signed [BIT_NUM-1:0] dataI_n [0:CHANNEL_SIZE-1];
    reg [$clog2(CHANNEL_SIZE)-1:0] cnt, cnt_n;
    reg valid_o_n;

    //state definition
    reg [2:0] STATE, STATE_N;
    reg [6:0] PHASE, PHASE_N;
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
    localparam BIDEND = 7'd66;
    always@(*) begin
        
        case(STATE)
            IDLE:    STATE_N = valid_i ? RECIEVE : IDLE;
            RECIEVE: STATE_N = ~valid_i ? BIDIAG : RECIEVE;
            BIDIAG:  STATE_N = (PHASE == BIDEND) ? SEND : BIDIAG;
            SEND:    STATE_N = (cnt == CHANNEL_SIZE) ? DONE : SEND;
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
                valid_o_n = PHASE == BIDEND ? 1 : 0;
                case(PHASE)
                    7'd0: begin
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
                    7'd1: begin
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
                    7'd2: begin
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
                    7'd3: begin
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
                    7'd4: begin
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
                    7'd5: begin 
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
                    7'd6: begin
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
                    7'd7: begin
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
                    7'd8: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        dataR_n[{2'd0,2'd0}] = pe0_x0_o;
                        dataI_n[{2'd0,2'd0}] = pe0_y0_o;
                        dataR_n[{2'd1,2'd0}] = pe0_x1_o;
                        dataI_n[{2'd1,2'd0}] = pe0_y1_o;
                        dataR_n[{2'd0,2'd1}] = pe1_x0_o;
                        dataI_n[{2'd0,2'd1}] = pe1_y0_o;
                        dataR_n[{2'd1,2'd1}] = pe1_x1_o;
                        dataI_n[{2'd1,2'd1}] = pe1_y1_o;
                    end
                    7'd9: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        dataR_n[{2'd0,2'd2}] = pe0_x0_o;
                        dataI_n[{2'd0,2'd2}] = pe0_y0_o;
                        dataR_n[{2'd1,2'd2}] = pe0_x1_o;
                        dataI_n[{2'd1,2'd2}] = pe0_y1_o;
                        dataR_n[{2'd0,2'd3}] = pe1_x0_o;
                        dataI_n[{2'd0,2'd3}] = pe1_y0_o;
                        dataR_n[{2'd1,2'd3}] = pe1_x1_o;
                        dataI_n[{2'd1,2'd3}] = pe1_y1_o;
                    end
                    7'd10: begin
                        pe0_valid = 2'b11;
                        pe1_valid = 2'b11;
                        pe0_scheme = REAL_NULLIFIED;
                        pe1_scheme = RELATED_ROTATE;
                        dataR_n[{2'd2,2'd0}] = pe0_x1_o;
                        dataI_n[{2'd2,2'd0}] = pe0_y1_o;
                        dataR_n[{2'd3,2'd0}] = pe0_x0_o;
                        dataI_n[{2'd3,2'd0}] = pe0_y0_o;
                        dataR_n[{2'd2,2'd1}] = pe1_x1_o;
                        dataI_n[{2'd2,2'd1}] = pe1_y1_o;
                        dataR_n[{2'd3,2'd1}] = pe1_x0_o;
                        dataI_n[{2'd3,2'd1}] = pe1_y0_o;
                        pe0_x0_i = dataR[{2'd0,2'd0}];
                        pe0_y0_i = dataI[{2'd0,2'd0}];
                        pe0_x1_i = pe0_x0_o;
                        pe0_y1_i = pe0_y0_o;
                        pe1_x0_i = dataR[{2'd0,2'd1}];
                        pe1_y0_i = dataI[{2'd0,2'd1}];
                        pe1_x1_i = pe1_x0_o;
                        pe1_y1_i = pe1_y0_o;
                    end
                    7'd11: begin
                        pe0_valid = 2'b11;
                        pe1_valid = 2'b11;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                        dataR_n[{2'd2,2'd2}] = pe0_x1_o;
                        dataI_n[{2'd2,2'd2}] = pe0_y1_o;
                        dataR_n[{2'd3,2'd2}] = pe0_x0_o;
                        dataI_n[{2'd3,2'd2}] = pe0_y0_o;
                        dataR_n[{2'd2,2'd3}] = pe1_x1_o;
                        dataI_n[{2'd2,2'd3}] = pe1_y1_o;
                        dataR_n[{2'd3,2'd3}] = pe1_x0_o;
                        dataI_n[{2'd3,2'd3}] = pe1_y0_o;
                        pe0_x0_i = dataR[{2'd0,2'd2}];
                        pe0_y0_i = dataI[{2'd0,2'd2}];
                        pe0_x1_i = pe0_x0_o;
                        pe0_y1_i = pe0_y0_o;
                        pe1_x0_i = dataR[{2'd0,2'd3}];
                        pe1_y0_i = dataI[{2'd0,2'd3}];
                        pe1_x1_i = pe1_x0_o;
                        pe1_y1_i = pe1_y0_o;
                    end
                    7'd12: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                    end
                    7'd13: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                    end
                    7'd14: begin
                        pe0_valid = 2'b11;
                        pe1_valid = 2'b11;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                        dataR_n[{2'd0,2'd0}] = pe0_x0_o;
                        dataI_n[{2'd0,2'd0}] = pe0_y0_o;
                        dataR_n[{2'd3,2'd0}] = pe0_x1_o;
                        dataI_n[{2'd3,2'd0}] = pe0_y1_o;
                        dataR_n[{2'd0,2'd1}] = pe1_x0_o;
                        dataI_n[{2'd0,2'd1}] = pe1_y0_o;
                        dataR_n[{2'd3,2'd1}] = pe1_x1_o;
                        dataI_n[{2'd3,2'd1}] = pe1_y1_o;
                    end
                    7'd15: begin
                        pe0_valid = 2'b11;
                        pe1_valid = 2'b11;
                        pe0_scheme = COMPLEX_2_REAL;
                        pe1_scheme = COMPLEX_ROTATE;
                        dataR_n[{2'd0,2'd2}] = pe0_x0_o;
                        dataI_n[{2'd0,2'd2}] = pe0_y0_o;
                        dataR_n[{2'd3,2'd2}] = pe0_x1_o;
                        dataI_n[{2'd3,2'd2}] = pe0_y1_o;
                        dataR_n[{2'd0,2'd3}] = pe1_x0_o;
                        dataI_n[{2'd0,2'd3}] = pe1_y0_o;
                        dataR_n[{2'd3,2'd3}] = pe1_x1_o;
                        dataI_n[{2'd3,2'd3}] = pe1_y1_o;
                        pe0_x0_i = dataR[{2'd0,2'd1}];
                        pe0_y0_i = dataI[{2'd0,2'd1}];
                        pe0_x1_i = pe0_x0_o;
                        pe0_y1_i = pe0_y0_o;
                        pe1_x0_i = dataR[{2'd1,2'd1}];
                        pe1_y0_i = dataI[{2'd1,2'd1}];
                        pe1_x1_i = dataR[{2'd1,2'd2}];
                        pe1_y1_i = dataI[{2'd1,2'd2}];
                    end
                    7'd16: begin
                        pe0_valid = 2'b11;
                        pe1_valid = 2'b11;
                        pe0_scheme = COMPLEX_ROTATE;
                        pe1_scheme = COMPLEX_ROTATE;
                        pe0_x0_i = dataR[{2'd2,2'd1}];
                        pe0_y0_i = dataI[{2'd2,2'd1}];
                        pe0_x1_i = dataR[{2'd2,2'd2}];
                        pe0_y1_i = dataI[{2'd2,2'd2}];
                        pe1_x0_i = dataR[{2'd3,2'd1}];
                        pe1_y0_i = dataI[{2'd3,2'd1}];
                        pe1_x1_i = dataR[{2'd3,2'd2}];
                        pe1_y1_i = dataI[{2'd3,2'd2}];
                    end
                    7'd17: begin
                        pe0_valid = 2'b01;
                        pe1_valid = 2'b01;
                        pe0_scheme = COMPLEX_2_REAL;
                        pe1_scheme = COMPLEX_ROTATE;
                        pe0_x0_i = dataR[{2'd0,2'd3}];
                        pe0_y0_i = dataI[{2'd0,2'd3}];
                        pe1_x0_i = dataR[{2'd1,2'd3}]; 
                        pe1_y0_i = dataI[{2'd1,2'd3}]; 
                    end
                    7'd18: begin
                        pe0_valid = 2'b01;
                        pe1_valid = 2'b01;
                        pe0_scheme = COMPLEX_ROTATE;
                        pe1_scheme = COMPLEX_ROTATE;
                        pe0_x0_i = dataR[{2'd2,2'd3}];
                        pe0_y0_i = dataI[{2'd2,2'd3}];
                        pe0_x1_i = dataR[{2'd2,2'd0}];
                        pe0_y1_i = dataI[{2'd2,2'd0}];
                        pe1_x0_i = dataR[{2'd3,2'd3}]; 
                        pe1_y0_i = dataI[{2'd3,2'd3}]; 
                        pe1_x1_i = dataR[{2'd3,2'd0}]; 
                        pe1_y1_i = dataI[{2'd3,2'd0}]; 
                    end
                    7'd19: begin
                        pe0_valid = 2'b11;
                        pe1_valid = 2'b11;
                        pe0_scheme = REAL_NULLIFIED;
                        pe1_scheme = RELATED_ROTATE;
                        dataR_n[{2'd0,2'd1}] = pe0_x0_o;
                        dataI_n[{2'd0,2'd1}] = pe0_y0_o;
                        dataR_n[{2'd0,2'd2}] = pe0_x1_o;
                        dataI_n[{2'd0,2'd2}] = pe0_y1_o;
                        dataR_n[{2'd1,2'd1}] = pe1_x0_o;
                        dataI_n[{2'd1,2'd1}] = pe1_y0_o;
                        dataR_n[{2'd1,2'd2}] = pe1_x1_o;
                        dataI_n[{2'd1,2'd2}] = pe1_y1_o;
                        pe0_x0_i = pe0_x0_o;
                        pe0_y0_i = pe0_y0_o;
                        pe0_x1_i = pe0_x1_o;
                        pe0_y1_i = pe0_y1_o;
                        pe1_x0_i = pe1_x0_o;
                        pe1_y0_i = pe1_y0_o;
                        pe1_x1_i = pe1_x1_o;
                        pe1_y1_i = pe1_y1_o;
                    end
                    7'd20: begin 
                        pe0_valid = 2'b11;
                        pe1_valid = 2'b11;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                        dataR_n[{2'd2,2'd1}] = pe0_x0_o;
                        dataI_n[{2'd2,2'd1}] = pe0_y0_o;
                        dataR_n[{2'd2,2'd2}] = pe0_x1_o;
                        dataI_n[{2'd2,2'd2}] = pe0_y1_o;
                        dataR_n[{2'd3,2'd1}] = pe1_x0_o;
                        dataI_n[{2'd3,2'd1}] = pe1_y0_o;
                        dataR_n[{2'd3,2'd2}] = pe1_x1_o;
                        dataI_n[{2'd3,2'd2}] = pe1_y1_o;
                        pe0_x0_i = pe0_x0_o;
                        pe0_y0_i = pe0_y0_o;
                        pe0_x1_i = pe0_x1_o;
                        pe0_y1_i = pe0_y1_o;
                        pe1_x0_i = pe1_x0_o;
                        pe1_y0_i = pe1_y0_o;
                        pe1_x1_i = pe1_x1_o;
                        pe1_y1_i = pe1_y1_o;
                    end
                    7'd21: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                        dataR_n[{2'd0,2'd3}] = pe0_x0_o;
                        dataI_n[{2'd0,2'd3}] = pe0_y0_o;
                        dataR_n[{2'd1,2'd3}] = pe1_x0_o; 
                        dataI_n[{2'd1,2'd3}] = pe1_y0_o; 
                        dataR_n[{2'd1,2'd0}] = pe1_x1_o; 
                        dataI_n[{2'd1,2'd0}] = pe1_y1_o; 
                    end
                    7'd22: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                        dataR_n[{2'd2,2'd3}] = pe0_x0_o;
                        dataI_n[{2'd2,2'd3}] = pe0_y0_o;
                        dataR_n[{2'd2,2'd0}] = pe0_x1_o;
                        dataI_n[{2'd2,2'd0}] = pe0_y1_o;
                        dataR_n[{2'd3,2'd3}] = pe1_x0_o; 
                        dataI_n[{2'd3,2'd3}] = pe1_y0_o; 
                        dataR_n[{2'd3,2'd0}] = pe1_x1_o; 
                        dataI_n[{2'd3,2'd0}] = pe1_y1_o; 
                    end
                    7'd23: begin
                        pe0_valid = 2'b11;
                        pe1_valid = 2'b11;
                        pe0_scheme = REAL_NULLIFIED;
                        pe1_scheme = RELATED_ROTATE;
                        dataR_n[{2'd0,2'd1}] = pe0_x0_o;
                        dataI_n[{2'd0,2'd1}] = pe0_y0_o;
                        dataR_n[{2'd0,2'd2}] = pe0_x1_o;
                        dataI_n[{2'd0,2'd2}] = pe0_y1_o;
                        dataR_n[{2'd1,2'd1}] = pe1_x0_o;
                        dataI_n[{2'd1,2'd1}] = pe1_y0_o;
                        dataR_n[{2'd1,2'd2}] = pe1_x1_o;
                        dataI_n[{2'd1,2'd2}] = pe1_y1_o;
                        pe0_x0_i = pe0_x0_o;
                        pe0_y0_i = pe0_y0_o;
                        pe0_x1_i = dataR[{2'd0,2'd3}];
                        pe0_y1_i = dataI[{2'd0,2'd3}];
                        pe1_x0_i = pe1_x0_o;
                        pe1_y0_i = pe1_y0_o;
                        pe1_x1_i = dataR[{2'd1,2'd3}];
                        pe1_y1_i = dataI[{2'd1,2'd3}];
                    end
                    7'd24: begin 
                        pe0_valid = 2'b11;
                        pe1_valid = 2'b11;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                        dataR_n[{2'd2,2'd1}] = pe0_x0_o;
                        dataI_n[{2'd2,2'd1}] = pe0_y0_o;
                        dataR_n[{2'd2,2'd2}] = pe0_x1_o;
                        dataI_n[{2'd2,2'd2}] = pe0_y1_o;
                        dataR_n[{2'd3,2'd1}] = pe1_x0_o;
                        dataI_n[{2'd3,2'd1}] = pe1_y0_o;
                        dataR_n[{2'd3,2'd2}] = pe1_x1_o;
                        dataI_n[{2'd3,2'd2}] = pe1_y1_o;
                        pe0_x0_i = pe0_x0_o;
                        pe0_y0_i = pe0_y0_o;
                        pe0_x1_i = dataR[{2'd2,2'd3}];
                        pe0_y1_i = dataI[{2'd2,2'd3}];
                        pe1_x0_i = pe1_x0_o;
                        pe1_y0_i = pe1_y0_o;
                        pe1_x1_i = dataR[{2'd3,2'd3}];
                        pe1_y1_i = dataI[{2'd3,2'd3}];
                    end
                    7'd25: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                    end
                    7'd26: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                    end
                    7'd27: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                        dataR_n[{2'd0,2'd1}] = pe0_x0_o;
                        dataI_n[{2'd0,2'd1}] = pe0_y0_o;
                        dataR_n[{2'd0,2'd3}] = pe0_x1_o;
                        dataI_n[{2'd0,2'd3}] = pe0_y1_o;
                        dataR_n[{2'd1,2'd1}] = pe1_x0_o;
                        dataI_n[{2'd1,2'd1}] = pe1_y0_o;
                        dataR_n[{2'd1,2'd3}] = pe1_x1_o;
                        dataI_n[{2'd1,2'd3}] = pe1_y1_o;
                    end
                    7'd28: begin 
                        pe0_valid = 2'b11;
                        pe1_valid = 2'b11;
                        pe0_scheme = COMPLEX_2_REAL;
                        pe1_scheme = COMPLEX_ROTATE;
                        dataR_n[{2'd2,2'd1}] = pe0_x0_o;
                        dataI_n[{2'd2,2'd1}] = pe0_y0_o;
                        dataR_n[{2'd2,2'd3}] = pe0_x1_o;
                        dataI_n[{2'd2,2'd3}] = pe0_y1_o;
                        dataR_n[{2'd3,2'd1}] = pe1_x0_o;
                        dataI_n[{2'd3,2'd1}] = pe1_y0_o;
                        dataR_n[{2'd3,2'd3}] = pe1_x1_o;
                        dataI_n[{2'd3,2'd3}] = pe1_y1_o;
                        pe0_x0_i = dataR[{2'd1,2'd1}];
                        pe0_y0_i = dataI[{2'd1,2'd1}];
                        pe0_x1_i = pe0_x0_o;
                        pe0_y1_i = pe0_y0_o;
                        pe1_x0_i = dataR[{2'd1,2'd2}];
                        pe1_y0_i = dataI[{2'd1,2'd2}];
                        pe1_x1_i = dataR[{2'd2,2'd2}];
                        pe1_y1_i = dataI[{2'd2,2'd2}];
                    end
                    7'd29: begin 
                        pe0_valid = 2'b11;
                        pe1_valid = 2'b00;
                        pe0_scheme = COMPLEX_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                        pe0_x0_i = dataR[{2'd1,2'd3}];
                        pe0_y0_i = dataI[{2'd1,2'd3}];
                        pe0_x1_i = dataR[{2'd2,2'd3}];
                        pe0_y1_i = dataI[{2'd2,2'd3}];
                        pe1_x0_i = 0;
                        pe1_y0_i = 0;
                        pe1_x1_i = 0;
                        pe1_y1_i = 0;
                    end
                    7'd30: begin 
                        pe0_valid = 2'b01;
                        pe1_valid = 2'b01;
                        pe0_scheme = COMPLEX_2_REAL;
                        pe1_scheme = COMPLEX_ROTATE;
                        pe0_x0_i = dataR[{2'd3,2'd1}];
                        pe0_y0_i = dataI[{2'd3,2'd1}];
                        pe0_x1_i = 0;
                        pe0_y1_i = 0;
                        pe1_x0_i = dataR[{2'd3,2'd2}];
                        pe1_y0_i = dataI[{2'd3,2'd2}];
                        pe1_x1_i = 0;
                        pe1_y1_i = 0;
                    end
                    7'd31: begin 
                        pe0_valid = 2'b01;
                        pe1_valid = 2'b00;
                        pe0_scheme = COMPLEX_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                        pe0_x0_i = dataR[{2'd3,2'd3}];
                        pe0_y0_i = dataI[{2'd3,2'd3}];
                        pe0_x1_i = 0;
                        pe0_y1_i = 0;
                        pe1_x0_i = 0;
                        pe1_y0_i = 0;
                        pe1_x1_i = 0;
                        pe1_y1_i = 0;
                    end
                    7'd32: begin 
                        pe0_valid = 2'b11;
                        pe1_valid = 2'b11;
                        pe0_scheme = REAL_NULLIFIED;
                        pe1_scheme = RELATED_ROTATE;
                        dataR_n[{2'd1,2'd1}] = pe0_x0_o;
                        dataI_n[{2'd1,2'd1}] = pe0_y0_o;
                        dataR_n[{2'd2,2'd1}] = pe0_x1_o;
                        dataI_n[{2'd2,2'd1}] = pe0_y1_o;
                        dataR_n[{2'd1,2'd2}] = pe1_x0_o;
                        dataI_n[{2'd1,2'd2}] = pe1_y0_o;
                        dataR_n[{2'd2,2'd2}] = pe1_x1_o;
                        dataI_n[{2'd2,2'd2}] = pe1_y1_o;
                        pe0_x0_i = pe0_x0_o;
                        pe0_y0_i = pe0_y0_o;
                        pe0_x1_i = pe0_x1_o;
                        pe0_y1_i = pe0_y1_o;
                        pe1_x0_i = pe1_x0_o;
                        pe1_y0_i = pe1_y0_o;
                        pe1_x1_i = pe1_x1_o;
                        pe1_y1_i = pe1_y1_o;
                    end
                    7'd33: begin 
                        pe0_valid = 2'b11;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                        dataR_n[{2'd1,2'd3}] = pe0_x0_o;
                        dataI_n[{2'd1,2'd3}] = pe0_y0_o;
                        dataR_n[{2'd2,2'd3}] = pe0_x1_o;
                        dataI_n[{2'd2,2'd3}] = pe0_y1_o;
                        pe0_x0_i = pe0_x0_o;
                        pe0_y0_i = pe0_y0_o;
                        pe0_x1_i = pe0_x1_o;
                        pe0_y1_i = pe0_y1_o;
                        pe1_x0_i = 0;
                        pe1_y0_i = 0;
                        pe1_x1_i = 0;
                        pe1_y1_i = 0;
                    end
                    7'd34: begin 
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                        dataR_n[{2'd3,2'd1}] = pe0_x0_o;
                        dataI_n[{2'd3,2'd1}] = pe0_y0_o;
                        dataR_n[{2'd3,2'd2}] = pe1_x0_o;
                        dataI_n[{2'd3,2'd2}] = pe1_y0_o;
                    end 
                    7'd35: begin 
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                        dataR_n[{2'd3,2'd3}] = pe0_x0_o;
                        dataI_n[{2'd3,2'd3}] = pe0_y0_o;
                    end
                    7'd36: begin 
                        pe0_valid = 2'b11;
                        pe1_valid = 2'b11;
                        pe0_scheme = REAL_NULLIFIED;
                        pe1_scheme = RELATED_ROTATE;
                        dataR_n[{2'd1,2'd1}] = pe0_x0_o;
                        dataI_n[{2'd1,2'd1}] = pe0_y0_o;
                        dataR_n[{2'd2,2'd1}] = pe0_x1_o;
                        dataI_n[{2'd2,2'd1}] = pe0_y1_o;
                        dataR_n[{2'd1,2'd2}] = pe1_x0_o;
                        dataI_n[{2'd1,2'd2}] = pe1_y0_o;
                        dataR_n[{2'd2,2'd2}] = pe1_x1_o;
                        dataI_n[{2'd2,2'd2}] = pe1_y1_o;
                        pe0_x0_i = pe0_x0_o;
                        pe0_y0_i = pe0_y0_o;
                        pe0_x1_i = dataR[{2'd3,2'd1}];
                        pe0_y1_i = dataI[{2'd3,2'd1}];
                        pe1_x0_i = pe1_x0_o;
                        pe1_y0_i = pe1_y0_o;
                        pe1_x1_i = dataR[{2'd3,2'd2}];
                        pe1_y1_i = dataI[{2'd3,2'd2}];
                    end
                    7'd37: begin 
                        pe0_valid = 2'b11;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                        dataR_n[{2'd1,2'd3}] = pe0_x0_o;
                        dataI_n[{2'd1,2'd3}] = pe0_y0_o;
                        dataR_n[{2'd2,2'd3}] = pe0_x1_o;
                        dataI_n[{2'd2,2'd3}] = pe0_y1_o;
                        pe0_x0_i = pe0_x0_o;
                        pe0_y0_i = pe0_y0_o;
                        pe0_x1_i = dataR[{2'd3,2'd3}];
                        pe0_y1_i = dataI[{2'd3,2'd3}];
                    end
                    7'd38: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                    end
                    7'd39: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                    end
                    7'd40: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                        dataR_n[{2'd1,2'd1}] = pe0_x0_o;
                        dataI_n[{2'd1,2'd1}] = pe0_y0_o;
                        dataR_n[{2'd3,2'd1}] = pe0_x1_o;
                        dataI_n[{2'd3,2'd1}] = pe0_y1_o;
                        dataR_n[{2'd1,2'd2}] = pe1_x0_o;
                        dataI_n[{2'd1,2'd2}] = pe1_y0_o;
                        dataR_n[{2'd3,2'd2}] = pe1_x1_o;
                        dataI_n[{2'd3,2'd2}] = pe1_y1_o;
                    end
                    7'd41: begin
                        pe0_valid = 2'b11;
                        pe1_valid = 2'b11;
                        pe0_scheme = COMPLEX_2_REAL;
                        pe1_scheme = COMPLEX_ROTATE;
                        dataR_n[{2'd1,2'd3}] = pe0_x0_o;
                        dataI_n[{2'd1,2'd3}] = pe0_y0_o;
                        dataR_n[{2'd3,2'd3}] = pe0_x1_o;
                        dataI_n[{2'd3,2'd3}] = pe0_y1_o;
                        pe0_x0_i = dataR[{2'd1,2'd2}];
                        pe0_y0_i = dataI[{2'd1,2'd2}];
                        pe0_x1_i = pe0_x0_o;
                        pe0_y1_i = pe0_y0_o;
                        pe1_x0_i = dataR[{2'd2,2'd2}];
                        pe1_y0_i = dataI[{2'd2,2'd2}];
                        pe1_x1_i = dataR[{2'd2,2'd3}];
                        pe1_y1_i = dataI[{2'd2,2'd3}];
                    end
                    7'd42: begin
                        pe0_valid = 2'b11;
                        pe1_valid = 2'b00;
                        pe0_scheme = COMPLEX_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                        pe0_x0_i = dataR[{2'd3,2'd2}];
                        pe0_y0_i = dataI[{2'd3,2'd2}];
                        pe0_x1_i = dataR[{2'd3,2'd3}];
                        pe0_y1_i = dataI[{2'd3,2'd3}];
                    end
                    7'd43: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                    end
                    7'd44: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                    end
                    7'd45: begin
                        pe0_valid = 2'b11;
                        pe1_valid = 2'b11;
                        pe0_scheme = REAL_NULLIFIED;
                        pe1_scheme = RELATED_ROTATE;
                        dataR_n[{2'd1,2'd2}] = pe0_x0_o;
                        dataI_n[{2'd1,2'd2}] = pe0_y0_o;
                        dataR_n[{2'd1,2'd3}] = pe0_x1_o;
                        dataI_n[{2'd1,2'd3}] = pe0_y1_o;
                        dataR_n[{2'd2,2'd2}] = pe1_x0_o;
                        dataI_n[{2'd2,2'd2}] = pe1_y0_o;
                        dataR_n[{2'd2,2'd3}] = pe1_x1_o;
                        dataI_n[{2'd2,2'd3}] = pe1_y1_o;
                        pe0_x0_i = pe0_x0_o;
                        pe0_y0_i = pe0_y0_o;
                        pe0_x1_i = pe0_x1_o;
                        pe0_y1_i = pe0_y1_o;
                        pe1_x0_i = pe1_x0_o;
                        pe1_y0_i = pe1_y0_o;
                        pe1_x1_i = pe1_x1_o;
                        pe1_y1_i = pe1_y1_o;
                    end
                    7'd46: begin
                        pe0_valid = 2'b11;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                        dataR_n[{2'd3,2'd2}] = pe0_x0_o;
                        dataI_n[{2'd3,2'd2}] = pe0_y0_o;
                        dataR_n[{2'd3,2'd3}] = pe0_x1_o;
                        dataI_n[{2'd3,2'd3}] = pe0_y1_o;
                        pe0_x0_i = pe0_x0_o;
                        pe0_y0_i = pe0_y0_o;
                        pe0_x1_i = pe0_x1_o;
                        pe0_y1_i = pe0_y1_o;
                    end
                    7'd47: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                    end
                    7'd48: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                    end
                    7'd49: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                        dataR_n[{2'd1,2'd2}] = pe0_x0_o;
                        dataI_n[{2'd1,2'd2}] = pe0_y0_o;
                        dataR_n[{2'd1,2'd3}] = pe0_x1_o;
                        dataI_n[{2'd1,2'd3}] = pe0_y1_o;
                        dataR_n[{2'd2,2'd2}] = pe1_x0_o;
                        dataI_n[{2'd2,2'd2}] = pe1_y0_o;
                        dataR_n[{2'd2,2'd3}] = pe1_x1_o;
                        dataI_n[{2'd2,2'd3}] = pe1_y1_o;
                    end
                    7'd50: begin
                        pe0_valid = 2'b11;
                        pe1_valid = 2'b11;
                        pe0_scheme = COMPLEX_2_REAL;
                        pe1_scheme = COMPLEX_ROTATE;
                        dataR_n[{2'd3,2'd2}] = pe0_x0_o;
                        dataI_n[{2'd3,2'd2}] = pe0_y0_o;
                        dataR_n[{2'd3,2'd3}] = pe0_x1_o;
                        dataI_n[{2'd3,2'd3}] = pe0_y1_o;
                        pe0_x0_i = dataR[{2'd2,2'd2}];
                        pe0_y0_i = dataI[{2'd2,2'd2}];
                        pe0_x1_i = pe0_x0_o;
                        pe0_y1_i = pe0_y0_o;
                        pe1_x0_i = dataR[{2'd2,2'd3}];
                        pe1_y0_i = dataI[{2'd2,2'd3}];
                        pe1_x1_i = pe0_x1_o;
                        pe1_y1_i = pe0_y1_o;
                    end
                    7'd51: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                    end
                    7'd52: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                    end
                    7'd53: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                    end
                    7'd54: begin
                        pe0_valid = 2'b11;
                        pe1_valid = 2'b11;
                        pe0_scheme = REAL_NULLIFIED;
                        pe1_scheme = RELATED_ROTATE;
                        dataR_n[{2'd2,2'd2}] = pe0_x0_o;
                        dataI_n[{2'd2,2'd2}] = pe0_y0_o;
                        dataR_n[{2'd3,2'd2}] = pe0_x1_o;
                        dataI_n[{2'd3,2'd2}] = pe0_y1_o;
                        dataR_n[{2'd2,2'd3}] = pe1_x0_o;
                        dataI_n[{2'd2,2'd3}] = pe1_y0_o;
                        dataR_n[{2'd3,2'd3}] = pe1_x1_o;
                        dataI_n[{2'd3,2'd3}] = pe1_y1_o;
                        pe0_x0_i = pe0_x0_o;
                        pe0_y0_i = pe0_y0_o;
                        pe0_x1_i = pe0_x1_o;
                        pe0_y1_i = pe0_y1_o;
                        pe1_x0_i = pe1_x0_o;
                        pe1_y0_i = pe1_y0_o;
                        pe1_x1_i = pe1_x1_o;
                        pe1_y1_i = pe1_y1_o;
                    end
                    7'd55: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                    end
                    7'd56: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                    end
                    7'd57: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                    end
                    7'd58: begin
                        pe0_valid = 2'b01;
                        pe1_valid = 2'b01;
                        pe0_scheme = COMPLEX_2_REAL;
                        pe1_scheme = COMPLEX_ROTATE;
                        dataR_n[{2'd2,2'd2}] = pe0_x0_o;
                        dataI_n[{2'd2,2'd2}] = pe0_y0_o;
                        dataR_n[{2'd3,2'd2}] = pe0_x1_o;
                        dataI_n[{2'd3,2'd2}] = pe0_y1_o;
                        dataR_n[{2'd2,2'd3}] = pe1_x0_o;
                        dataI_n[{2'd2,2'd3}] = pe1_y0_o;
                        dataR_n[{2'd3,2'd3}] = pe1_x1_o;
                        dataI_n[{2'd3,2'd3}] = pe1_y1_o;
                        pe0_x0_i = pe1_x0_o;
                        pe0_y0_i = pe1_y0_o;
                        pe1_x0_i = pe1_x1_o;
                        pe1_y0_i = pe1_y1_o;
                    end
                    7'd59: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                    end
                    7'd60: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                    end
                    7'd61: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                    end
                    7'd62: begin
                        pe0_valid = 2'b01;
                        pe1_valid = 2'b00;
                        pe0_scheme = COMPLEX_2_REAL;
                        pe1_scheme = RELATED_ROTATE;
                        dataR_n[{2'd2,2'd3}] = pe0_x0_o;
                        dataI_n[{2'd2,2'd3}] = pe0_y0_o;
                        dataR_n[{2'd3,2'd3}] = pe1_x0_o;
                        dataI_n[{2'd3,2'd3}] = pe1_y0_o;
                        pe0_x0_i = pe1_x0_o;
                        pe0_y0_i = pe1_y0_o;
                    end
                    7'd63: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                    end
                    7'd64: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                    end
                    7'd65: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                    end
                    7'd66: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                        dataR_n[{2'd3,2'd3}] = pe0_x0_o;
                        dataI_n[{2'd3,2'd3}] = pe0_y0_o;
                    end
                    default: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
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