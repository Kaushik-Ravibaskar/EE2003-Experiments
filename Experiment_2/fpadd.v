/*
File Name: fpadd.v
Implementation: 1EEE-754 Floating Point Addition
Author: Kaushik Ravibaskar EE20B057
*/


//defining global constants
`define exp_bit 8
`define mant_bit 23
`define fp_size 32

//the main module
module fpadd (
    clk, reset, start,
    a, b,
    sum, 
    done,
    nan,
    current_state
);

    //defining internal wires, internal registers, temp storage elements

    //output [31:0] sum_reg;

    reg [`mant_bit+2:0] mant_ar, mant_br;
    reg [`mant_bit+2:0] mant_ar_next, mant_br_next;
    reg [`exp_bit:0] exp_ar, exp_br;
    reg [`exp_bit:0] exp_ar_next, exp_br_next;
    reg sign_ar, sign_br;
    reg sign_ar_next, sign_br_next;

    reg [`mant_bit+2:0] mant_sum_temp;
    reg [`mant_bit+2:0] mant_sum_temp_next;
    reg [`mant_bit+1:0] mant_sum;
    reg [`mant_bit+1:0] mant_sum_next;
    reg [`exp_bit-1:0] exp_sum;
    reg [`exp_bit-1:0] exp_sum_next;
    reg [31:0] sum_reg;
    reg [31:0] sum_reg_next;
    reg sign_sum_next;
    reg sign_sum;
    reg done_reg;
    reg done_reg_next;
    reg temp;
    reg temp_next;

    wire [`mant_bit+2:0] mant_a, mant_b;
    wire [`exp_bit-1:0] exp_a, exp_b;
    wire sign_a, sign_b;

    //defining the required i/o signals
    input clk, reset, start;
    input [31:0] a, b;
    output [31:0] sum;
    output done;
    output reg nan;
    output [3:0] current_state;
    //output [3:0] current_state;

    //defining the outputs
    assign sum = sum_reg;
    assign done = done_reg;

    //defining some assign statements to be stored in registers
    assign {sign_a, sign_b} = {a[`fp_size-1], b[`fp_size-1]};
    assign {exp_a, exp_b} = {a[`fp_size-2:`fp_size-9], b[`fp_size-2:`fp_size-9]};
    assign {mant_a, mant_b} = {1'b0,1'b0,1'b1,a[`fp_size-10:0],1'b0,1'b0,1'b1,b[`fp_size-10:0]};

    //defining the states of the adder
