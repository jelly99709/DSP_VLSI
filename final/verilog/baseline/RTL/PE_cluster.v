module PE_cluster (
    clk,
    rst_n,
    val_PE0_valid_i,
    val_PE1_valid_i,
    val_PE0_scheme_i,
    val_PE1_scheme_i,
    val_PE0_X0_i, 
    val_PE0_Y0_i,
    val_PE0_X1_i, 
    val_PE0_Y1_i,
    val_PE1_X0_i, 
    val_PE1_Y0_i,
    val_PE1_X1_i, 
    val_PE1_Y1_i,
    val_PE0_X0_o, 
    val_PE0_Y0_o,
    val_PE0_X1_o, 
    val_PE0_Y1_o,
    val_PE1_X0_o, 
    val_PE1_Y0_o,
    val_PE1_X1_o, 
    val_PE1_Y1_o,

    vec_PE0_valid_i,
    vec_PE1_valid_i,
    vec_PE0_scheme_i,
    vec_PE1_scheme_i,
    vec_PE0_X0_i, 
    vec_PE0_Y0_i,
    vec_PE0_X1_i, 
    vec_PE0_Y1_i,
    vec_PE1_X0_i, 
    vec_PE1_Y0_i,
    vec_PE1_X1_i, 
    vec_PE1_Y1_i,
    vec_PE0_X0_o, 
    vec_PE0_Y0_o,
    vec_PE0_X1_o, 
    vec_PE0_Y1_o,
    vec_PE1_X0_o, 
    vec_PE1_Y0_o,
    vec_PE1_X1_o, 
    vec_PE1_Y1_o,      
    angle_inv 

);
    parameter BITWIDTH   = 18;
    parameter CORDIC_NUM = 14;

    input wire clk, rst_n;

    input wire [1:0] val_PE0_valid_i, val_PE1_valid_i;
    input wire [1:0] val_PE0_scheme_i, val_PE1_scheme_i;
    input wire signed [BITWIDTH-1:0] val_PE0_X0_i, val_PE0_Y0_i, val_PE0_X1_i, val_PE0_Y1_i;
    input wire signed [BITWIDTH-1:0] val_PE1_X0_i, val_PE1_Y0_i, val_PE1_X1_i, val_PE1_Y1_i;
    output wire signed [BITWIDTH-1:0] val_PE0_X0_o, val_PE0_Y0_o, val_PE0_X1_o, val_PE0_Y1_o;
    output wire signed [BITWIDTH-1:0] val_PE1_X0_o, val_PE1_Y0_o, val_PE1_X1_o, val_PE1_Y1_o;
    input wire [1:0] vec_PE0_valid_i, vec_PE1_valid_i;
    input wire [1:0] vec_PE0_scheme_i, vec_PE1_scheme_i;
    input wire signed [BITWIDTH-1:0] vec_PE0_X0_i, vec_PE0_Y0_i, vec_PE0_X1_i, vec_PE0_Y1_i;
    input wire signed [BITWIDTH-1:0] vec_PE1_X0_i, vec_PE1_Y0_i, vec_PE1_X1_i, vec_PE1_Y1_i;
    output wire signed [BITWIDTH-1:0] vec_PE0_X0_o, vec_PE0_Y0_o, vec_PE0_X1_o, vec_PE0_Y1_o;
    output wire signed [BITWIDTH-1:0] vec_PE1_X0_o, vec_PE1_Y0_o, vec_PE1_X1_o, vec_PE1_Y1_o;
    input wire  [CORDIC_NUM-1:0] angle_inv;

    wire [CORDIC_NUM-1:0] angle0_i, angle1_i;
    wire [CORDIC_NUM-1:0] angle0_o, angle1_o;
    
    assign angle0_i = angle0_o ^ angle_inv;
    assign angle1_i = angle1_o ^ angle_inv;


    PEs_val val_unit(
        .clk(clk),
        .rst_n(rst_n),
        .PE0_valid_i(val_PE0_valid_i),
        .PE1_valid_i(val_PE1_valid_i),
        .PE0_scheme_i(val_PE0_scheme_i),
        .PE1_scheme_i(val_PE1_scheme_i),
        .PE0_X0_i(val_PE0_X0_i), .PE0_Y0_i(val_PE0_Y0_i),
        .PE0_X1_i(val_PE0_X1_i), .PE0_Y1_i(val_PE0_Y1_i),
        .PE1_X0_i(val_PE1_X0_i), .PE1_Y0_i(val_PE1_Y0_i),
        .PE1_X1_i(val_PE1_X1_i), .PE1_Y1_i(val_PE1_Y1_i),
        .PE0_X0_o(val_PE0_X0_o), .PE0_Y0_o(val_PE0_Y0_o),
        .PE0_X1_o(val_PE0_X1_o), .PE0_Y1_o(val_PE0_Y1_o),
        .PE1_X0_o(val_PE1_X0_o), .PE1_Y0_o(val_PE1_Y0_o),
        .PE1_X1_o(val_PE1_X1_o), .PE1_Y1_o(val_PE1_Y1_o), 
        .angle0_o(angle0_o), 
        .angle1_o(angle1_o)
        );

    PEs_vec vec_unit(
        .clk(clk),
        .rst_n(rst_n),
        .PE0_valid_i(vec_PE0_valid_i),
        .PE1_valid_i(vec_PE1_valid_i),
        .PE0_scheme_i(vec_PE0_scheme_i),
        .PE1_scheme_i(vec_PE1_scheme_i),
        .PE0_X0_i(vec_PE0_X0_i), .PE0_Y0_i(vec_PE0_Y0_i),
        .PE0_X1_i(vec_PE0_X1_i), .PE0_Y1_i(vec_PE0_Y1_i),
        .PE1_X0_i(vec_PE1_X0_i), .PE1_Y0_i(vec_PE1_Y0_i),
        .PE1_X1_i(vec_PE1_X1_i), .PE1_Y1_i(vec_PE1_Y1_i),
        .PE0_X0_o(vec_PE0_X0_o), .PE0_Y0_o(vec_PE0_Y0_o),
        .PE0_X1_o(vec_PE0_X1_o), .PE0_Y1_o(vec_PE0_Y1_o),
        .PE1_X0_o(vec_PE1_X0_o), .PE1_Y0_o(vec_PE1_Y0_o),
        .PE1_X1_o(vec_PE1_X1_o), .PE1_Y1_o(vec_PE1_Y1_o), 
        .angle0_i(angle0_i), 
        .angle1_i(angle1_i)
        );

