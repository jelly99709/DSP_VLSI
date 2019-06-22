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
    parameter MAXSWEEP = 8;


    //input & output port definition 
    input clk, rst_n;
    input valid_i;
    input signed [BIT_NUM-1:0] R_i, I_i;
    output reg signed [BIT_NUM-1:0] R_o, I_o;
    output reg [1:0] valid_o;

    //internal port declaration
    reg [1:0] pe0_valid, pe1_valid;
    reg [1:0] pe0_scheme, pe1_scheme;
    reg signed [BIT_NUM-1:0] pe0_x0_i, pe0_y0_i, pe0_x1_i, pe0_y1_i;
    reg signed [BIT_NUM-1:0] pe1_x0_i, pe1_y0_i, pe1_x1_i, pe1_y1_i;
    wire signed [BIT_NUM-1:0] pe0_x0_o, pe0_y0_o, pe0_x1_o, pe0_y1_o;
    wire signed [BIT_NUM-1:0] pe1_x0_o, pe1_y0_o, pe1_x1_o, pe1_y1_o;
    reg [1:0] vec_pe0_valid, vec_pe1_valid;
    reg [1:0] vec_pe0_scheme, vec_pe1_scheme;
    reg signed [BIT_NUM-1:0] vec_pe0_x0_i, vec_pe0_y0_i, vec_pe0_x1_i, vec_pe0_y1_i;
    reg signed [BIT_NUM-1:0] vec_pe1_x0_i, vec_pe1_y0_i, vec_pe1_x1_i, vec_pe1_y1_i;
    wire signed [BIT_NUM-1:0] vec_pe0_x0_o, vec_pe0_y0_o, vec_pe0_x1_o, vec_pe0_y1_o;
    wire signed [BIT_NUM-1:0] vec_pe1_x0_o, vec_pe1_y0_o, vec_pe1_x1_o, vec_pe1_y1_o;
    reg [1:0] inv;
    reg inv_i;
    wire [1:0] inv_n;
    wire [ROTATION_NUM-1:0] angle_inv;

    assign inv_n = {inv[0], inv_i};
    assign angle_inv = {{5{inv[1]}}, {5{inv[0]}}, {4{inv_i}}};

    localparam COMPLEX_2_REAL = 2'd0;
    localparam COMPLEX_ROTATE = 2'd1;
    localparam REAL_NULLIFIED = 2'd2;
    localparam RELATED_ROTATE = 2'd3;

    //wire & reg declaration
    reg signed [BIT_NUM-1:0] dataR   [0:CHANNEL_SIZE-1];
    reg signed [BIT_NUM-1:0] dataR_n [0:CHANNEL_SIZE-1];
    reg signed [BIT_NUM-1:0] dataI   [0:CHANNEL_SIZE-1];
    reg signed [BIT_NUM-1:0] dataI_n [0:CHANNEL_SIZE-1];
    reg signed [BIT_NUM-1:0] rvec_dataR   [0:CHANNEL_SIZE-1];
    reg signed [BIT_NUM-1:0] rvec_dataR_n [0:CHANNEL_SIZE-1];
    reg signed [BIT_NUM-1:0] rvec_dataI   [0:CHANNEL_SIZE-1];
    reg signed [BIT_NUM-1:0] rvec_dataI_n [0:CHANNEL_SIZE-1];
    reg signed [BIT_NUM-1:0] lvec_dataR   [0:CHANNEL_SIZE-1];
    reg signed [BIT_NUM-1:0] lvec_dataR_n [0:CHANNEL_SIZE-1];
    reg signed [BIT_NUM-1:0] lvec_dataI   [0:CHANNEL_SIZE-1];
    reg signed [BIT_NUM-1:0] lvec_dataI_n [0:CHANNEL_SIZE-1];
    reg [$clog2(CHANNEL_SIZE)-1:0] cnt, cnt_n;
    reg [$clog2(MAXSWEEP)-1:0] sw_num, sw_num_n;
    reg [1:0] valid_o_n;
    reg neg_val;
    wire diag_end;

    
    //state definition
    reg [2:0] STATE, STATE_N;
    reg [6:0] PHASE, PHASE_N;
    reg [4:0] DIAG_STATE, DIAG_STATE_N;
    reg DPHASE, DPHASE_N;
    localparam IDLE    = 3'd0;
    localparam RECIEVE = 3'd1;
    localparam BIDIAG  = 3'd2;
    localparam DIAG    = 3'd3;
    localparam SEND    = 3'd4;
    //localparam DONE    = 3'd5;

    integer i;
    
    localparam BIDEND = 7'd67;
    assign diag_end = (sw_num == MAXSWEEP-1) && (DIAG_STATE == 5'd15);

    PE_cluster PEs(
        .clk(clk),
        .rst_n(rst_n),
        .val_PE0_valid_i(pe0_valid),
        .val_PE1_valid_i(pe1_valid),
        .val_PE0_scheme_i(pe0_scheme),
        .val_PE1_scheme_i(pe1_scheme),
        .val_PE0_X0_i(pe0_x0_i), .val_PE0_Y0_i(pe0_y0_i),
        .val_PE0_X1_i(pe0_x1_i), .val_PE0_Y1_i(pe0_y1_i),
        .val_PE1_X0_i(pe1_x0_i), .val_PE1_Y0_i(pe1_y0_i),
        .val_PE1_X1_i(pe1_x1_i), .val_PE1_Y1_i(pe1_y1_i),
        .val_PE0_X0_o(pe0_x0_o), .val_PE0_Y0_o(pe0_y0_o),
        .val_PE0_X1_o(pe0_x1_o), .val_PE0_Y1_o(pe0_y1_o),
        .val_PE1_X0_o(pe1_x0_o), .val_PE1_Y0_o(pe1_y0_o),
        .val_PE1_X1_o(pe1_x1_o), .val_PE1_Y1_o(pe1_y1_o), 
        .vec_PE0_valid_i(vec_pe0_valid),
        .vec_PE1_valid_i(vec_pe1_valid),
        .vec_PE0_scheme_i(vec_pe0_scheme),
        .vec_PE1_scheme_i(vec_pe1_scheme),
        .vec_PE0_X0_i(vec_pe0_x0_i), .vec_PE0_Y0_i(vec_pe0_y0_i),
        .vec_PE0_X1_i(vec_pe0_x1_i), .vec_PE0_Y1_i(vec_pe0_y1_i),
        .vec_PE1_X0_i(vec_pe1_x0_i), .vec_PE1_Y0_i(vec_pe1_y0_i),
        .vec_PE1_X1_i(vec_pe1_x1_i), .vec_PE1_Y1_i(vec_pe1_y1_i),
        .vec_PE0_X0_o(vec_pe0_x0_o), .vec_PE0_Y0_o(vec_pe0_y0_o),
        .vec_PE0_X1_o(vec_pe0_x1_o), .vec_PE0_Y1_o(vec_pe0_y1_o),
        .vec_PE1_X0_o(vec_pe1_x0_o), .vec_PE1_Y0_o(vec_pe1_y0_o),
        .vec_PE1_X1_o(vec_pe1_x1_o), .vec_PE1_Y1_o(vec_pe1_y1_o), 
        .angle_inv(angle_inv)
        );

    //state transfer

    always@(*) begin
        
        case(STATE)
            IDLE:    STATE_N = valid_i ? RECIEVE : IDLE;
            RECIEVE: STATE_N = ~valid_i ? BIDIAG : RECIEVE;
            BIDIAG:  STATE_N = (PHASE == BIDEND) ? DIAG : BIDIAG;
            DIAG:    STATE_N = (diag_end) ? SEND:DIAG;
            SEND:    STATE_N = (cnt == CHANNEL_SIZE-1 && valid_o == 2'b11) ? IDLE : SEND;
            //DONE:    STATE_N = DONE;
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
        neg_val = 0;
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

        DIAG_STATE_N = DIAG_STATE;
        DPHASE_N = DPHASE;
        sw_num_n = sw_num;

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
                valid_o_n = 2'b00;
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
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
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
                        pe1_x0_i = dataR[{2'd3,2'd3}]; 
                        pe1_y0_i = dataI[{2'd3,2'd3}]; 

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
                    end
                    7'd22: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                        dataR_n[{2'd2,2'd3}] = pe0_x0_o;
                        dataI_n[{2'd2,2'd3}] = pe0_y0_o;
                        dataR_n[{2'd3,2'd3}] = pe1_x0_o; 
                        dataI_n[{2'd3,2'd3}] = pe1_y0_o; 
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
                    7'd67: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                    end
                    default: begin
                        pe0_valid = 2'b00;
                        pe1_valid = 2'b00;
                        pe0_scheme = RELATED_ROTATE;
                        pe1_scheme = RELATED_ROTATE;
                    end
                endcase
            end
            DIAG: begin
                valid_o_n = (diag_end) ? 1 : 0;
                case (DPHASE)
                    1'b0: begin
                        sw_num_n = sw_num;
                        if(cnt[1:0] == 3'b00) begin
                            pe0_valid = 2'b11;
                            pe1_valid = 2'b11;
                            pe0_scheme = REAL_NULLIFIED;
                            pe1_scheme = RELATED_ROTATE;
                            pe0_x0_i = dataR[{2'd0,2'd0}];
                            pe0_y0_i = dataI[{2'd0,2'd0}];
                            pe0_x1_i = dataR[{2'd0,2'd1}];
                            pe0_y1_i = dataI[{2'd0,2'd1}];
                            pe1_x0_i = dataR[{2'd1,2'd0}];
                            pe1_y0_i = dataI[{2'd1,2'd0}];
                            pe1_x1_i = dataR[{2'd1,2'd1}];
                            pe1_y1_i = dataI[{2'd1,2'd1}];
                            DPHASE_N = 0;
                            cnt_n = cnt + 1;
                        end

                        else if(cnt[1:0] == 2'b11) begin
                            pe0_valid = 2'b00;
                            pe1_valid = 2'b00;
                            pe0_scheme = RELATED_ROTATE;
                            pe1_scheme = RELATED_ROTATE;
                            DPHASE_N = 1;
                            cnt_n = 0;
                        end
                        else begin
                            pe0_valid = 2'b00;
                            pe1_valid = 2'b00;
                            pe0_scheme = RELATED_ROTATE;
                            pe1_scheme = RELATED_ROTATE;
                            DPHASE_N = 0;
                            cnt_n = cnt + 1;
                        end

                    end
                    1'b1: begin
                        DPHASE_N = 1;
                        cnt_n = 0;
                        if(DIAG_STATE == 5'd19) begin
                            DIAG_STATE_N = 5'd0;
                            sw_num_n = sw_num + 1;
                        end
                        else begin
                            DIAG_STATE_N = DIAG_STATE + 1;
                            sw_num_n = sw_num;
                        end

                        if(DIAG_STATE[0]) begin
                            pe0_valid = 2'b00;
                            pe1_valid = 2'b00;
                            pe0_scheme = RELATED_ROTATE;
                            pe1_scheme = RELATED_ROTATE;
                        end
                        else begin
                            case (DIAG_STATE[4:1])
                                4'd0: begin
                                    pe0_valid = 2'b11;
                                    pe1_valid = 2'b11;
                                    pe0_scheme = REAL_NULLIFIED;
                                    pe1_scheme = RELATED_ROTATE;
                                    dataR_n[{2'd0,2'd0}] = pe0_x0_o;
                                    dataI_n[{2'd0,2'd0}] = pe0_y0_o;
                                    dataR_n[{2'd0,2'd1}] = pe0_x1_o;
                                    dataI_n[{2'd0,2'd1}] = pe0_y1_o;
                                    dataR_n[{2'd1,2'd0}] = pe1_x0_o;
                                    dataI_n[{2'd1,2'd0}] = pe1_y0_o;
                                    dataR_n[{2'd1,2'd1}] = pe1_x1_o;
                                    dataI_n[{2'd1,2'd1}] = pe1_y1_o;
                                    pe0_x0_i = pe1_x1_o;
                                    pe0_y0_i = pe1_y1_o;
                                    pe0_x1_i = dataR[{2'd1,2'd2}];
                                    pe0_y1_i = dataI[{2'd1,2'd2}];
                                    pe1_x0_i = dataR[{2'd2,2'd1}];
                                    pe1_y0_i = dataI[{2'd2,2'd1}];
                                    pe1_x1_i = dataR[{2'd2,2'd2}];
                                    pe1_y1_i = dataI[{2'd2,2'd2}];
                                end
                                4'd1: begin
                                    pe0_valid = 2'b00;
                                    pe1_valid = 2'b00;
                                    pe0_scheme = RELATED_ROTATE;
                                    pe1_scheme = RELATED_ROTATE;
                                end
                                4'd2: begin
                                    pe0_valid = 2'b11;
                                    pe1_valid = 2'b11;
                                    pe0_scheme = REAL_NULLIFIED;
                                    pe1_scheme = RELATED_ROTATE;
                                    dataR_n[{2'd1,2'd1}] = pe0_x0_o;
                                    dataI_n[{2'd1,2'd1}] = pe0_y0_o;
                                    dataR_n[{2'd1,2'd2}] = pe0_x1_o;
                                    dataI_n[{2'd1,2'd2}] = pe0_y1_o;
                                    dataR_n[{2'd2,2'd1}] = pe1_x0_o;
                                    dataI_n[{2'd2,2'd1}] = pe1_y0_o;
                                    dataR_n[{2'd2,2'd2}] = pe1_x1_o;
                                    dataI_n[{2'd2,2'd2}] = pe1_y1_o;
                                    pe0_x0_i = pe1_x1_o;
                                    pe0_y0_i = pe1_y1_o;
                                    pe0_x1_i = dataR[{2'd2,2'd3}];
                                    pe0_y1_i = dataI[{2'd2,2'd3}];
                                    pe1_x0_i = dataR[{2'd3,2'd2}];
                                    pe1_y0_i = dataI[{2'd3,2'd2}];
                                    pe1_x1_i = dataR[{2'd3,2'd3}];
                                    pe1_y1_i = dataI[{2'd3,2'd3}];
                                end
                                4'd3: begin
                                    pe0_valid = 2'b11;
                                    pe1_valid = 2'b11;
                                    pe0_scheme = REAL_NULLIFIED;
                                    pe1_scheme = RELATED_ROTATE;
                                    pe0_x0_i = dataR[{2'd0,2'd0}];
                                    pe0_y0_i = dataI[{2'd0,2'd0}];
                                    pe0_x1_i = dataR[{2'd1,2'd0}];
                                    pe0_y1_i = dataI[{2'd1,2'd0}];
                                    pe1_x0_i = dataR[{2'd0,2'd1}];
                                    pe1_y0_i = dataI[{2'd0,2'd1}];
                                    pe1_x1_i = dataR[{2'd1,2'd1}];
                                    pe1_y1_i = dataI[{2'd1,2'd1}];
                                end
                                4'd4: begin
                                    pe0_valid = 2'b00;
                                    pe1_valid = 2'b00;
                                    pe0_scheme = RELATED_ROTATE;
                                    pe1_scheme = RELATED_ROTATE;
                                    dataR_n[{2'd2,2'd2}] = pe0_x0_o;
                                    dataI_n[{2'd2,2'd2}] = pe0_y0_o;
                                    dataR_n[{2'd2,2'd3}] = pe0_x1_o;
                                    dataI_n[{2'd2,2'd3}] = pe0_y1_o;
                                    dataR_n[{2'd3,2'd2}] = pe1_x0_o;
                                    dataI_n[{2'd3,2'd2}] = pe1_y0_o;
                                    dataR_n[{2'd3,2'd3}] = pe1_x1_o;
                                    dataI_n[{2'd3,2'd3}] = pe1_y1_o;
                                end
                                4'd5: begin
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
                                    pe0_x0_i = pe1_x1_o;
                                    pe0_y0_i = pe1_y1_o;
                                    pe0_x1_i = dataR[{2'd2,2'd1}];
                                    pe0_y1_i = dataI[{2'd2,2'd1}];
                                    pe1_x0_i = dataR[{2'd1,2'd2}];
                                    pe1_y0_i = dataI[{2'd1,2'd2}];
                                    pe1_x1_i = dataR[{2'd2,2'd2}];
                                    pe1_y1_i = dataI[{2'd2,2'd2}];
                                end
                                4'd6: begin
                                    pe0_valid = 2'b00;
                                    pe1_valid = 2'b00;
                                    pe0_scheme = RELATED_ROTATE;
                                    pe1_scheme = RELATED_ROTATE;
                                end
                                4'd7: begin
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
                                    pe0_x0_i = pe1_x1_o;
                                    pe0_y0_i = pe1_y1_o;
                                    pe0_x1_i = dataR[{2'd3,2'd2}];
                                    pe0_y1_i = dataI[{2'd3,2'd2}];
                                    pe1_x0_i = dataR[{2'd2,2'd3}];
                                    pe1_y0_i = dataI[{2'd2,2'd3}];
                                    pe1_x1_i = dataR[{2'd3,2'd3}];
                                    pe1_y1_i = dataI[{2'd3,2'd3}];
                                end
                                4'd8: begin
                                    pe0_valid = 2'b11;
                                    pe1_valid = 2'b11;
                                    pe0_scheme = REAL_NULLIFIED;
                                    pe1_scheme = RELATED_ROTATE;
                                    pe0_x0_i = dataR[{2'd0,2'd0}];
                                    pe0_y0_i = dataI[{2'd0,2'd0}];
                                    pe0_x1_i = dataR[{2'd0,2'd1}];
                                    pe0_y1_i = dataI[{2'd0,2'd1}];
                                    pe1_x0_i = dataR[{2'd1,2'd0}];
                                    pe1_y0_i = dataI[{2'd1,2'd0}];
                                    pe1_x1_i = dataR[{2'd1,2'd1}];
                                    pe1_y1_i = dataI[{2'd1,2'd1}];
                                end
                                4'd9: begin
                                    pe0_valid = 2'b00;
                                    pe1_valid = 2'b00;
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
                                end

                                default: begin
                                    pe0_valid = 2'b00;
                                    pe1_valid = 2'b00;
                                    pe0_scheme = RELATED_ROTATE;
                                    pe1_scheme = RELATED_ROTATE;
                                end
                            endcase
                        end
                    end
                endcase
            end
            SEND: begin
                cnt_n = cnt + 1;
                case (valid_o)
                    2'b01: begin
                        case (cnt[1:0])
                            2'b00: begin
                                if(dataR[0][BIT_NUM-1]) begin
                                    R_o = -dataR[0];
                                    I_o = 0;
                                    neg_val = 1;
                                end
                                else begin
                                    R_o = dataR[0];
                                    I_o = 0;
                                    neg_val = 0;
                                end
                            end
                            2'b01: begin
                                if(dataR[5][BIT_NUM-1]) begin
                                    R_o = -dataR[5];
                                    I_o = 0;
                                    neg_val = 1;
                                end
                                else begin
                                    R_o = dataR[5];
                                    I_o = 0;
                                    neg_val = 0;
                                end
                            end
                            2'b10: begin
                                if(dataR[10][BIT_NUM-1]) begin
                                    R_o = -dataR[10];
                                    I_o = 0;
                                    neg_val = 1;
                                end
                                else begin
                                    R_o = dataR[10];
                                    I_o = 0;
                                    neg_val = 0;
                                end
                            end
                            2'b11: begin
                                if(dataR[15][BIT_NUM-1]) begin
                                    R_o = -dataR[15];
                                    I_o = 0;
                                    neg_val = 1;
                                end
                                else begin
                                    R_o = dataR[15];
                                    I_o = 0;
                                    neg_val = 0;
                                end
                            end  
                        endcase
                    end

                    2'b10: begin
                        R_o = lvec_dataR[cnt];
                        I_o = lvec_dataI[cnt];
                        neg_val = 0;
                    end

                    2'b11: begin
                        R_o = rvec_dataR[cnt];
                        I_o = rvec_dataI[cnt];
                        neg_val = 0;
                    end
                    default : begin
                        R_o = 0;
                        I_o = 0;
                        neg_val = 0;
                    end
                endcase
                if(cnt == 4'd15 || (cnt == 4'd3 && valid_o ==2'b01)) begin
                    valid_o_n = valid_o + 1;
                    cnt_n = 0;
                end
                else begin
                    valid_o_n = valid_o;
                end
                //valid_o_n = (valid_o == 2'b11 && cnt == 4'd15) ? 0 : 1;
            end
            /*
            DONE: begin
                valid_o_n = 0;
            end
            */
        endcase
    end

    
    //state function
    always@(*) begin

        for(i = 0; i < CHANNEL_SIZE; i = i + 1) begin
            lvec_dataR_n[i] = lvec_dataR[i];
            lvec_dataI_n[i] = lvec_dataI[i];
            rvec_dataR_n[i] = rvec_dataR[i];
            rvec_dataI_n[i] = rvec_dataI[i];
        end

        vec_pe0_valid = 2'b00;
        vec_pe1_valid = 2'b00;
        vec_pe0_scheme = 0;
        vec_pe1_scheme = 0;
        vec_pe0_x0_i = 0;
        vec_pe0_y0_i = 0;
        vec_pe0_x1_i = 0;
        vec_pe0_y1_i = 0;
        vec_pe1_x0_i = 0;
        vec_pe1_y0_i = 0;
        vec_pe1_x1_i = 0;
        vec_pe1_y1_i = 0;
        inv_i    = 0;

        case(STATE)
            IDLE: begin
                for(i = 0; i < CHANNEL_SIZE; i = i + 1) begin
                    lvec_dataR_n[i] = lvec_dataR[i];
                    lvec_dataI_n[i] = lvec_dataI[i];
                    rvec_dataR_n[i] = rvec_dataR[i];
                    rvec_dataI_n[i] = rvec_dataI[i];
                end          
            end
            RECIEVE: begin
                for(i = 0; i < CHANNEL_SIZE; i = i + 1) begin
                    lvec_dataR_n[i] = lvec_dataR[i];
                    lvec_dataI_n[i] = lvec_dataI[i];
                    rvec_dataR_n[i] = rvec_dataR[i];
                    rvec_dataI_n[i] = rvec_dataI[i];
                end 
            end
            BIDIAG: begin
                case(PHASE)
                    7'd0: begin
                        inv_i = 1;
                        vec_pe0_valid = 2'b11;
                        vec_pe1_valid = 2'b11;
                        vec_pe0_scheme = COMPLEX_ROTATE;
                        vec_pe1_scheme = COMPLEX_ROTATE;
                        vec_pe0_x0_i = lvec_dataR[{2'd0,2'd0}];
                        vec_pe0_y0_i = lvec_dataI[{2'd0,2'd0}];
                        vec_pe0_x1_i = lvec_dataR[{2'd0,2'd1}];
                        vec_pe0_y1_i = lvec_dataI[{2'd0,2'd1}];
                        vec_pe1_x0_i = lvec_dataR[{2'd1,2'd0}];
                        vec_pe1_y0_i = lvec_dataI[{2'd1,2'd0}];
                        vec_pe1_x1_i = lvec_dataR[{2'd1,2'd1}];
                        vec_pe1_y1_i = lvec_dataI[{2'd1,2'd1}];
                    end
                    7'd1: begin
                        inv_i = 1;
                        vec_pe0_valid = 2'b11;
                        vec_pe1_valid = 2'b11;
                        vec_pe0_scheme = COMPLEX_ROTATE;
                        vec_pe1_scheme = COMPLEX_ROTATE;
                        vec_pe0_x0_i = lvec_dataR[{2'd2,2'd0}];
                        vec_pe0_y0_i = lvec_dataI[{2'd2,2'd0}];
                        vec_pe0_x1_i = lvec_dataR[{2'd2,2'd1}];
                        vec_pe0_y1_i = lvec_dataI[{2'd2,2'd1}];
                        vec_pe1_x0_i = lvec_dataR[{2'd3,2'd0}];
                        vec_pe1_y0_i = lvec_dataI[{2'd3,2'd0}];
                        vec_pe1_x1_i = lvec_dataR[{2'd3,2'd1}];
                        vec_pe1_y1_i = lvec_dataI[{2'd3,2'd1}];
                    end
                    7'd2: begin
                        inv_i = 1;
                        vec_pe0_valid = 2'b11;
                        vec_pe1_valid = 2'b11;
                        vec_pe0_scheme = COMPLEX_ROTATE;
                        vec_pe1_scheme = COMPLEX_ROTATE;
                        vec_pe0_x0_i = lvec_dataR[{2'd0,2'd2}];
                        vec_pe0_y0_i = lvec_dataI[{2'd0,2'd2}];
                        vec_pe0_x1_i = lvec_dataR[{2'd0,2'd3}];
                        vec_pe0_y1_i = lvec_dataI[{2'd0,2'd3}];
                        vec_pe1_x0_i = lvec_dataR[{2'd1,2'd2}];
                        vec_pe1_y0_i = lvec_dataI[{2'd1,2'd2}];
                        vec_pe1_x1_i = lvec_dataR[{2'd1,2'd3}];
                        vec_pe1_y1_i = lvec_dataI[{2'd1,2'd3}];
                    end
                    7'd3: begin
                        inv_i = 1;
                        vec_pe0_valid = 2'b11;
                        vec_pe1_valid = 2'b11;
                        vec_pe0_scheme = COMPLEX_ROTATE;
                        vec_pe1_scheme = COMPLEX_ROTATE;
                        vec_pe0_x0_i = lvec_dataR[{2'd2,2'd2}];
                        vec_pe0_y0_i = lvec_dataI[{2'd2,2'd2}];
                        vec_pe0_x1_i = lvec_dataR[{2'd2,2'd3}];
                        vec_pe0_y1_i = lvec_dataI[{2'd2,2'd3}];
                        vec_pe1_x0_i = lvec_dataR[{2'd3,2'd2}];
                        vec_pe1_y0_i = lvec_dataI[{2'd3,2'd2}];
                        vec_pe1_x1_i = lvec_dataR[{2'd3,2'd3}];
                        vec_pe1_y1_i = lvec_dataI[{2'd3,2'd3}];
                    end
                    7'd4: begin
                        inv_i = 0;
                        vec_pe0_valid = 2'b11;
                        vec_pe1_valid = 2'b11;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                        lvec_dataR_n[{2'd0,2'd0}] = vec_pe0_x0_o;
                        lvec_dataI_n[{2'd0,2'd0}] = vec_pe0_y0_o;
                        lvec_dataR_n[{2'd0,2'd1}] = vec_pe0_x1_o;
                        lvec_dataI_n[{2'd0,2'd1}] = vec_pe0_y1_o;
                        lvec_dataR_n[{2'd1,2'd0}] = vec_pe1_x0_o;
                        lvec_dataI_n[{2'd1,2'd0}] = vec_pe1_y0_o;
                        lvec_dataR_n[{2'd1,2'd1}] = vec_pe1_x1_o;
                        lvec_dataI_n[{2'd1,2'd1}] = vec_pe1_y1_o;
                        vec_pe0_x0_i = vec_pe0_x0_o;
                        vec_pe0_y0_i = vec_pe0_y0_o;
                        vec_pe0_x1_i = vec_pe0_x1_o;
                        vec_pe0_y1_i = vec_pe0_y1_o;
                        vec_pe1_x0_i = vec_pe1_x0_o;
                        vec_pe1_y0_i = vec_pe1_y0_o;
                        vec_pe1_x1_i = vec_pe1_x1_o;
                        vec_pe1_y1_i = vec_pe1_y1_o;
                    end

                    7'd5: begin 
                        inv_i = 0;
                        vec_pe0_valid = 2'b11;
                        vec_pe1_valid = 2'b11;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                        lvec_dataR_n[{2'd2,2'd0}] = vec_pe0_x0_o;
                        lvec_dataI_n[{2'd2,2'd0}] = vec_pe0_y0_o;
                        lvec_dataR_n[{2'd2,2'd1}] = vec_pe0_x1_o;
                        lvec_dataI_n[{2'd2,2'd1}] = vec_pe0_y1_o;
                        lvec_dataR_n[{2'd3,2'd0}] = vec_pe1_x0_o;
                        lvec_dataI_n[{2'd3,2'd0}] = vec_pe1_y0_o;
                        lvec_dataR_n[{2'd3,2'd1}] = vec_pe1_x1_o;
                        lvec_dataI_n[{2'd3,2'd1}] = vec_pe1_y1_o;
                        vec_pe0_x0_i = vec_pe0_x0_o;
                        vec_pe0_y0_i = vec_pe0_y0_o;
                        vec_pe0_x1_i = vec_pe0_x1_o;
                        vec_pe0_y1_i = vec_pe0_y1_o;
                        vec_pe1_x0_i = vec_pe1_x0_o;
                        vec_pe1_y0_i = vec_pe1_y0_o;
                        vec_pe1_x1_i = vec_pe1_x1_o;
                        vec_pe1_y1_i = vec_pe1_y1_o;
                    end
                    7'd6: begin
                        inv_i = 0;
                        vec_pe0_valid = 2'b11;
                        vec_pe1_valid = 2'b11;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                        lvec_dataR_n[{2'd0,2'd2}] = vec_pe0_x0_o;
                        lvec_dataI_n[{2'd0,2'd2}] = vec_pe0_y0_o;
                        lvec_dataR_n[{2'd0,2'd3}] = vec_pe0_x1_o;
                        lvec_dataI_n[{2'd0,2'd3}] = vec_pe0_y1_o;
                        lvec_dataR_n[{2'd1,2'd2}] = vec_pe1_x0_o;
                        lvec_dataI_n[{2'd1,2'd2}] = vec_pe1_y0_o;
                        lvec_dataR_n[{2'd1,2'd3}] = vec_pe1_x1_o;
                        lvec_dataI_n[{2'd1,2'd3}] = vec_pe1_y1_o;
                        vec_pe0_x0_i = vec_pe0_x1_o; //Reverse
                        vec_pe0_y0_i = vec_pe0_y1_o; //order
                        vec_pe0_x1_i = vec_pe0_x0_o; //row 3 first
                        vec_pe0_y1_i = vec_pe0_y0_o; //row 2 second
                        vec_pe1_x0_i = vec_pe1_x1_o; //!!!!!!!
                        vec_pe1_y0_i = vec_pe1_y1_o;
                        vec_pe1_x1_i = vec_pe1_x0_o;
                        vec_pe1_y1_i = vec_pe1_y0_o;
                    end
                    7'd7: begin
                        inv_i = 0;
                        vec_pe0_valid = 2'b11;
                        vec_pe1_valid = 2'b11;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                        lvec_dataR_n[{2'd2,2'd2}] = vec_pe0_x0_o;
                        lvec_dataI_n[{2'd2,2'd2}] = vec_pe0_y0_o;
                        lvec_dataR_n[{2'd2,2'd3}] = vec_pe0_x1_o;
                        lvec_dataI_n[{2'd2,2'd3}] = vec_pe0_y1_o;
                        lvec_dataR_n[{2'd3,2'd2}] = vec_pe1_x0_o;
                        lvec_dataI_n[{2'd3,2'd2}] = vec_pe1_y0_o;
                        lvec_dataR_n[{2'd3,2'd3}] = vec_pe1_x1_o;
                        lvec_dataI_n[{2'd3,2'd3}] = vec_pe1_y1_o;
                        vec_pe0_x0_i = vec_pe0_x1_o; //Reverse
                        vec_pe0_y0_i = vec_pe0_y1_o; //order
                        vec_pe0_x1_i = vec_pe0_x0_o; //row 3 first
                        vec_pe0_y1_i = vec_pe0_y0_o; //row 2 second
                        vec_pe1_x0_i = vec_pe1_x1_o; //!!!!!!!
                        vec_pe1_y0_i = vec_pe1_y1_o;
                        vec_pe1_x1_i = vec_pe1_x0_o;
                        vec_pe1_y1_i = vec_pe1_y0_o;
                    end
                    7'd8: begin
                        vec_pe0_valid = 2'b00;
                        vec_pe1_valid = 2'b00;
                        lvec_dataR_n[{2'd0,2'd0}] = vec_pe0_x0_o;
                        lvec_dataI_n[{2'd0,2'd0}] = vec_pe0_y0_o;
                        lvec_dataR_n[{2'd0,2'd1}] = vec_pe0_x1_o;
                        lvec_dataI_n[{2'd0,2'd1}] = vec_pe0_y1_o;
                        lvec_dataR_n[{2'd1,2'd0}] = vec_pe1_x0_o;
                        lvec_dataI_n[{2'd1,2'd0}] = vec_pe1_y0_o;
                        lvec_dataR_n[{2'd1,2'd1}] = vec_pe1_x1_o;
                        lvec_dataI_n[{2'd1,2'd1}] = vec_pe1_y1_o;
                    end
                    7'd9: begin
                        vec_pe0_valid = 2'b00;
                        vec_pe1_valid = 2'b00;
                        lvec_dataR_n[{2'd2,2'd0}] = vec_pe0_x0_o;
                        lvec_dataI_n[{2'd2,2'd0}] = vec_pe0_y0_o;
                        lvec_dataR_n[{2'd2,2'd1}] = vec_pe0_x1_o;
                        lvec_dataI_n[{2'd2,2'd1}] = vec_pe0_y1_o;
                        lvec_dataR_n[{2'd3,2'd0}] = vec_pe1_x0_o;
                        lvec_dataI_n[{2'd3,2'd0}] = vec_pe1_y0_o;
                        lvec_dataR_n[{2'd3,2'd1}] = vec_pe1_x1_o;
                        lvec_dataI_n[{2'd3,2'd1}] = vec_pe1_y1_o;
                    end
                    7'd10: begin
                        vec_pe0_valid = 2'b11;
                        vec_pe1_valid = 2'b11;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                        lvec_dataR_n[{2'd0, 2'd2}] = vec_pe0_x1_o;
                        lvec_dataI_n[{2'd0, 2'd2}] = vec_pe0_y1_o;
                        lvec_dataR_n[{2'd0, 2'd3}] = vec_pe0_x0_o;
                        lvec_dataI_n[{2'd0, 2'd3}] = vec_pe0_y0_o;
                        lvec_dataR_n[{2'd1, 2'd2}] = vec_pe1_x1_o;
                        lvec_dataI_n[{2'd1, 2'd2}] = vec_pe1_y1_o;
                        lvec_dataR_n[{2'd1, 2'd3}] = vec_pe1_x0_o;
                        lvec_dataI_n[{2'd1, 2'd3}] = vec_pe1_y0_o;
                        vec_pe0_x0_i = lvec_dataR[{2'd0,2'd0}];
                        vec_pe0_y0_i = lvec_dataI[{2'd0,2'd0}];
                        vec_pe0_x1_i = vec_pe0_x0_o;
                        vec_pe0_y1_i = vec_pe0_y0_o;
                        vec_pe1_x0_i = lvec_dataR[{2'd1,2'd0}];
                        vec_pe1_y0_i = lvec_dataI[{2'd1,2'd0}];
                        vec_pe1_x1_i = vec_pe1_x0_o;
                        vec_pe1_y1_i = vec_pe1_y0_o;
                    end
                    7'd11: begin
                        inv_i = 0;
                        vec_pe0_valid = 2'b11;
                        vec_pe1_valid = 2'b11;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                        lvec_dataR_n[{2'd2,2'd2}] = vec_pe0_x1_o;
                        lvec_dataI_n[{2'd2,2'd2}] = vec_pe0_y1_o;
                        lvec_dataR_n[{2'd2,2'd3}] = vec_pe0_x0_o;
                        lvec_dataI_n[{2'd2,2'd3}] = vec_pe0_y0_o;
                        lvec_dataR_n[{2'd3,2'd2}] = vec_pe1_x1_o;
                        lvec_dataI_n[{2'd3,2'd2}] = vec_pe1_y1_o;
                        lvec_dataR_n[{2'd3,2'd3}] = vec_pe1_x0_o;
                        lvec_dataI_n[{2'd3,2'd3}] = vec_pe1_y0_o;
                        vec_pe0_x0_i = lvec_dataR[{2'd2,2'd0}];
                        vec_pe0_y0_i = lvec_dataI[{2'd2,2'd0}];
                        vec_pe0_x1_i = vec_pe0_x0_o;
                        vec_pe0_y1_i = vec_pe0_y0_o;
                        vec_pe1_x0_i = lvec_dataR[{2'd3,2'd0}];
                        vec_pe1_y0_i = lvec_dataI[{2'd3,2'd0}];
                        vec_pe1_x1_i = vec_pe1_x0_o;
                        vec_pe1_y1_i = vec_pe1_y0_o;
                    end
                    7'd12: begin
                        vec_pe0_valid = 2'b00;
                        vec_pe1_valid = 2'b00;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                    end
                    7'd13: begin
                        vec_pe0_valid = 2'b00;
                        vec_pe1_valid = 2'b00;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                    end
                    7'd14: begin
                        vec_pe0_valid = 2'b11;
                        vec_pe1_valid = 2'b11;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                        lvec_dataR_n[{2'd0,2'd0}] = vec_pe0_x0_o;
                        lvec_dataI_n[{2'd0,2'd0}] = vec_pe0_y0_o;
                        lvec_dataR_n[{2'd0,2'd3}] = vec_pe0_x1_o;
                        lvec_dataI_n[{2'd0,2'd3}] = vec_pe0_y1_o;
                        lvec_dataR_n[{2'd1,2'd0}] = vec_pe1_x0_o;
                        lvec_dataI_n[{2'd1,2'd0}] = vec_pe1_y0_o;
                        lvec_dataR_n[{2'd1,2'd3}] = vec_pe1_x1_o;
                        lvec_dataI_n[{2'd1,2'd3}] = vec_pe1_y1_o;
                    end
                    7'd15: begin
                        inv_i = 0;
                        vec_pe0_valid = 2'b11;
                        vec_pe1_valid = 2'b11;
                        vec_pe0_scheme = COMPLEX_ROTATE;
                        vec_pe1_scheme = COMPLEX_ROTATE;
                        lvec_dataR_n[{2'd2,2'd0}] = vec_pe0_x0_o;
                        lvec_dataI_n[{2'd2,2'd0}] = vec_pe0_y0_o;
                        lvec_dataR_n[{2'd2,2'd3}] = vec_pe0_x1_o;
                        lvec_dataI_n[{2'd2,2'd3}] = vec_pe0_y1_o;
                        lvec_dataR_n[{2'd3,2'd0}] = vec_pe1_x0_o;
                        lvec_dataI_n[{2'd3,2'd0}] = vec_pe1_y0_o;
                        lvec_dataR_n[{2'd3,2'd3}] = vec_pe1_x1_o;
                        lvec_dataI_n[{2'd3,2'd3}] = vec_pe1_y1_o;
                        vec_pe0_x0_i = rvec_dataR[{2'd0,2'd1}];
                        vec_pe0_y0_i = rvec_dataI[{2'd0,2'd1}];
                        vec_pe0_x1_i = rvec_dataR[{2'd0,2'd2}];
                        vec_pe0_y1_i = rvec_dataR[{2'd0,2'd2}];
                        vec_pe1_x0_i = rvec_dataR[{2'd1,2'd1}];
                        vec_pe1_y0_i = rvec_dataI[{2'd1,2'd1}];
                        vec_pe1_x1_i = rvec_dataR[{2'd1,2'd2}];
                        vec_pe1_y1_i = rvec_dataI[{2'd1,2'd2}];
                    end
                    7'd16: begin
                        inv_i = 0;
                        vec_pe0_valid = 2'b11;
                        vec_pe1_valid = 2'b11;
                        vec_pe0_scheme = COMPLEX_ROTATE;
                        vec_pe1_scheme = COMPLEX_ROTATE;
                        vec_pe0_x0_i = rvec_dataR[{2'd2,2'd1}];
                        vec_pe0_y0_i = rvec_dataI[{2'd2,2'd1}];
                        vec_pe0_x1_i = rvec_dataR[{2'd2,2'd2}];
                        vec_pe0_y1_i = rvec_dataI[{2'd2,2'd2}];
                        vec_pe1_x0_i = rvec_dataR[{2'd3,2'd1}];
                        vec_pe1_y0_i = rvec_dataI[{2'd3,2'd1}];
                        vec_pe1_x1_i = rvec_dataR[{2'd3,2'd2}];
                        vec_pe1_y1_i = rvec_dataI[{2'd3,2'd2}];
                    end
                    7'd17: begin
                        inv_i = 0;
                        vec_pe0_valid = 2'b01;
                        vec_pe1_valid = 2'b01;
                        vec_pe0_scheme = COMPLEX_ROTATE;
                        vec_pe1_scheme = COMPLEX_ROTATE;
                        vec_pe0_x0_i = rvec_dataR[{2'd0,2'd3}];
                        vec_pe0_y0_i = rvec_dataI[{2'd0,2'd3}];
                        vec_pe1_x0_i = rvec_dataR[{2'd1,2'd3}]; 
                        vec_pe1_y0_i = rvec_dataI[{2'd1,2'd3}]; 
                    end
                    7'd18: begin
                        inv_i = 0;
                        vec_pe0_valid = 2'b01;
                        vec_pe1_valid = 2'b01;
                        vec_pe0_scheme = COMPLEX_ROTATE;
                        vec_pe1_scheme = COMPLEX_ROTATE;
                        vec_pe0_x0_i = rvec_dataR[{2'd2,2'd3}];
                        vec_pe0_y0_i = rvec_dataI[{2'd2,2'd3}];
                        vec_pe1_x0_i = rvec_dataR[{2'd3,2'd3}]; 
                        vec_pe1_y0_i = rvec_dataI[{2'd3,2'd3}]; 
                    end
                    7'd19: begin
                        inv_i = 0;
                        vec_pe0_valid = 2'b11;
                        vec_pe1_valid = 2'b11;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                        rvec_dataR_n[{2'd0,2'd1}] = vec_pe0_x0_o;
                        rvec_dataI_n[{2'd0,2'd1}] = vec_pe0_y0_o;
                        rvec_dataR_n[{2'd0,2'd2}] = vec_pe0_x1_o;
                        rvec_dataI_n[{2'd0,2'd2}] = vec_pe0_y1_o;
                        rvec_dataR_n[{2'd1,2'd1}] = vec_pe1_x0_o;
                        rvec_dataI_n[{2'd1,2'd1}] = vec_pe1_y0_o;
                        rvec_dataR_n[{2'd1,2'd2}] = vec_pe1_x1_o;
                        rvec_dataI_n[{2'd1,2'd2}] = vec_pe1_y1_o;
                        vec_pe0_x0_i = vec_pe0_x0_o;
                        vec_pe0_y0_i = vec_pe0_y0_o;
                        vec_pe0_x1_i = vec_pe0_x1_o;
                        vec_pe0_y1_i = vec_pe0_y1_o;
                        vec_pe1_x0_i = vec_pe1_x0_o;
                        vec_pe1_y0_i = vec_pe1_y0_o;
                        vec_pe1_x1_i = vec_pe1_x1_o;
                        vec_pe1_y1_i = vec_pe1_y1_o;
                    end
                    7'd20: begin 
                        inv_i = 0;
                        vec_pe0_valid = 2'b11;
                        vec_pe1_valid = 2'b11;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                        rvec_dataR_n[{2'd2,2'd1}] = vec_pe0_x0_o;
                        rvec_dataI_n[{2'd2,2'd1}] = vec_pe0_y0_o;
                        rvec_dataR_n[{2'd2,2'd2}] = vec_pe0_x1_o;
                        rvec_dataI_n[{2'd2,2'd2}] = vec_pe0_y1_o;
                        rvec_dataR_n[{2'd3,2'd1}] = vec_pe1_x0_o;
                        rvec_dataI_n[{2'd3,2'd1}] = vec_pe1_y0_o;
                        rvec_dataR_n[{2'd3,2'd2}] = vec_pe1_x1_o;
                        rvec_dataI_n[{2'd3,2'd2}] = vec_pe1_y1_o;
                        vec_pe0_x0_i = vec_pe0_x0_o;
                        vec_pe0_y0_i = vec_pe0_y0_o;
                        vec_pe0_x1_i = vec_pe0_x1_o;
                        vec_pe0_y1_i = vec_pe0_y1_o;
                        vec_pe1_x0_i = vec_pe1_x0_o;
                        vec_pe1_y0_i = vec_pe1_y0_o;
                        vec_pe1_x1_i = vec_pe1_x1_o;
                        vec_pe1_y1_i = vec_pe1_y1_o;
                    end
                    7'd21: begin
                        vec_pe0_valid = 2'b00;
                        vec_pe1_valid = 2'b00;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                        rvec_dataR_n[{2'd0,2'd3}] = vec_pe0_x0_o;
                        rvec_dataI_n[{2'd0,2'd3}] = vec_pe0_y0_o;
                        rvec_dataR_n[{2'd1,2'd3}] = vec_pe1_x0_o; 
                        rvec_dataI_n[{2'd1,2'd3}] = vec_pe1_y0_o; 
                    end
                    7'd22: begin
                        vec_pe0_valid = 2'b00;
                        vec_pe1_valid = 2'b00;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                        rvec_dataR_n[{2'd2,2'd3}] = vec_pe0_x0_o;
                        rvec_dataI_n[{2'd2,2'd3}] = vec_pe0_y0_o;
                        rvec_dataR_n[{2'd3,2'd3}] = vec_pe1_x0_o; 
                        rvec_dataI_n[{2'd3,2'd3}] = vec_pe1_y0_o; 
                    end
                    7'd23: begin
                        inv_i = 0;
                        vec_pe0_valid = 2'b11;
                        vec_pe1_valid = 2'b11;
                        vec_pe0_scheme = REAL_NULLIFIED;
                        vec_pe1_scheme = RELATED_ROTATE;
                        rvec_dataR_n[{2'd0,2'd1}] = vec_pe0_x0_o;
                        rvec_dataI_n[{2'd0,2'd1}] = vec_pe0_y0_o;
                        rvec_dataR_n[{2'd0,2'd2}] = vec_pe0_x1_o;
                        rvec_dataI_n[{2'd0,2'd2}] = vec_pe0_y1_o;
                        rvec_dataR_n[{2'd1,2'd1}] = vec_pe1_x0_o;
                        rvec_dataI_n[{2'd1,2'd1}] = vec_pe1_y0_o;
                        rvec_dataR_n[{2'd1,2'd2}] = vec_pe1_x1_o;
                        rvec_dataI_n[{2'd1,2'd2}] = vec_pe1_y1_o;
                        vec_pe0_x0_i = vec_pe0_x0_o;
                        vec_pe0_y0_i = vec_pe0_y0_o;
                        vec_pe0_x1_i = rvec_dataR[{2'd0,2'd3}];
                        vec_pe0_y1_i = rvec_dataI[{2'd0,2'd3}];
                        vec_pe1_x0_i = vec_pe1_x0_o;
                        vec_pe1_y0_i = vec_pe1_y0_o;
                        vec_pe1_x1_i = rvec_dataR[{2'd1,2'd3}];
                        vec_pe1_y1_i = rvec_dataI[{2'd1,2'd3}];
                    end
                    7'd24: begin 
                        inv_i = 0;
                        vec_pe0_valid = 2'b11;
                        vec_pe1_valid = 2'b11;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                        rvec_dataR_n[{2'd2,2'd1}] = vec_pe0_x0_o;
                        rvec_dataI_n[{2'd2,2'd1}] = vec_pe0_y0_o;
                        rvec_dataR_n[{2'd2,2'd2}] = vec_pe0_x1_o;
                        rvec_dataI_n[{2'd2,2'd2}] = vec_pe0_y1_o;
                        rvec_dataR_n[{2'd3,2'd1}] = vec_pe1_x0_o;
                        rvec_dataI_n[{2'd3,2'd1}] = vec_pe1_y0_o;
                        rvec_dataR_n[{2'd3,2'd2}] = vec_pe1_x1_o;
                        rvec_dataI_n[{2'd3,2'd2}] = vec_pe1_y1_o;
                        vec_pe0_x0_i = vec_pe0_x0_o;
                        vec_pe0_y0_i = vec_pe0_y0_o;
                        vec_pe0_x1_i = rvec_dataR[{2'd2,2'd3}];
                        vec_pe0_y1_i = rvec_dataI[{2'd2,2'd3}];
                        vec_pe1_x0_i = vec_pe1_x0_o;
                        vec_pe1_y0_i = vec_pe1_y0_o;
                        vec_pe1_x1_i = rvec_dataR[{2'd3,2'd3}];
                        vec_pe1_y1_i = rvec_dataI[{2'd3,2'd3}];
                    end
                    7'd25: begin
                        vec_pe0_valid = 2'b00;
                        vec_pe1_valid = 2'b00;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                    end
                    7'd26: begin
                        vec_pe0_valid = 2'b00;
                        vec_pe1_valid = 2'b00;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                    end
                    7'd27: begin
                        vec_pe0_valid = 2'b00;
                        vec_pe1_valid = 2'b00;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                        rvec_dataR_n[{2'd0,2'd1}] = vec_pe0_x0_o;
                        rvec_dataI_n[{2'd0,2'd1}] = vec_pe0_y0_o;
                        rvec_dataR_n[{2'd0,2'd3}] = vec_pe0_x1_o;
                        rvec_dataI_n[{2'd0,2'd3}] = vec_pe0_y1_o;
                        rvec_dataR_n[{2'd1,2'd1}] = vec_pe1_x0_o;
                        rvec_dataI_n[{2'd1,2'd1}] = vec_pe1_y0_o;
                        rvec_dataR_n[{2'd1,2'd3}] = vec_pe1_x1_o;
                        rvec_dataI_n[{2'd1,2'd3}] = vec_pe1_y1_o;
                    end
                    7'd28: begin 
                        inv_i = 1;
                        vec_pe0_valid = 2'b11;
                        vec_pe1_valid = 2'b11;
                        vec_pe0_scheme = COMPLEX_ROTATE;
                        vec_pe1_scheme = COMPLEX_ROTATE;
                        rvec_dataR_n[{2'd2,2'd1}] = vec_pe0_x0_o;
                        rvec_dataI_n[{2'd2,2'd1}] = vec_pe0_y0_o;
                        rvec_dataR_n[{2'd2,2'd3}] = vec_pe0_x1_o;
                        rvec_dataI_n[{2'd2,2'd3}] = vec_pe0_y1_o;
                        rvec_dataR_n[{2'd3,2'd1}] = vec_pe1_x0_o;
                        rvec_dataI_n[{2'd3,2'd1}] = vec_pe1_y0_o;
                        rvec_dataR_n[{2'd3,2'd3}] = vec_pe1_x1_o;
                        rvec_dataI_n[{2'd3,2'd3}] = vec_pe1_y1_o;
                        vec_pe0_x0_i = lvec_dataR[{2'd0,2'd1}];
                        vec_pe0_y0_i = lvec_dataI[{2'd0,2'd1}];
                        vec_pe0_x1_i = lvec_dataR[{2'd0,2'd2}];
                        vec_pe0_y1_i = lvec_dataI[{2'd0,2'd2}];
                        vec_pe1_x0_i = lvec_dataR[{2'd1,2'd1}];
                        vec_pe1_y0_i = lvec_dataI[{2'd1,2'd1}];
                        vec_pe1_x1_i = lvec_dataR[{2'd1,2'd2}];
                        vec_pe1_y1_i = lvec_dataI[{2'd1,2'd2}];
                    end
                    7'd29: begin 
                        inv_i = 1;
                        vec_pe0_valid = 2'b11;
                        vec_pe1_valid = 2'b11;
                        vec_pe0_scheme = COMPLEX_ROTATE;
                        vec_pe1_scheme = COMPLEX_ROTATE;
                        vec_pe0_x0_i = lvec_dataR[{2'd2,2'd1}];
                        vec_pe0_y0_i = lvec_dataI[{2'd2,2'd1}];
                        vec_pe0_x1_i = lvec_dataR[{2'd2,2'd2}];
                        vec_pe0_y1_i = lvec_dataI[{2'd2,2'd2}];
                        vec_pe1_x0_i = lvec_dataR[{2'd3,2'd1}];
                        vec_pe1_y0_i = lvec_dataI[{2'd3,2'd1}];
                        vec_pe1_x1_i = lvec_dataR[{2'd3,2'd2}];
                        vec_pe1_y1_i = lvec_dataI[{2'd3,2'd2}];
                    end
                    7'd30: begin
                        inv_i = 1;
                        vec_pe0_valid = 2'b01;
                        vec_pe1_valid = 2'b01;
                        vec_pe0_scheme = COMPLEX_ROTATE;
                        vec_pe1_scheme = COMPLEX_ROTATE;
                        vec_pe0_x0_i = lvec_dataR[{2'd0,2'd3}];
                        vec_pe0_y0_i = lvec_dataI[{2'd0,2'd3}];
                        vec_pe0_x1_i = 0;
                        vec_pe0_y1_i = 0;
                        vec_pe1_x0_i = lvec_dataR[{2'd1,2'd3}];
                        vec_pe1_y0_i = lvec_dataI[{2'd1,2'd3}];
                        vec_pe1_x1_i = 0;
                        vec_pe1_y1_i = 0;
                    end
                    7'd31: begin
                        inv_i = 1;
                        vec_pe0_valid = 2'b01;
                        vec_pe1_valid = 2'b01;
                        vec_pe0_scheme = COMPLEX_ROTATE;
                        vec_pe1_scheme = COMPLEX_ROTATE;
                        vec_pe0_x0_i = lvec_dataR[{2'd2,2'd3}];
                        vec_pe0_y0_i = lvec_dataI[{2'd2,2'd3}];
                        vec_pe0_x1_i = 0;
                        vec_pe0_y1_i = 0;
                        vec_pe1_x0_i = lvec_dataR[{2'd3,2'd3}];
                        vec_pe1_y0_i = lvec_dataI[{2'd3,2'd3}];
                        vec_pe1_x1_i = 0;
                        vec_pe1_y1_i = 0;
                    end
                    7'd32: begin 
                        inv_i = 0;
                        vec_pe0_valid = 2'b11;
                        vec_pe1_valid = 2'b11;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                        lvec_dataR_n[{2'd0,2'd1}] = vec_pe0_x0_o;
                        lvec_dataI_n[{2'd0,2'd1}] = vec_pe0_y0_o;
                        lvec_dataR_n[{2'd0,2'd2}] = vec_pe0_x1_o;
                        lvec_dataI_n[{2'd0,2'd2}] = vec_pe0_y1_o;
                        lvec_dataR_n[{2'd1,2'd1}] = vec_pe1_x0_o;
                        lvec_dataI_n[{2'd1,2'd1}] = vec_pe1_y0_o;
                        lvec_dataR_n[{2'd1,2'd2}] = vec_pe1_x1_o;
                        lvec_dataI_n[{2'd1,2'd2}] = vec_pe1_y1_o;
                        vec_pe0_x0_i = vec_pe0_x0_o;
                        vec_pe0_y0_i = vec_pe0_y0_o;
                        vec_pe0_x1_i = vec_pe0_x1_o;
                        vec_pe0_y1_i = vec_pe0_y1_o;
                        vec_pe1_x0_i = vec_pe1_x0_o;
                        vec_pe1_y0_i = vec_pe1_y0_o;
                        vec_pe1_x1_i = vec_pe1_x1_o;
                        vec_pe1_y1_i = vec_pe1_y1_o;
                    end
                    7'd33: begin 
                        inv_i = 0;
                        vec_pe0_valid = 2'b11;
                        vec_pe1_valid = 2'b11;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                        lvec_dataR_n[{2'd2,2'd1}] = vec_pe0_x0_o;
                        lvec_dataI_n[{2'd2,2'd1}] = vec_pe0_y0_o;
                        lvec_dataR_n[{2'd2,2'd2}] = vec_pe0_x1_o;
                        lvec_dataI_n[{2'd2,2'd2}] = vec_pe0_y1_o;
                        lvec_dataR_n[{2'd3,2'd1}] = vec_pe1_x0_o;
                        lvec_dataI_n[{2'd3,2'd1}] = vec_pe1_y0_o;
                        lvec_dataR_n[{2'd3,2'd2}] = vec_pe1_x1_o;
                        lvec_dataI_n[{2'd3,2'd2}] = vec_pe1_y1_o;
                        vec_pe0_x0_i = vec_pe0_x0_o;
                        vec_pe0_y0_i = vec_pe0_y0_o;
                        vec_pe0_x1_i = vec_pe0_x1_o;
                        vec_pe0_y1_i = vec_pe0_y1_o;
                        vec_pe1_x0_i = vec_pe1_x0_o;
                        vec_pe1_y0_i = vec_pe1_y0_o;
                        vec_pe1_x1_i = vec_pe1_x1_o;
                        vec_pe1_y1_i = vec_pe1_y1_o;
                    end
                    7'd34: begin 
                        vec_pe0_valid = 2'b00;
                        vec_pe1_valid = 2'b00;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                        lvec_dataR_n[{2'd0,2'd3}] = vec_pe0_x0_o;
                        lvec_dataI_n[{2'd0,2'd3}] = vec_pe0_y0_o;
                        lvec_dataR_n[{2'd1,2'd3}] = vec_pe1_x0_o;
                        lvec_dataI_n[{2'd1,2'd3}] = vec_pe1_y0_o;
                    end 
                    7'd35: begin 
                        vec_pe0_valid = 2'b00;
                        vec_pe1_valid = 2'b00;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                        lvec_dataR_n[{2'd2,2'd3}] = vec_pe0_x0_o;
                        lvec_dataI_n[{2'd2,2'd3}] = vec_pe0_y0_o;
                        lvec_dataR_n[{2'd3,2'd3}] = vec_pe1_x0_o;
                        lvec_dataI_n[{2'd3,2'd3}] = vec_pe1_y0_o;
                    end
                    7'd36: begin 
                        inv_i = 0;
                        vec_pe0_valid = 2'b11;
                        vec_pe1_valid = 2'b11;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                        lvec_dataR_n[{2'd0,2'd1}] = vec_pe0_x0_o;
                        lvec_dataI_n[{2'd0,2'd1}] = vec_pe0_y0_o;
                        lvec_dataR_n[{2'd0,2'd2}] = vec_pe0_x1_o;
                        lvec_dataI_n[{2'd0,2'd2}] = vec_pe0_y1_o;
                        lvec_dataR_n[{2'd1,2'd1}] = vec_pe1_x0_o;
                        lvec_dataI_n[{2'd1,2'd1}] = vec_pe1_y0_o;
                        lvec_dataR_n[{2'd1,2'd2}] = vec_pe1_x1_o;
                        lvec_dataI_n[{2'd1,2'd2}] = vec_pe1_y1_o;
                        vec_pe0_x0_i = vec_pe0_x0_o;
                        vec_pe0_y0_i = vec_pe0_y0_o;
                        vec_pe0_x1_i = lvec_dataR[{2'd0,2'd3}];
                        vec_pe0_y1_i = lvec_dataI[{2'd0,2'd3}];
                        vec_pe1_x0_i = vec_pe1_x0_o;
                        vec_pe1_y0_i = vec_pe1_y0_o;
                        vec_pe1_x1_i = lvec_dataR[{2'd1,2'd3}];
                        vec_pe1_y1_i = lvec_dataI[{2'd1,2'd3}];
                    end
                    7'd37: begin 
                        inv_i = 0;
                        vec_pe0_valid = 2'b11;
                        vec_pe1_valid = 2'b11;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                        lvec_dataR_n[{2'd2,2'd1}] = vec_pe0_x0_o;
                        lvec_dataI_n[{2'd2,2'd1}] = vec_pe0_y0_o;
                        lvec_dataR_n[{2'd2,2'd2}] = vec_pe0_x1_o;
                        lvec_dataI_n[{2'd2,2'd2}] = vec_pe0_y1_o;
                        lvec_dataR_n[{2'd3,2'd1}] = vec_pe1_x0_o;
                        lvec_dataI_n[{2'd3,2'd1}] = vec_pe1_y0_o;
                        lvec_dataR_n[{2'd3,2'd2}] = vec_pe1_x1_o;
                        lvec_dataI_n[{2'd3,2'd2}] = vec_pe1_y1_o;
                        vec_pe0_x0_i = vec_pe0_x0_o;
                        vec_pe0_y0_i = vec_pe0_y0_o;
                        vec_pe0_x1_i = lvec_dataR[{2'd2,2'd3}];
                        vec_pe0_y1_i = lvec_dataI[{2'd2,2'd3}];
                        vec_pe1_x0_i = vec_pe1_x0_o;
                        vec_pe1_y0_i = vec_pe1_y0_o;
                        vec_pe1_x1_i = lvec_dataR[{2'd3,2'd3}];
                        vec_pe1_y1_i = lvec_dataI[{2'd3,2'd3}];
                    end
                    7'd38: begin
                        vec_pe0_valid = 2'b00;
                        vec_pe1_valid = 2'b00;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                    end
                    7'd39: begin
                        vec_pe0_valid = 2'b00;
                        vec_pe1_valid = 2'b00;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                    end
                    7'd40: begin
                        vec_pe0_valid = 2'b00;
                        vec_pe1_valid = 2'b00;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                        lvec_dataR_n[{2'd0,2'd1}] = vec_pe0_x0_o;
                        lvec_dataI_n[{2'd0,2'd1}] = vec_pe0_y0_o;
                        lvec_dataR_n[{2'd0,2'd3}] = vec_pe0_x1_o;
                        lvec_dataI_n[{2'd0,2'd3}] = vec_pe0_y1_o;
                        lvec_dataR_n[{2'd1,2'd1}] = vec_pe1_x0_o;
                        lvec_dataI_n[{2'd1,2'd1}] = vec_pe1_y0_o;
                        lvec_dataR_n[{2'd1,2'd3}] = vec_pe1_x1_o;
                        lvec_dataI_n[{2'd1,2'd3}] = vec_pe1_y1_o;
                    end
                    7'd41: begin
                        inv_i = 0;
                        vec_pe0_valid = 2'b11;
                        vec_pe1_valid = 2'b11;
                        vec_pe0_scheme = COMPLEX_ROTATE;
                        vec_pe1_scheme = COMPLEX_ROTATE;
                        lvec_dataR_n[{2'd2,2'd1}] = vec_pe0_x0_o;
                        lvec_dataI_n[{2'd2,2'd1}] = vec_pe0_y0_o;
                        lvec_dataR_n[{2'd2,2'd3}] = vec_pe0_x1_o;
                        lvec_dataI_n[{2'd2,2'd3}] = vec_pe0_y1_o;
                        lvec_dataR_n[{2'd3,2'd1}] = vec_pe1_x0_o;
                        lvec_dataI_n[{2'd3,2'd1}] = vec_pe1_y0_o;
                        lvec_dataR_n[{2'd3,2'd3}] = vec_pe1_x1_o;
                        lvec_dataI_n[{2'd3,2'd3}] = vec_pe1_y1_o;
                        vec_pe0_x0_i = rvec_dataR[{2'd0,2'd2}];
                        vec_pe0_y0_i = rvec_dataI[{2'd0,2'd2}];
                        vec_pe0_x1_i = rvec_dataR[{2'd0,2'd3}];
                        vec_pe0_y1_i = rvec_dataI[{2'd0,2'd3}];
                        vec_pe1_x0_i = rvec_dataR[{2'd1,2'd2}];
                        vec_pe1_y0_i = rvec_dataI[{2'd1,2'd2}];
                        vec_pe1_x1_i = rvec_dataR[{2'd1,2'd3}];
                        vec_pe1_y1_i = rvec_dataI[{2'd1,2'd3}];
                    end

                    7'd42: begin
                        inv_i = 0;
                        vec_pe0_valid = 2'b11;
                        vec_pe1_valid = 2'b11;
                        vec_pe0_scheme = COMPLEX_ROTATE;
                        vec_pe1_scheme = COMPLEX_ROTATE;
                        vec_pe0_x0_i = rvec_dataR[{2'd2,2'd2}];
                        vec_pe0_y0_i = rvec_dataI[{2'd2,2'd2}];
                        vec_pe0_x1_i = rvec_dataR[{2'd2,2'd3}];
                        vec_pe0_y1_i = rvec_dataI[{2'd2,2'd3}];
                        vec_pe1_x0_i = rvec_dataR[{2'd3,2'd2}];
                        vec_pe1_y0_i = rvec_dataI[{2'd3,2'd2}];
                        vec_pe1_x1_i = rvec_dataR[{2'd3,2'd3}];
                        vec_pe1_y1_i = rvec_dataI[{2'd3,2'd3}];
                    end
                    7'd43: begin
                        vec_pe0_valid = 2'b00;
                        vec_pe1_valid = 2'b00;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                    end
                    7'd44: begin
                        vec_pe0_valid = 2'b00;
                        vec_pe1_valid = 2'b00;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                    end
                    7'd45: begin
                        inv_i = 0;
                        vec_pe0_valid = 2'b11;
                        vec_pe1_valid = 2'b11;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                        rvec_dataR_n[{2'd0,2'd2}] = vec_pe0_x0_o;
                        rvec_dataI_n[{2'd0,2'd2}] = vec_pe0_y0_o;
                        rvec_dataR_n[{2'd0,2'd3}] = vec_pe0_x1_o;
                        rvec_dataI_n[{2'd0,2'd3}] = vec_pe0_y1_o;
                        rvec_dataR_n[{2'd1,2'd2}] = vec_pe1_x0_o;
                        rvec_dataI_n[{2'd1,2'd2}] = vec_pe1_y0_o;
                        rvec_dataR_n[{2'd1,2'd3}] = vec_pe1_x1_o;
                        rvec_dataI_n[{2'd1,2'd3}] = vec_pe1_y1_o;
                        vec_pe0_x0_i = vec_pe0_x0_o;
                        vec_pe0_y0_i = vec_pe0_y0_o;
                        vec_pe0_x1_i = vec_pe0_x1_o;
                        vec_pe0_y1_i = vec_pe0_y1_o;
                        vec_pe1_x0_i = vec_pe1_x0_o;
                        vec_pe1_y0_i = vec_pe1_y0_o;
                        vec_pe1_x1_i = vec_pe1_x1_o;
                        vec_pe1_y1_i = vec_pe1_y1_o;
                    end
                    7'd46: begin
                        inv_i = 0;
                        vec_pe0_valid = 2'b11;
                        vec_pe1_valid = 2'b11;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                        rvec_dataR_n[{2'd2,2'd2}] = vec_pe0_x0_o;
                        rvec_dataI_n[{2'd2,2'd2}] = vec_pe0_y0_o;
                        rvec_dataR_n[{2'd2,2'd3}] = vec_pe0_x1_o;
                        rvec_dataI_n[{2'd2,2'd3}] = vec_pe0_y1_o;
                        rvec_dataR_n[{2'd3,2'd2}] = vec_pe1_x0_o;
                        rvec_dataI_n[{2'd3,2'd2}] = vec_pe1_y0_o;
                        rvec_dataR_n[{2'd3,2'd3}] = vec_pe1_x1_o;
                        rvec_dataI_n[{2'd3,2'd3}] = vec_pe1_y1_o;
                        vec_pe0_x0_i = vec_pe0_x0_o;
                        vec_pe0_y0_i = vec_pe0_y0_o;
                        vec_pe0_x1_i = vec_pe0_x1_o;
                        vec_pe0_y1_i = vec_pe0_y1_o;
                        vec_pe1_x0_i = vec_pe1_x0_o;
                        vec_pe1_y0_i = vec_pe1_y0_o;
                        vec_pe1_x1_i = vec_pe1_x1_o;
                        vec_pe1_y1_i = vec_pe1_y1_o;
                    end
                    7'd47: begin
                        vec_pe0_valid = 2'b00;
                        vec_pe1_valid = 2'b00;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                    end
                    7'd48: begin
                        vec_pe0_valid = 2'b00;
                        vec_pe1_valid = 2'b00;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                    end
                    7'd49: begin
                        vec_pe0_valid = 2'b00;
                        vec_pe1_valid = 2'b00;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                        rvec_dataR_n[{2'd0,2'd2}] = vec_pe0_x0_o;
                        rvec_dataI_n[{2'd0,2'd2}] = vec_pe0_y0_o;
                        rvec_dataR_n[{2'd0,2'd3}] = vec_pe0_x1_o;
                        rvec_dataI_n[{2'd0,2'd3}] = vec_pe0_y1_o;
                        rvec_dataR_n[{2'd1,2'd2}] = vec_pe1_x0_o;
                        rvec_dataI_n[{2'd1,2'd2}] = vec_pe1_y0_o;
                        rvec_dataR_n[{2'd1,2'd3}] = vec_pe1_x1_o;
                        rvec_dataI_n[{2'd1,2'd3}] = vec_pe1_y1_o;
                    end
                    7'd50: begin
                        inv_i = 1;
                        vec_pe0_valid = 2'b11;
                        vec_pe1_valid = 2'b11;
                        vec_pe0_scheme = COMPLEX_ROTATE;
                        vec_pe1_scheme = COMPLEX_ROTATE;
                        rvec_dataR_n[{2'd2,2'd2}] = vec_pe0_x0_o;
                        rvec_dataI_n[{2'd2,2'd2}] = vec_pe0_y0_o;
                        rvec_dataR_n[{2'd2,2'd3}] = vec_pe0_x1_o;
                        rvec_dataI_n[{2'd2,2'd3}] = vec_pe0_y1_o;
                        rvec_dataR_n[{2'd3,2'd2}] = vec_pe1_x0_o;
                        rvec_dataI_n[{2'd3,2'd2}] = vec_pe1_y0_o;
                        rvec_dataR_n[{2'd3,2'd3}] = vec_pe1_x1_o;
                        rvec_dataI_n[{2'd3,2'd3}] = vec_pe1_y1_o;
                        vec_pe0_x0_i = lvec_dataR[{2'd0,2'd2}];
                        vec_pe0_y0_i = lvec_dataI[{2'd0,2'd2}];
                        vec_pe0_x1_i = lvec_dataR[{2'd0,2'd3}];
                        vec_pe0_y1_i = lvec_dataI[{2'd0,2'd3}];
                        vec_pe1_x0_i = lvec_dataR[{2'd1,2'd2}];
                        vec_pe1_y0_i = lvec_dataI[{2'd1,2'd2}];
                        vec_pe1_x1_i = lvec_dataR[{2'd1,2'd3}];
                        vec_pe1_y1_i = lvec_dataI[{2'd1,2'd3}];
                    end

                    7'd51: begin
                        inv_i = 1;
                        vec_pe0_valid = 2'b11;
                        vec_pe1_valid = 2'b11;
                        vec_pe0_scheme = COMPLEX_ROTATE;
                        vec_pe1_scheme = COMPLEX_ROTATE;
                        vec_pe0_x0_i = lvec_dataR[{2'd2,2'd2}];
                        vec_pe0_y0_i = lvec_dataI[{2'd2,2'd2}];
                        vec_pe0_x1_i = lvec_dataR[{2'd2,2'd3}];
                        vec_pe0_y1_i = lvec_dataI[{2'd2,2'd3}];
                        vec_pe1_x0_i = lvec_dataR[{2'd3,2'd2}];
                        vec_pe1_y0_i = lvec_dataI[{2'd3,2'd2}];
                        vec_pe1_x1_i = lvec_dataR[{2'd3,2'd3}];
                        vec_pe1_y1_i = lvec_dataI[{2'd3,2'd3}];
                    end
                    7'd52: begin
                        vec_pe0_valid = 2'b00;
                        vec_pe1_valid = 2'b00;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                    end
                    7'd53: begin
                        vec_pe0_valid = 2'b00;
                        vec_pe1_valid = 2'b00;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                    end
                    7'd54: begin
                        inv_i = 0;
                        vec_pe0_valid = 2'b11;
                        vec_pe1_valid = 2'b11;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                        lvec_dataR_n[{2'd0,2'd2}] = vec_pe0_x0_o;
                        lvec_dataI_n[{2'd0,2'd2}] = vec_pe0_y0_o;
                        lvec_dataR_n[{2'd0,2'd3}] = vec_pe0_x1_o;
                        lvec_dataI_n[{2'd0,2'd3}] = vec_pe0_y1_o;
                        lvec_dataR_n[{2'd1,2'd2}] = vec_pe1_x0_o;
                        lvec_dataI_n[{2'd1,2'd2}] = vec_pe1_y0_o;
                        lvec_dataR_n[{2'd1,2'd3}] = vec_pe1_x1_o;
                        lvec_dataI_n[{2'd1,2'd3}] = vec_pe1_y1_o;
                        vec_pe0_x0_i = vec_pe0_x0_o;
                        vec_pe0_y0_i = vec_pe0_y0_o;
                        vec_pe0_x1_i = vec_pe0_x1_o;
                        vec_pe0_y1_i = vec_pe0_y1_o;
                        vec_pe1_x0_i = vec_pe1_x0_o;
                        vec_pe1_y0_i = vec_pe1_y0_o;
                        vec_pe1_x1_i = vec_pe1_x1_o;
                        vec_pe1_y1_i = vec_pe1_y1_o;
                    end
                    7'd55: begin
                        inv_i = 0;
                        vec_pe0_valid = 2'b11;
                        vec_pe1_valid = 2'b11;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                        lvec_dataR_n[{2'd2,2'd2}] = vec_pe0_x0_o;
                        lvec_dataI_n[{2'd2,2'd2}] = vec_pe0_y0_o;
                        lvec_dataR_n[{2'd2,2'd3}] = vec_pe0_x1_o;
                        lvec_dataI_n[{2'd2,2'd3}] = vec_pe0_y1_o;
                        lvec_dataR_n[{2'd3,2'd2}] = vec_pe1_x0_o;
                        lvec_dataI_n[{2'd3,2'd2}] = vec_pe1_y0_o;
                        lvec_dataR_n[{2'd3,2'd3}] = vec_pe1_x1_o;
                        lvec_dataI_n[{2'd3,2'd3}] = vec_pe1_y1_o;
                        vec_pe0_x0_i = vec_pe0_x0_o;
                        vec_pe0_y0_i = vec_pe0_y0_o;
                        vec_pe0_x1_i = vec_pe0_x1_o;
                        vec_pe0_y1_i = vec_pe0_y1_o;
                        vec_pe1_x0_i = vec_pe1_x0_o;
                        vec_pe1_y0_i = vec_pe1_y0_o;
                        vec_pe1_x1_i = vec_pe1_x1_o;
                        vec_pe1_y1_i = vec_pe1_y1_o;
                    end

                    7'd56: begin
                        vec_pe0_valid = 2'b00;
                        vec_pe1_valid = 2'b00;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                    end
                    7'd57: begin
                        vec_pe0_valid = 2'b00;
                        vec_pe1_valid = 2'b00;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                    end
                    7'd58: begin
                        inv_i = 0;
                        vec_pe0_valid = 2'b01;
                        vec_pe1_valid = 2'b01;
                        vec_pe0_scheme = COMPLEX_ROTATE;
                        vec_pe1_scheme = COMPLEX_ROTATE;
                        lvec_dataR_n[{2'd0,2'd2}] = vec_pe0_x0_o;
                        lvec_dataI_n[{2'd0,2'd2}] = vec_pe0_y0_o;
                        lvec_dataR_n[{2'd0,2'd3}] = vec_pe0_x1_o;
                        lvec_dataI_n[{2'd0,2'd3}] = vec_pe0_y1_o;
                        lvec_dataR_n[{2'd1,2'd2}] = vec_pe1_x0_o;
                        lvec_dataI_n[{2'd1,2'd2}] = vec_pe1_y0_o;
                        lvec_dataR_n[{2'd1,2'd3}] = vec_pe1_x1_o;
                        lvec_dataI_n[{2'd1,2'd3}] = vec_pe1_y1_o;
                        vec_pe0_x0_i = rvec_dataR[{2'd0,2'd3}];
                        vec_pe0_y0_i = rvec_dataI[{2'd0,2'd3}];
                        vec_pe1_x0_i = rvec_dataR[{2'd1,2'd3}];
                        vec_pe1_y0_i = rvec_dataI[{2'd1,2'd3}];

                    end
                    7'd59: begin
                        inv_i = 0;
                        vec_pe0_valid = 2'b01;
                        vec_pe1_valid = 2'b01;
                        vec_pe0_scheme = COMPLEX_ROTATE;
                        vec_pe1_scheme = COMPLEX_ROTATE;
                        lvec_dataR_n[{2'd2,2'd2}] = vec_pe0_x0_o;
                        lvec_dataI_n[{2'd2,2'd2}] = vec_pe0_y0_o;
                        lvec_dataR_n[{2'd2,2'd3}] = vec_pe0_x1_o;
                        lvec_dataI_n[{2'd2,2'd3}] = vec_pe0_y1_o;
                        lvec_dataR_n[{2'd3,2'd2}] = vec_pe1_x0_o;
                        lvec_dataI_n[{2'd3,2'd2}] = vec_pe1_y0_o;
                        lvec_dataR_n[{2'd3,2'd3}] = vec_pe1_x1_o;
                        lvec_dataI_n[{2'd3,2'd3}] = vec_pe1_y1_o;
                        vec_pe0_x0_i = rvec_dataR[{2'd2,2'd3}];
                        vec_pe0_y0_i = rvec_dataI[{2'd2,2'd3}];
                        vec_pe1_x0_i = rvec_dataR[{2'd3,2'd3}];
                        vec_pe1_y0_i = rvec_dataI[{2'd3,2'd3}];
                    end

                    7'd60: begin
                        vec_pe0_valid = 2'b00;
                        vec_pe1_valid = 2'b00;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                    end
                    7'd61: begin
                        vec_pe0_valid = 2'b00;
                        vec_pe1_valid = 2'b00;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                    end
                    7'd62: begin
                        inv_i = 1;
                        vec_pe0_valid = 2'b01;
                        vec_pe1_valid = 2'b01;
                        vec_pe0_scheme = COMPLEX_ROTATE;
                        vec_pe1_scheme = COMPLEX_ROTATE;
                        rvec_dataR_n[{2'd0,2'd3}] = vec_pe0_x0_o;
                        rvec_dataI_n[{2'd0,2'd3}] = vec_pe0_y0_o;
                        rvec_dataR_n[{2'd1,2'd3}] = vec_pe1_x0_o;
                        rvec_dataI_n[{2'd1,2'd3}] = vec_pe1_y0_o;
                        vec_pe0_x0_i = lvec_dataR[{2'd0,2'd3}];
                        vec_pe0_y0_i = lvec_dataI[{2'd0,2'd3}];
                        vec_pe1_x0_i = lvec_dataR[{2'd1,2'd3}];
                        vec_pe1_y0_i = lvec_dataI[{2'd1,2'd3}];
                    end
                    7'd63: begin
                        inv_i = 1;
                        vec_pe0_valid = 2'b01;
                        vec_pe1_valid = 2'b01;
                        vec_pe0_scheme = COMPLEX_ROTATE;
                        vec_pe1_scheme = COMPLEX_ROTATE;
                        rvec_dataR_n[{2'd2,2'd3}] = vec_pe0_x0_o;
                        rvec_dataI_n[{2'd2,2'd3}] = vec_pe0_y0_o;
                        rvec_dataR_n[{2'd3,2'd3}] = vec_pe1_x0_o;
                        rvec_dataI_n[{2'd3,2'd3}] = vec_pe1_y0_o;
                        vec_pe0_x0_i = lvec_dataR[{2'd2,2'd3}];
                        vec_pe0_y0_i = lvec_dataI[{2'd2,2'd3}];
                        vec_pe1_x0_i = lvec_dataR[{2'd3,2'd3}];
                        vec_pe1_y0_i = lvec_dataI[{2'd3,2'd3}];
                    end

                    7'd64: begin
                        vec_pe0_valid = 2'b00;
                        vec_pe1_valid = 2'b00;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                    end
                    7'd65: begin
                        vec_pe0_valid = 2'b00;
                        vec_pe1_valid = 2'b00;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                    end
                    7'd66: begin
                        vec_pe0_valid = 2'b00;
                        vec_pe1_valid = 2'b00;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                        lvec_dataR_n[{2'd0,2'd3}] = vec_pe0_x0_o;
                        lvec_dataI_n[{2'd0,2'd3}] = vec_pe0_y0_o;
                        lvec_dataR_n[{2'd1,2'd3}] = vec_pe1_x0_o;
                        lvec_dataI_n[{2'd1,2'd3}] = vec_pe1_y0_o;
                    end
                    7'd67: begin
                        vec_pe0_valid = 2'b00;
                        vec_pe1_valid = 2'b00;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                        lvec_dataR_n[{2'd2,2'd3}] = vec_pe0_x0_o;
                        lvec_dataI_n[{2'd2,2'd3}] = vec_pe0_y0_o;
                        lvec_dataR_n[{2'd3,2'd3}] = vec_pe1_x0_o;
                        lvec_dataI_n[{2'd3,2'd3}] = vec_pe1_y0_o;
                    end
                    default: begin
                        vec_pe0_valid = 2'b00;
                        vec_pe1_valid = 2'b00;
                        vec_pe0_scheme = RELATED_ROTATE;
                        vec_pe1_scheme = RELATED_ROTATE;
                    end
                endcase
            end
            DIAG: begin
                valid_o_n = (diag_end) ? 1 : 0;
                case (DPHASE)
                    1'b0: begin
                        sw_num_n = sw_num;
                        case(cnt[1:0])

                            2'b00: begin
                                inv_i = 0;
                                vec_pe0_valid = 2'b11;
                                vec_pe1_valid = 2'b11;
                                vec_pe0_scheme = RELATED_ROTATE;
                                vec_pe1_scheme = RELATED_ROTATE;
                                vec_pe0_x0_i = rvec_dataR[{2'd0,2'd0}];
                                vec_pe0_y0_i = rvec_dataI[{2'd0,2'd0}];
                                vec_pe0_x1_i = rvec_dataR[{2'd0,2'd1}];
                                vec_pe0_y1_i = rvec_dataI[{2'd0,2'd1}];
                                vec_pe1_x0_i = rvec_dataR[{2'd1,2'd0}];
                                vec_pe1_y0_i = rvec_dataI[{2'd1,2'd0}];
                                vec_pe1_x1_i = rvec_dataR[{2'd1,2'd1}];
                                vec_pe1_y1_i = rvec_dataI[{2'd1,2'd1}];
                                DPHASE_N = 0;
                                cnt_n = cnt + 1;
                            end
                            2'b01: begin
                                inv_i = 0;
                                vec_pe0_valid = 2'b11;
                                vec_pe1_valid = 2'b11;
                                vec_pe0_scheme = RELATED_ROTATE;
                                vec_pe1_scheme = RELATED_ROTATE;
                                vec_pe0_x0_i = rvec_dataR[{2'd2,2'd0}];
                                vec_pe0_y0_i = rvec_dataI[{2'd2,2'd0}];
                                vec_pe0_x1_i = rvec_dataR[{2'd2,2'd1}];
                                vec_pe0_y1_i = rvec_dataI[{2'd2,2'd1}];
                                vec_pe1_x0_i = rvec_dataR[{2'd3,2'd0}];
                                vec_pe1_y0_i = rvec_dataI[{2'd3,2'd0}];
                                vec_pe1_x1_i = rvec_dataR[{2'd3,2'd1}];
                                vec_pe1_y1_i = rvec_dataI[{2'd3,2'd1}];
                                DPHASE_N = 0;
                                cnt_n = cnt + 1;
                            end
                            2'b10: begin
                                vec_pe0_valid = 2'b00;
                                vec_pe1_valid = 2'b00;
                                vec_pe0_scheme = RELATED_ROTATE;
                                vec_pe1_scheme = RELATED_ROTATE;
                                DPHASE_N = 0;
                                cnt_n = cnt + 1;
                            end
                            2'b11: begin
                                vec_pe0_valid = 2'b00;
                                vec_pe1_valid = 2'b00;
                                vec_pe0_scheme = RELATED_ROTATE;
                                vec_pe1_scheme = RELATED_ROTATE;
                                DPHASE_N = 1;
                                cnt_n = 0;
                            end
                        endcase

                    end
                    1'b1: begin
                        DPHASE_N = 1;
                        cnt_n = 0;
                        if(DIAG_STATE == 5'd19) begin
                            DIAG_STATE_N = 5'd0;
                            sw_num_n = sw_num + 1;
                        end
                        else begin
                            DIAG_STATE_N = DIAG_STATE + 1;
                            sw_num_n = sw_num;
                        end

                        case (DIAG_STATE[4:0])
                            5'd0: begin
                                inv_i = 0;
                                vec_pe0_valid = 2'b11;
                                vec_pe1_valid = 2'b11;
                                vec_pe0_scheme = RELATED_ROTATE;
                                vec_pe1_scheme = RELATED_ROTATE;
                                rvec_dataR_n[{2'd0,2'd0}] = vec_pe0_x0_o;
                                rvec_dataI_n[{2'd0,2'd0}] = vec_pe0_y0_o;
                                rvec_dataR_n[{2'd0,2'd1}] = vec_pe0_x1_o;
                                rvec_dataI_n[{2'd0,2'd1}] = vec_pe0_y1_o;
                                rvec_dataR_n[{2'd1,2'd0}] = vec_pe1_x0_o;
                                rvec_dataI_n[{2'd1,2'd0}] = vec_pe1_y0_o;
                                rvec_dataR_n[{2'd1,2'd1}] = vec_pe1_x1_o;
                                rvec_dataI_n[{2'd1,2'd1}] = vec_pe1_y1_o;
                                vec_pe0_x0_i = vec_pe0_x1_o;
                                vec_pe0_y0_i = vec_pe0_y1_o;
                                vec_pe0_x1_i = rvec_dataR[{2'd0,2'd2}];
                                vec_pe0_y1_i = rvec_dataI[{2'd0,2'd2}];
                                vec_pe1_x0_i = vec_pe1_x1_o;
                                vec_pe1_y0_i = vec_pe1_y1_o;
                                vec_pe1_x1_i = rvec_dataR[{2'd1,2'd2}];
                                vec_pe1_y1_i = rvec_dataI[{2'd1,2'd2}];
                            end
                            5'd1: begin
                                inv_i = 0;
                                vec_pe0_valid = 2'b11;
                                vec_pe1_valid = 2'b11;
                                vec_pe0_scheme = RELATED_ROTATE;
                                vec_pe1_scheme = RELATED_ROTATE;
                                rvec_dataR_n[{2'd2,2'd0}] = vec_pe0_x0_o;
                                rvec_dataI_n[{2'd2,2'd0}] = vec_pe0_y0_o;
                                rvec_dataR_n[{2'd2,2'd1}] = vec_pe0_x1_o;
                                rvec_dataI_n[{2'd2,2'd1}] = vec_pe0_y1_o;
                                rvec_dataR_n[{2'd3,2'd0}] = vec_pe1_x0_o;
                                rvec_dataI_n[{2'd3,2'd0}] = vec_pe1_y0_o;
                                rvec_dataR_n[{2'd3,2'd1}] = vec_pe1_x1_o;
                                rvec_dataI_n[{2'd3,2'd1}] = vec_pe1_y1_o;
                                vec_pe0_x0_i = vec_pe0_x1_o;
                                vec_pe0_y0_i = vec_pe0_y1_o;
                                vec_pe0_x1_i = rvec_dataR[{2'd2,2'd2}];
                                vec_pe0_y1_i = rvec_dataI[{2'd2,2'd2}];
                                vec_pe1_x0_i = vec_pe1_x1_o;
                                vec_pe1_y0_i = vec_pe1_y1_o;
                                vec_pe1_x1_i = rvec_dataR[{2'd3,2'd2}];
                                vec_pe1_y1_i = rvec_dataI[{2'd3,2'd2}];
                            end
                            
                            5'd4: begin
                                inv_i = 0;
                                vec_pe0_valid = 2'b11;
                                vec_pe1_valid = 2'b11;
                                vec_pe0_scheme = RELATED_ROTATE;
                                vec_pe1_scheme = RELATED_ROTATE;
                                rvec_dataR_n[{2'd0,2'd1}] = vec_pe0_x0_o;
                                rvec_dataI_n[{2'd0,2'd1}] = vec_pe0_y0_o;
                                rvec_dataR_n[{2'd0,2'd2}] = vec_pe0_x1_o;
                                rvec_dataI_n[{2'd0,2'd2}] = vec_pe0_y1_o;
                                rvec_dataR_n[{2'd1,2'd1}] = vec_pe1_x0_o;
                                rvec_dataI_n[{2'd1,2'd1}] = vec_pe1_y0_o;
                                rvec_dataR_n[{2'd1,2'd2}] = vec_pe1_x1_o;
                                rvec_dataI_n[{2'd1,2'd2}] = vec_pe1_y1_o;
                                vec_pe0_x0_i = vec_pe0_x1_o;
                                vec_pe0_y0_i = vec_pe0_y1_o;
                                vec_pe0_x1_i = rvec_dataR[{2'd0,2'd3}];
                                vec_pe0_y1_i = rvec_dataI[{2'd0,2'd3}];
                                vec_pe1_x0_i = vec_pe1_x1_o;
                                vec_pe1_y0_i = vec_pe1_y1_o;
                                vec_pe1_x1_i = rvec_dataR[{2'd1,2'd3}];
                                vec_pe1_y1_i = rvec_dataI[{2'd1,2'd3}];
                            end
                            5'd5: begin
                                inv_i = 0;
                                vec_pe0_valid = 2'b11;
                                vec_pe1_valid = 2'b11;
                                vec_pe0_scheme = RELATED_ROTATE;
                                vec_pe1_scheme = RELATED_ROTATE;
                                rvec_dataR_n[{2'd2,2'd1}] = vec_pe0_x0_o;
                                rvec_dataI_n[{2'd2,2'd1}] = vec_pe0_y0_o;
                                rvec_dataR_n[{2'd2,2'd2}] = vec_pe0_x1_o;
                                rvec_dataI_n[{2'd2,2'd2}] = vec_pe0_y1_o;
                                rvec_dataR_n[{2'd3,2'd1}] = vec_pe1_x0_o;
                                rvec_dataI_n[{2'd3,2'd1}] = vec_pe1_y0_o;
                                rvec_dataR_n[{2'd3,2'd2}] = vec_pe1_x1_o;
                                rvec_dataI_n[{2'd3,2'd2}] = vec_pe1_y1_o;
                                
                                vec_pe0_x0_i = vec_pe0_x1_o;
                                vec_pe0_y0_i = vec_pe0_y1_o;
                                vec_pe0_x1_i = rvec_dataR[{2'd2,2'd3}];
                                vec_pe0_y1_i = rvec_dataI[{2'd2,2'd3}];
                                vec_pe1_x0_i = vec_pe1_x1_o;
                                vec_pe1_y0_i = vec_pe1_y1_o;
                                vec_pe1_x1_i = rvec_dataR[{2'd3,2'd3}];
                                vec_pe1_y1_i = rvec_dataI[{2'd3,2'd3}];
                            end
                            5'd6: begin
                                inv_i = 0;
                                vec_pe0_valid = 2'b11;
                                vec_pe1_valid = 2'b11;
                                vec_pe0_scheme = RELATED_ROTATE;
                                vec_pe1_scheme = RELATED_ROTATE;
                                vec_pe0_x0_i = lvec_dataR[{2'd0,2'd0}];
                                vec_pe0_y0_i = lvec_dataI[{2'd0,2'd0}];
                                vec_pe0_x1_i = lvec_dataR[{2'd0,2'd1}];
                                vec_pe0_y1_i = lvec_dataI[{2'd0,2'd1}];
                                vec_pe1_x0_i = lvec_dataR[{2'd1,2'd0}];
                                vec_pe1_y0_i = lvec_dataI[{2'd1,2'd0}];
                                vec_pe1_x1_i = lvec_dataR[{2'd1,2'd1}];
                                vec_pe1_y1_i = lvec_dataI[{2'd1,2'd1}];
                            end
                            5'd7: begin
                                inv_i = 0;
                                vec_pe0_valid = 2'b11;
                                vec_pe1_valid = 2'b11;
                                vec_pe0_scheme = RELATED_ROTATE;
                                vec_pe1_scheme = RELATED_ROTATE;
                                vec_pe0_x0_i = lvec_dataR[{2'd2,2'd0}];
                                vec_pe0_y0_i = lvec_dataI[{2'd2,2'd0}];
                                vec_pe0_x1_i = lvec_dataR[{2'd2,2'd1}];
                                vec_pe0_y1_i = lvec_dataI[{2'd2,2'd1}];
                                vec_pe1_x0_i = lvec_dataR[{2'd3,2'd0}];
                                vec_pe1_y0_i = lvec_dataI[{2'd3,2'd0}];
                                vec_pe1_x1_i = lvec_dataR[{2'd3,2'd1}];
                                vec_pe1_y1_i = lvec_dataI[{2'd3,2'd1}];
                            end
                            5'd8: begin
                                vec_pe0_valid = 2'b00;
                                vec_pe1_valid = 2'b00;
                                vec_pe0_scheme = RELATED_ROTATE;
                                vec_pe1_scheme = RELATED_ROTATE;
                                rvec_dataR_n[{2'd0,2'd2}] = vec_pe0_x0_o;
                                rvec_dataI_n[{2'd0,2'd2}] = vec_pe0_y0_o;
                                rvec_dataR_n[{2'd0,2'd3}] = vec_pe0_x1_o;
                                rvec_dataI_n[{2'd0,2'd3}] = vec_pe0_y1_o;
                                rvec_dataR_n[{2'd1,2'd2}] = vec_pe1_x0_o;
                                rvec_dataI_n[{2'd1,2'd2}] = vec_pe1_y0_o;
                                rvec_dataR_n[{2'd1,2'd3}] = vec_pe1_x1_o;
                                rvec_dataI_n[{2'd1,2'd3}] = vec_pe1_y1_o;
                            end
                            5'd9: begin
                                vec_pe0_valid = 2'b00;
                                vec_pe1_valid = 2'b00;
                                vec_pe0_scheme = RELATED_ROTATE;
                                vec_pe1_scheme = RELATED_ROTATE;
                                rvec_dataR_n[{2'd2,2'd2}] = vec_pe0_x0_o;
                                rvec_dataI_n[{2'd2,2'd2}] = vec_pe0_y0_o;
                                rvec_dataR_n[{2'd2,2'd3}] = vec_pe0_x1_o;
                                rvec_dataI_n[{2'd2,2'd3}] = vec_pe0_y1_o;
                                rvec_dataR_n[{2'd3,2'd2}] = vec_pe1_x0_o;
                                rvec_dataI_n[{2'd3,2'd2}] = vec_pe1_y0_o;
                                rvec_dataR_n[{2'd3,2'd3}] = vec_pe1_x1_o;
                                rvec_dataI_n[{2'd3,2'd3}] = vec_pe1_y1_o;
                            end
                            5'd10: begin
                                inv_i = 0;
                                vec_pe0_valid = 2'b11;
                                vec_pe1_valid = 2'b11;
                                vec_pe0_scheme = RELATED_ROTATE;
                                vec_pe1_scheme = RELATED_ROTATE;
                                lvec_dataR_n[{2'd0,2'd0}] = vec_pe0_x0_o;
                                lvec_dataI_n[{2'd0,2'd0}] = vec_pe0_y0_o;
                                lvec_dataR_n[{2'd0,2'd1}] = vec_pe0_x1_o;
                                lvec_dataI_n[{2'd0,2'd1}] = vec_pe0_y1_o;
                                lvec_dataR_n[{2'd1,2'd0}] = vec_pe1_x0_o;
                                lvec_dataI_n[{2'd1,2'd0}] = vec_pe1_y0_o;
                                lvec_dataR_n[{2'd1,2'd1}] = vec_pe1_x1_o;
                                lvec_dataI_n[{2'd1,2'd1}] = vec_pe1_y1_o;
                                vec_pe0_x0_i = vec_pe0_x1_o;
                                vec_pe0_y0_i = vec_pe0_y1_o;
                                vec_pe0_x1_i = lvec_dataR[{2'd0,2'd2}];
                                vec_pe0_y1_i = lvec_dataI[{2'd0,2'd2}];
                                vec_pe1_x0_i = vec_pe1_x1_o;
                                vec_pe1_y0_i = vec_pe1_y1_o;
                                vec_pe1_x1_i = lvec_dataR[{2'd1,2'd2}];
                                vec_pe1_y1_i = lvec_dataI[{2'd1,2'd2}];
                            end
                            5'd11: begin
                                inv_i = 0;
                                vec_pe0_valid = 2'b11;
                                vec_pe1_valid = 2'b11;
                                vec_pe0_scheme = RELATED_ROTATE;
                                vec_pe1_scheme = RELATED_ROTATE;
                                lvec_dataR_n[{2'd2,2'd0}] = vec_pe0_x0_o;
                                lvec_dataI_n[{2'd2,2'd0}] = vec_pe0_y0_o;
                                lvec_dataR_n[{2'd2,2'd1}] = vec_pe0_x1_o;
                                lvec_dataI_n[{2'd2,2'd1}] = vec_pe0_y1_o;
                                lvec_dataR_n[{2'd3,2'd0}] = vec_pe1_x0_o;
                                lvec_dataI_n[{2'd3,2'd0}] = vec_pe1_y0_o;
                                lvec_dataR_n[{2'd3,2'd1}] = vec_pe1_x1_o;
                                lvec_dataI_n[{2'd3,2'd1}] = vec_pe1_y1_o;
                                vec_pe0_x0_i = vec_pe0_x1_o;
                                vec_pe0_y0_i = vec_pe0_y1_o;
                                vec_pe0_x1_i = lvec_dataR[{2'd2,2'd2}];
                                vec_pe0_y1_i = lvec_dataI[{2'd2,2'd2}];
                                vec_pe1_x0_i = vec_pe1_x1_o;
                                vec_pe1_y0_i = vec_pe1_y1_o;
                                vec_pe1_x1_i = lvec_dataR[{2'd3,2'd2}];
                                vec_pe1_y1_i = lvec_dataI[{2'd3,2'd2}];
                            end

                            5'd14: begin
                                inv_i = 0;
                                vec_pe0_valid = 2'b11;
                                vec_pe1_valid = 2'b11;
                                vec_pe0_scheme = RELATED_ROTATE;
                                vec_pe1_scheme = RELATED_ROTATE;
                                lvec_dataR_n[{2'd0,2'd1}] = vec_pe0_x0_o;
                                lvec_dataI_n[{2'd0,2'd1}] = vec_pe0_y0_o;
                                lvec_dataR_n[{2'd0,2'd2}] = vec_pe0_x1_o;
                                lvec_dataI_n[{2'd0,2'd2}] = vec_pe0_y1_o;
                                lvec_dataR_n[{2'd1,2'd1}] = vec_pe1_x0_o;
                                lvec_dataI_n[{2'd1,2'd1}] = vec_pe1_y0_o;
                                lvec_dataR_n[{2'd1,2'd2}] = vec_pe1_x1_o;
                                lvec_dataI_n[{2'd1,2'd2}] = vec_pe1_y1_o;
                                vec_pe0_x0_i = vec_pe0_x1_o;
                                vec_pe0_y0_i = vec_pe0_y1_o;
                                vec_pe0_x1_i = lvec_dataR[{2'd0,2'd3}];
                                vec_pe0_y1_i = lvec_dataI[{2'd0,2'd3}];
                                vec_pe1_x0_i = vec_pe1_x1_o;
                                vec_pe1_y0_i = vec_pe1_y1_o;
                                vec_pe1_x1_i = lvec_dataR[{2'd1,2'd3}];
                                vec_pe1_y1_i = lvec_dataI[{2'd1,2'd3}];
                            end
                            5'd15: begin
                                inv_i = 0;
                                vec_pe0_valid = 2'b11;
                                vec_pe1_valid = 2'b11;
                                vec_pe0_scheme = RELATED_ROTATE;
                                vec_pe1_scheme = RELATED_ROTATE;
                                lvec_dataR_n[{2'd2,2'd1}] = vec_pe0_x0_o;
                                lvec_dataI_n[{2'd2,2'd1}] = vec_pe0_y0_o;
                                lvec_dataR_n[{2'd2,2'd2}] = vec_pe0_x1_o;
                                lvec_dataI_n[{2'd2,2'd2}] = vec_pe0_y1_o;
                                lvec_dataR_n[{2'd3,2'd1}] = vec_pe1_x0_o;
                                lvec_dataI_n[{2'd3,2'd1}] = vec_pe1_y0_o;
                                lvec_dataR_n[{2'd3,2'd2}] = vec_pe1_x1_o;
                                lvec_dataI_n[{2'd3,2'd2}] = vec_pe1_y1_o;               
                                vec_pe0_x0_i = vec_pe0_x1_o;
                                vec_pe0_y0_i = vec_pe0_y1_o;
                                vec_pe0_x1_i = lvec_dataR[{2'd2,2'd3}];
                                vec_pe0_y1_i = lvec_dataI[{2'd2,2'd3}];
                                vec_pe1_x0_i = vec_pe1_x1_o;
                                vec_pe1_y0_i = vec_pe1_y1_o;
                                vec_pe1_x1_i = lvec_dataR[{2'd3,2'd3}];
                                vec_pe1_y1_i = lvec_dataI[{2'd3,2'd3}];
                            end
                            5'd16: begin
                                inv_i = 0;
                                vec_pe0_valid = 2'b11;
                                vec_pe1_valid = 2'b11;
                                vec_pe0_scheme = RELATED_ROTATE;
                                vec_pe1_scheme = RELATED_ROTATE;
                                vec_pe0_x0_i = rvec_dataR[{2'd0,2'd0}];
                                vec_pe0_y0_i = rvec_dataI[{2'd0,2'd0}];
                                vec_pe0_x1_i = rvec_dataR[{2'd0,2'd1}];
                                vec_pe0_y1_i = rvec_dataI[{2'd0,2'd1}];
                                vec_pe1_x0_i = rvec_dataR[{2'd1,2'd0}];
                                vec_pe1_y0_i = rvec_dataI[{2'd1,2'd0}];
                                vec_pe1_x1_i = rvec_dataR[{2'd1,2'd1}];
                                vec_pe1_y1_i = rvec_dataI[{2'd1,2'd1}];
                            end
                            5'd17: begin
                                inv_i = 0;
                                vec_pe0_valid = 2'b11;
                                vec_pe1_valid = 2'b11;
                                vec_pe0_scheme = RELATED_ROTATE;
                                vec_pe1_scheme = RELATED_ROTATE;
                                vec_pe0_x0_i = rvec_dataR[{2'd2,2'd0}];
                                vec_pe0_y0_i = rvec_dataI[{2'd2,2'd0}];
                                vec_pe0_x1_i = rvec_dataR[{2'd2,2'd1}];
                                vec_pe0_y1_i = rvec_dataI[{2'd2,2'd1}];
                                vec_pe1_x0_i = rvec_dataR[{2'd3,2'd0}];
                                vec_pe1_y0_i = rvec_dataI[{2'd3,2'd0}];
                                vec_pe1_x1_i = rvec_dataR[{2'd3,2'd1}];
                                vec_pe1_y1_i = rvec_dataI[{2'd3,2'd1}];
                            end
                            5'd18: begin
                                vec_pe0_valid = 2'b00;
                                vec_pe1_valid = 2'b00;
                                vec_pe0_scheme = RELATED_ROTATE;
                                vec_pe1_scheme = RELATED_ROTATE;
                                lvec_dataR_n[{2'd0,2'd2}] = vec_pe0_x0_o;
                                lvec_dataI_n[{2'd0,2'd2}] = vec_pe0_y0_o;
                                lvec_dataR_n[{2'd0,2'd3}] = vec_pe0_x1_o;
                                lvec_dataI_n[{2'd0,2'd3}] = vec_pe0_y1_o;
                                lvec_dataR_n[{2'd1,2'd2}] = vec_pe1_x0_o;
                                lvec_dataI_n[{2'd1,2'd2}] = vec_pe1_y0_o;
                                lvec_dataR_n[{2'd1,2'd3}] = vec_pe1_x1_o;
                                lvec_dataI_n[{2'd1,2'd3}] = vec_pe1_y1_o;
                            end
                            5'd19: begin
                                vec_pe0_valid = 2'b00;
                                vec_pe1_valid = 2'b00;
                                vec_pe0_scheme = RELATED_ROTATE;
                                vec_pe1_scheme = RELATED_ROTATE;
                                lvec_dataR_n[{2'd2,2'd2}] = vec_pe0_x0_o;
                                lvec_dataI_n[{2'd2,2'd2}] = vec_pe0_y0_o;
                                lvec_dataR_n[{2'd2,2'd3}] = vec_pe0_x1_o;
                                lvec_dataI_n[{2'd2,2'd3}] = vec_pe0_y1_o;
                                lvec_dataR_n[{2'd3,2'd2}] = vec_pe1_x0_o;
                                lvec_dataI_n[{2'd3,2'd2}] = vec_pe1_y0_o;
                                lvec_dataR_n[{2'd3,2'd3}] = vec_pe1_x1_o;
                                lvec_dataI_n[{2'd3,2'd3}] = vec_pe1_y1_o;
                            end

                            default: begin
                                inv_i = 0;
                                vec_pe0_valid = 2'b00;
                                vec_pe1_valid = 2'b00;
                                vec_pe0_scheme = RELATED_ROTATE;
                                vec_pe1_scheme = RELATED_ROTATE;
                            end
                        endcase
                    end
                endcase
            end
            SEND: begin
                for(i = 0; i < CHANNEL_SIZE; i = i + 1) begin

                    rvec_dataR_n[i] = rvec_dataR[i];
                    rvec_dataI_n[i] = rvec_dataI[i];
                end
                if (neg_val) begin
                    for(i = 0; i < CHANNEL_SIZE; i = i + 1) begin
                        lvec_dataR_n[i] = lvec_dataR[i];
                        lvec_dataI_n[i] = lvec_dataI[i];
                    end
                    case (cnt[1:0])  
                        2'b00: begin
                            lvec_dataR_n[{2'b00, 2'b00}] = -lvec_dataR[{2'b00, 2'b00}];
                            lvec_dataI_n[{2'b00, 2'b00}] = -lvec_dataI[{2'b00, 2'b00}];
                            lvec_dataR_n[{2'b01, 2'b00}] = -lvec_dataR[{2'b01, 2'b00}];
                            lvec_dataI_n[{2'b01, 2'b00}] = -lvec_dataI[{2'b01, 2'b00}];
                            lvec_dataR_n[{2'b10, 2'b00}] = -lvec_dataR[{2'b10, 2'b00}];
                            lvec_dataI_n[{2'b10, 2'b00}] = -lvec_dataI[{2'b10, 2'b00}];
                            lvec_dataR_n[{2'b11, 2'b00}] = -lvec_dataR[{2'b11, 2'b00}];
                            lvec_dataI_n[{2'b11, 2'b00}] = -lvec_dataI[{2'b11, 2'b00}];
                        end
                        2'b01: begin
                            lvec_dataR_n[{2'b00, 2'b01}] = -lvec_dataR[{2'b00, 2'b01}];
                            lvec_dataI_n[{2'b00, 2'b01}] = -lvec_dataI[{2'b00, 2'b01}];
                            lvec_dataR_n[{2'b01, 2'b01}] = -lvec_dataR[{2'b01, 2'b01}];
                            lvec_dataI_n[{2'b01, 2'b01}] = -lvec_dataI[{2'b01, 2'b01}];
                            lvec_dataR_n[{2'b10, 2'b01}] = -lvec_dataR[{2'b10, 2'b01}];
                            lvec_dataI_n[{2'b10, 2'b01}] = -lvec_dataI[{2'b10, 2'b01}];
                            lvec_dataR_n[{2'b11, 2'b01}] = -lvec_dataR[{2'b11, 2'b01}];
                            lvec_dataI_n[{2'b11, 2'b01}] = -lvec_dataI[{2'b11, 2'b01}];
                        end
                        2'b10: begin
                            lvec_dataR_n[{2'b00, 2'b10}] = -lvec_dataR[{2'b00, 2'b10}];
                            lvec_dataI_n[{2'b00, 2'b10}] = -lvec_dataI[{2'b00, 2'b10}];
                            lvec_dataR_n[{2'b01, 2'b10}] = -lvec_dataR[{2'b01, 2'b10}];
                            lvec_dataI_n[{2'b01, 2'b10}] = -lvec_dataI[{2'b01, 2'b10}];
                            lvec_dataR_n[{2'b10, 2'b10}] = -lvec_dataR[{2'b10, 2'b10}];
                            lvec_dataI_n[{2'b10, 2'b10}] = -lvec_dataI[{2'b10, 2'b10}];
                            lvec_dataR_n[{2'b11, 2'b10}] = -lvec_dataR[{2'b11, 2'b10}];
                            lvec_dataI_n[{2'b11, 2'b10}] = -lvec_dataI[{2'b11, 2'b10}];
                        end
                        2'b11: begin
                            lvec_dataR_n[{2'b00, 2'b11}] = -lvec_dataR[{2'b00, 2'b11}];
                            lvec_dataI_n[{2'b00, 2'b11}] = -lvec_dataI[{2'b00, 2'b11}];
                            lvec_dataR_n[{2'b01, 2'b11}] = -lvec_dataR[{2'b01, 2'b11}];
                            lvec_dataI_n[{2'b01, 2'b11}] = -lvec_dataI[{2'b01, 2'b11}];
                            lvec_dataR_n[{2'b10, 2'b11}] = -lvec_dataR[{2'b10, 2'b11}];
                            lvec_dataI_n[{2'b10, 2'b11}] = -lvec_dataI[{2'b10, 2'b11}];
                            lvec_dataR_n[{2'b11, 2'b11}] = -lvec_dataR[{2'b11, 2'b11}];
                            lvec_dataI_n[{2'b11, 2'b11}] = -lvec_dataI[{2'b11, 2'b11}];
                        end  
                    endcase
                end
                else begin
                    for(i = 0; i < CHANNEL_SIZE; i = i + 1) begin
                        lvec_dataR_n[i] = lvec_dataR[i];
                        lvec_dataI_n[i] = lvec_dataI[i];
                    end
                end
            end
            /*
            DONE: begin
                for(i = 0; i < CHANNEL_SIZE; i = i + 1) begin
                    lvec_dataR_n[i] = lvec_dataR[i];
                    lvec_dataI_n[i] = lvec_dataI[i];
                    rvec_dataR_n[i] = rvec_dataR[i];
                    rvec_dataI_n[i] = rvec_dataI[i];
                end 
            end
            */
        endcase
    end
    

    //sequential circuit
    always@(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            STATE      <= IDLE;
            PHASE      <= 0;
            DIAG_STATE <= 0;
            DPHASE     <= 0;
            inv <= 0;
            cnt <= 0;
            sw_num <= 0;
            valid_o <= 0;
            for(i = 0; i < CHANNEL_SIZE; i = i + 1) begin
                dataR[i] <= 0;
                dataI[i] <= 0;
                rvec_dataI[i] <= 0;
                lvec_dataI[i] <= 0;
            end

            rvec_dataR[0]  <= 18'b00_0100_0000_0000_0000;
            rvec_dataR[1]  <= 18'd0;
            rvec_dataR[2]  <= 18'd0;
            rvec_dataR[3]  <= 18'd0;
            rvec_dataR[4]  <= 18'd0;
            rvec_dataR[5]  <= 18'b00_0100_0000_0000_0000;
            rvec_dataR[6]  <= 18'd0;
            rvec_dataR[7]  <= 18'd0;
            rvec_dataR[8]  <= 18'd0;
            rvec_dataR[9]  <= 18'd0;
            rvec_dataR[10] <= 18'b00_0100_0000_0000_0000;
            rvec_dataR[11] <= 18'd0;
            rvec_dataR[12] <= 18'd0;
            rvec_dataR[13] <= 18'd0;
            rvec_dataR[14] <= 18'd0;
            rvec_dataR[15] <= 18'b00_0100_0000_0000_0000;

            lvec_dataR[0]  <= 18'b00_0100_0000_0000_0000;
            lvec_dataR[1]  <= 18'd0;
            lvec_dataR[2]  <= 18'd0;
            lvec_dataR[3]  <= 18'd0;
            lvec_dataR[4]  <= 18'd0;
            lvec_dataR[5]  <= 18'b00_0100_0000_0000_0000;
            lvec_dataR[6]  <= 18'd0;
            lvec_dataR[7]  <= 18'd0;
            lvec_dataR[8]  <= 18'd0;
            lvec_dataR[9]  <= 18'd0;
            lvec_dataR[10] <= 18'b00_0100_0000_0000_0000;
            lvec_dataR[11] <= 18'd0;
            lvec_dataR[12] <= 18'd0;
            lvec_dataR[13] <= 18'd0;
            lvec_dataR[14] <= 18'd0;
            lvec_dataR[15] <= 18'b00_0100_0000_0000_0000;

        end
        else begin
            STATE      <= STATE_N;
            PHASE      <= PHASE_N;
            DIAG_STATE <= DIAG_STATE_N;
            DPHASE     <= DPHASE_N;
            cnt <= cnt_n;
            sw_num <= sw_num_n;
            valid_o <= valid_o_n;
            inv <= inv_n;
            for(i = 0; i < CHANNEL_SIZE; i = i + 1) begin
                dataR[i] <= dataR_n[i];
                dataI[i] <= dataI_n[i];
                rvec_dataR[i] <= rvec_dataR_n[i];
                rvec_dataI[i] <= rvec_dataI_n[i];
                lvec_dataR[i] <= lvec_dataR_n[i];
                lvec_dataI[i] <= lvec_dataI_n[i];
            end
        end
    end

endmodule