localparam State_Initial = 4'd0,
            State_1 = 4'd1,
            State_2 = 4'd2,
            State_3 = 4'd3,
            State_4 = 4'd4,
            State_5 = 4'd5,
            State_6 = 4'd6,
            State_7 = 4'd7,
            State_8 = 4'd8,
            State_9 = 4'd9,
            State_10 = 4'd10;
    
    //defining state regs
    reg [3:0] current_state;
    reg [3:0] next_state;

    //synchronous positive edge clock state transition
    always @ (posedge clk) begin
        if (reset == 1 || start == 1) begin
            current_state <= State_Initial;
        end
        else begin
            current_state <= next_state;
            mant_ar_next <= mant_ar;
            mant_br_next <= mant_br;
            exp_ar_next <= exp_ar;
            exp_br_next <= exp_br;
            sign_ar_next <= sign_ar;
            sign_br_next <= sign_br;
            mant_sum_temp_next <= mant_sum_temp;
            mant_sum_next <= mant_sum;
            exp_sum_next <= exp_sum;
            sum_reg_next <= sum_reg;
            sign_sum_next <= sign_sum;
            done_reg_next <= done_reg;
            temp_next <= temp;
            
            
            
        end
    end

    //conditional state transition always block
    always @ (*) begin
        next_state = current_state;
        mant_ar = mant_ar_next;
        mant_br = mant_br_next;
        exp_ar = exp_ar_next;
        exp_br = exp_br_next;
        sign_ar = sign_ar_next;
        sign_br = sign_br_next;
        mant_sum_temp = mant_sum_temp_next;
        mant_sum = mant_sum_next;
        exp_sum = exp_sum_next;
        sum_reg = sum_reg_next;
        sign_sum = sign_sum_next;
        done_reg = done_reg_next;
        temp = temp_next;

        case(current_state)

            //initial state
            State_Initial: begin
                sum_reg = 0;    
                done_reg = 0;
                mant_ar = 0;
                mant_br = 0;
                exp_ar = 0;
                exp_br = 0;
                sign_ar = 0;
                sign_br = 0;
                mant_sum_temp = 0;
                mant_sum = 0;
                exp_sum = 0;
                sign_sum = 0;
                nan = 0;
                temp = 0;
                
                if (start != 1) begin
                    next_state = State_1;
                
                end

            end

            //storing mantissa of a and b
            State_1: begin
                if (sign_a == 1 && sign_b == 0) begin
                    mant_ar = ~(mant_a) + 1;
                    mant_br = mant_b;
                end
                else if (sign_a == 0 && sign_b == 1) begin
                    mant_ar = mant_a;
                    mant_br = ~(mant_b) + 1;
                end
                else if (sign_a == 0 && sign_b == 0) begin
                    mant_ar = mant_a;
                    mant_br = mant_b;
                end
                else begin
                    mant_ar = ~(mant_a) + 1;
                    mant_br = ~(mant_b) + 1;
                end
                next_state = State_2;
            end

            //taking care of exponents
            State_2: begin
                if (exp_a > exp_b) begin
                    exp_ar = {1'b0, exp_a};
                    exp_br = ~{1'b0, exp_b} + 1;
                    {temp,exp_sum} = exp_ar + exp_br;
                        if (mant_br[`mant_bit+2] == 1) begin
                            mant_br = ~(mant_br) + 1;
                            mant_br = mant_br >> exp_sum;
                            mant_br = ~(mant_br) + 1;
                        end
                        else begin
                            mant_br = mant_br >> exp_sum;
                        end
                    exp_sum = exp_a;
                end
                else if (exp_a < exp_b) begin
                    exp_br = {1'b0, exp_b};
                    exp_ar = ~{1'b0, exp_a} + 1;
                    {temp,exp_sum} = exp_ar + exp_br;
                        if (mant_ar[`mant_bit+2] == 1) begin
                            mant_ar = ~(mant_ar) + 1;
                            mant_ar = mant_ar >> exp_sum;
                            mant_ar = ~(mant_ar) + 1;
                        end
                        else begin
                            mant_ar = mant_ar >> exp_sum;
                        end
                    exp_sum = exp_b;
                end
                else begin
                    exp_sum = exp_a;
                end

                next_state = State_3;

            end

            //adding the mantissas and storing the sign bit and branching to different cases
            State_3: begin
                mant_sum_temp = mant_ar + mant_br;

                if (mant_sum_temp[`mant_bit+2] == 1) begin
                    sign_sum = 1;
                    mant_sum_temp = ~(mant_sum_temp) + 1;
                    {temp, mant_sum} = mant_sum_temp;
                end
                else begin
                    sign_sum = 0;
                    {temp, mant_sum} = mant_sum_temp;
                end


                if (exp_a == 0 && mant_a[22:0] == 0) begin
                    next_state = State_4;                   
                end
                else if (exp_b == 0 && mant_b[22:0] == 0) begin
                    next_state = State_4;
                end
                else if (exp_a == 8'hff && mant_a[22:0] == 0) begin
                    next_state = State_4;              
                end
                else if (exp_b == 8'hff && mant_b[22:0] == 0) begin
                    next_state = State_4;
                end
                else if (exp_a == 8'hff && mant_a[22:0] != 0) begin
                    next_state = State_4;
                end
                else if (exp_b == 8'hff && mant_b[22:0] != 0) begin
                    next_state = State_4;
                end
                else if (mant_sum == 0) begin
                    next_state = State_4;
                end
                else if (mant_sum[`mant_bit+1] == 0 && mant_sum[`mant_bit] == 1) begin
                    next_state = State_5;
                end
                else if (mant_sum[`mant_bit+1] == 1) begin
                    next_state = State_6;
                end
                else begin
                    next_state = State_7;
                end
            
            end

            //edge cases
            State_4: begin

                if (exp_a == 8'hff && mant_a[22:0] != 0 && done_reg != 1) begin
                    sum_reg = 0;
                    nan = 1;
                    done_reg = 1;
                    
                end
                else if (exp_b == 8'hff && mant_b[22:0] != 0 && done_reg != 1) begin
                    sum_reg = 0;
                    nan = 1;
                    done_reg = 1;
                    
                end
                else if (exp_a == 0 && mant_a[22:0] == 0 && done_reg != 1) begin
                    sum_reg = b;
                    done_reg = 1;
                    
                end
                else if (exp_b == 0 && mant_b[22:0] == 0 && done_reg != 1) begin
                    sum_reg = a;
                    done_reg = 1;
                    
                end
                else if (exp_a == 8'hff && mant_a[22:0] == 0 && done_reg != 1) begin
                    sum_reg = a;
                    done_reg = 1;
                    
                end
                else if (exp_b == 8'hff && mant_b[22:0] == 0 && done_reg != 1) begin
                    sum_reg = b;
                    done_reg = 1;
                    
                end
                else if (mant_sum == 0 && done_reg != 1) begin
                    exp_sum = 0;
                    sum_reg = 0;
                    done_reg = 1;

                end

                if (start == 1) begin
                    next_state = State_Initial;
                end


            end

            //normal case
            State_5: begin                
                
                if (done_reg != 1) begin
                    exp_sum = exp_sum;
                    mant_sum = mant_sum;
                    sum_reg = {sign_sum, exp_sum, mant_sum[`mant_bit-1:0]};
                    done_reg = 1;
    
                    
                end
                
                if (start == 1) begin
                    next_state = State_Initial;
                end

            end

            //overflow case
            State_6: begin
                
                if (done_reg != 1) begin
                    mant_sum = mant_sum >> 1;
                    exp_sum = exp_sum + 1;
                    sum_reg = {sign_sum, exp_sum, mant_sum[`mant_bit-1:0]};
                    done_reg = 1;
                    
                
                end
                
                if (start == 1) begin
                    next_state = State_Initial;
                end
                

            end


            //special case of small mantissa
            State_7: begin

                if(mant_sum[`mant_bit] == 1 && done_reg != 1) begin
                    sum_reg = {sign_sum, exp_sum, mant_sum[`mant_bit-1:0]};
                    done_reg = 1;
                end
                else if (done_reg != 1) begin
                    mant_sum = mant_sum << 1;
                    exp_sum = exp_sum - 1;
                    next_state = State_8;               
                end

                if (start == 1) begin
                    next_state = State_Initial;
                end


            end

            //a shield for State_7
            State_8: begin

                next_state = State_7;

            end

        endcase

    end 


endmodule