endmodule




module PEs_val (
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

    angle0_o, 
    angle1_o
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

    output signed [CORDIC_NUM-1:0] angle0_o;
    output signed [CORDIC_NUM-1:0] angle1_o;

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
        
        for(i=0;i<4;i=i+1) begin
            PE0_angle_d0_in[i] = (angle0_reg[i] & (~PE0_angle_val0_out[0])) | (PE0_angle_d0_out[i] & (PE0_angle_val0_out[0]));
            PE0_angle_d1_in[i] = (angle1_reg[i] & (~PE0_angle_val1_out[0])) | (PE0_angle_d1_out[i] & (PE0_angle_val1_out[0]));
        end
        
        for(i=4;i<9;i=i+1) begin
            PE0_angle_d0_in[i] = (angle0_reg[i] & (~PE0_angle_val0_out[1])) | (PE0_angle_d0_out[i] & (PE0_angle_val0_out[1]));
            PE0_angle_d1_in[i] = (angle1_reg[i] & (~PE0_angle_val1_out[1])) | (PE0_angle_d1_out[i] & (PE0_angle_val1_out[1]));
        end

        for(i=9;i<14;i=i+1) begin
            PE0_angle_d0_in[i] = (angle0_reg[i] & (~PE0_angle_val0_out[2])) | (PE0_angle_d0_out[i] & (PE0_angle_val0_out[2]));
            PE0_angle_d1_in[i] = (angle1_reg[i] & (~PE0_angle_val1_out[2])) | (PE0_angle_d1_out[i] & (PE0_angle_val1_out[2]));
        end
    end



    assign PE1_idle   = ~PE1_valid_i;
    assign PE1_scheme = PE1_scheme_i;
    assign PE1_X0_in  = PE1_X0_i;
    assign PE1_Y0_in  = PE1_Y0_i;
    assign PE1_X1_in  = PE1_X1_i;
    assign PE1_Y1_in  = PE1_Y1_i;


    always @(*) begin
        
        for(i=0;i<4;i=i+1) begin
            PE1_angle_d0_in[i] = (angle0_reg[i] & (~PE0_angle_val0_out[0])) | (PE0_angle_d0_out[i] & (PE0_angle_val0_out[0]));
            PE1_angle_d1_in[i] = (angle1_reg[i] & (~PE0_angle_val1_out[0])) | (PE0_angle_d1_out[i] & (PE0_angle_val1_out[0]));
        end
        
        for(i=4;i<9;i=i+1) begin
            PE1_angle_d0_in[i] = (angle0_reg[i] & (~PE0_angle_val0_out[1])) | (PE0_angle_d0_out[i] & (PE0_angle_val0_out[1]));
            PE1_angle_d1_in[i] = (angle1_reg[i] & (~PE0_angle_val1_out[1])) | (PE0_angle_d1_out[i] & (PE0_angle_val1_out[1]));
        end
        for(i=9;i<14;i=i+1) begin
            PE1_angle_d0_in[i] = (angle0_reg[i] & (~PE0_angle_val0_out[2])) | (PE0_angle_d0_out[i] & (PE0_angle_val0_out[2]));
            PE1_angle_d1_in[i] = (angle1_reg[i] & (~PE0_angle_val1_out[2])) | (PE0_angle_d1_out[i] & (PE0_angle_val1_out[2]));
        end
    end

    PE_VR #(BITWIDTH,CORDIC_NUM) PE0(
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

    PE_R #(BITWIDTH,CORDIC_NUM) PE1(
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
        .Y1_o(PE1_Y1_out)
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

module PEs_vec (
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

    PE_R #(BITWIDTH,CORDIC_NUM) PE0(
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
        .Y1_o(PE0_Y1_out)
    );

    PE_R #(BITWIDTH,CORDIC_NUM) PE1(
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
        .Y1_o(PE1_Y1_out)
    );


endmodule