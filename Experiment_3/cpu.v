/*

Name: Kaushik Ravibaskar
File name: cpu.v
Assignment: Single Cycle CPU based on RISCV instruction set

*/


//module instantiation
module cpu (
    input clk, 
    input reset,
    output [31:0] iaddr,
    input [31:0] idata,
    output [31:0] daddr,
    input [31:0] drdata,
    output [31:0] dwdata,
    output [3:0] dwe,
    output [32*32-1:0] registers
);

//defining local parameters
localparam case0 = 3'd0,
            case1 = 3'd1,
            case2 = 3'd2,
            case3 = 3'd3,
            case4 = 3'd4,
            case5 = 3'd5,
            case6 = 3'd6,
            case7 = 3'd7;

    //registers for interfacing IMEM and DMEM
    reg [31:0] iaddr;
    reg [31:0] daddr;
    reg [31:0] dwdata;
    reg [3:0]  dwe;
    reg [31:0] iaddr_b;

    reg [31:0] iaddr_q;
    reg [31:0] daddr_q;
    reg [31:0] dwdata_q;
    reg [3:0]  dwe_q;

    //gpr registers and registers used for interfacing them
    reg [31:0] gpr_data_in;
    reg [4:0] gpr_rd_add;
    reg [31:0] gpr_registers [0:31];

    reg [31:0] gpr_data_in_q;
    reg [4:0] gpr_rd_add_q;

    //for hardware compatibility
    assign registers = {gpr_registers[31], gpr_registers[30], gpr_registers[29], gpr_registers[28], gpr_registers[27], gpr_registers[26], gpr_registers[25], gpr_registers[24], gpr_registers[23], gpr_registers[22], gpr_registers[21], gpr_registers[20], gpr_registers[19], gpr_registers[18], gpr_registers[17], gpr_registers[16], gpr_registers[15], gpr_registers[14], gpr_registers[13], gpr_registers[12], gpr_registers[11], gpr_registers[10], gpr_registers[9], gpr_registers[8], gpr_registers[7], gpr_registers[6], gpr_registers[5], gpr_registers[4], gpr_registers[3], gpr_registers[2], gpr_registers[1], gpr_registers[0]};

    //temporary register for looping the reg file
    integer i;
    reg we;
    reg we_q;

    //control flags (inst specific)
    reg flag_i;
    reg flag_r;
    reg flag_s;
    reg flag_b;
    reg flag_u;

    reg flag_i_q;
    reg flag_r_q;
    reg flag_s_q;
    reg flag_b_q;
    reg flag_u_q;

    
    //decoder block
    always @(*) begin

        //setting d-input to q-input to avoid latching!
        daddr = daddr_q;
        dwdata = dwdata_q;
        dwe = dwe_q;
        iaddr = iaddr_q;
        iaddr_b = iaddr_q;
        gpr_data_in = gpr_data_in_q;
        gpr_rd_add = gpr_rd_add_q;
        flag_i = flag_i_q;
        flag_r = flag_r_q;
        flag_s = flag_s_q;
        flag_b = flag_b_q;
        flag_u = flag_u_q;
        we = we_q;

        //setting up the flags (inst. specific)
        if (idata[6:0] == 7'b0000011 || ((idata[6:0] == 7'b0010011) && (idata[14:12] != 001) && (idata[14:12] != 101))) begin
            flag_i = 1;
            flag_r = 0;
            flag_s = 0;
            flag_b = 0;
            flag_u = 0;
        end
        else if (idata[6:4] == 3'b010) begin
            flag_s = 1;
            flag_i = 0;
            flag_r = 0;
            flag_b = 0;
            flag_u = 0;
        end
        else if (idata[6:0] == 7'b0010011 || idata[6:0] == 7'b0110011) begin
            flag_r = 1;
            flag_i = 0;
            flag_s = 0;
            flag_b = 0;
            flag_u = 0;
        end
        else if (idata[6:0] == 7'b1100011) begin
            flag_b = 1;
            flag_i = 0;
            flag_r = 0;
            flag_s = 0;
            flag_u = 0;
        end
        else if (idata[6:0] == 7'b0110111 || idata[6:0] == 7'b0010111) begin
            flag_b = 0;
            flag_i = 0;
            flag_r = 0;
            flag_s = 0;
            flag_u = 1;
        end
        else begin
            flag_b = 0;
            flag_i = 0;
            flag_r = 0;
            flag_s = 0;
            flag_u = 0;
        end



        //I-type instructions
        if (flag_i == 1 && idata[6:4] == 3'b000) begin
            dwe = 0;
            case (idata[14:12])

                case0: begin
                    //$display("LB");
                    gpr_rd_add = idata[11:7];
                    daddr = gpr_registers[idata[19:15]] + {{20{idata[31]}}, idata[31:20]};
                    gpr_data_in = {{24{drdata[7]}},drdata[7:0]};
                    we = 1;
                end

                case1: begin
                    //$display("LH");
                    gpr_rd_add = idata[11:7];
                    daddr = gpr_registers[idata[19:15]] + {{20{idata[31]}}, idata[31:20]};
                    gpr_data_in = {{16{drdata[15]}},drdata[15:0]};
                    we = 1;
                end
                case2: begin
                    //$display("LW");
                    gpr_rd_add = idata[11:7];
                    daddr = gpr_registers[idata[19:15]] + {{20{idata[31]}}, idata[31:20]};
                    gpr_data_in = drdata;
                    we = 1;
                end
                case4: begin
                    //$display("LBU");
                    gpr_rd_add = idata[11:7];
                    daddr = gpr_registers[idata[19:15]] + {{20{idata[31]}}, idata[31:20]};
                    gpr_data_in = {{24{1'b0}},drdata[7:0]};
                    we = 1;
                end
                case4: begin
                    //$display("LHU");
                    gpr_rd_add = idata[11:7];
                    daddr = gpr_registers[idata[19:15]] + {{20{idata[31]}}, idata[31:20]};
                    gpr_data_in = {{16{1'b0}},drdata[15:0]};
                    we = 1;
                end
            endcase
        end

        //I-type instructions
        else if (flag_i == 1 && idata[6:4] == 3'b001) begin
            dwe = 0;
            case (idata[14:12])

                case0: begin
                    //$display("ADDI");
                    gpr_rd_add = idata[11:7];
                    gpr_data_in = gpr_registers[idata[19:15]] + {{20{idata[31]}}, idata[31:20]};
                    we = 1;
                end
                case2: begin
                    //$display("SLTI");
                    gpr_rd_add = idata[11:7];
                    we = 1;
                    if(gpr_registers[idata[19:15]][31] == 0 && idata[31] == 0) begin
                        gpr_data_in = (gpr_registers[idata[19:15]] <  {{20{idata[31]}}, idata[31:20]}) ? 1 : 0;
                    end
                    else if(gpr_registers[idata[19:15]][31] == 0 && idata[31] == 1) begin
                        gpr_data_in = 0;
                    end
                    else if(gpr_registers[idata[19:15]][31] == 1 && idata[31] == 0) begin
                        gpr_data_in = 1;
                    end
                    else begin
                        gpr_data_in = (gpr_registers[idata[19:15]] <  {{20{idata[31]}}, idata[31:20]}) ? 1 : 0;
                    end
                end
                case3: begin
                    //$display("SLTIU");
                    gpr_rd_add = idata[11:7];
                    we = 1;
                    gpr_data_in = (gpr_registers[idata[19:15]] <  {{20{idata[31]}}, idata[31:20]}) ? 1 : 0;
                end
                case4: begin
                    //$display("XORI");
                    we = 1;
                    gpr_rd_add = idata[11:7];
                    gpr_data_in = (gpr_registers[idata[19:15]] ^  {{20{idata[31]}}, idata[31:20]});
                end
                case6: begin
                    //$display("ORI");
                    we = 1;
                    gpr_rd_add = idata[11:7];
                    gpr_data_in = (gpr_registers[idata[19:15]] |  {{20{idata[31]}}, idata[31:20]});
                end
                case7: begin
                    //$display("ANDI");
                    we = 1;
                    gpr_rd_add = idata[11:7];
                    gpr_data_in = (gpr_registers[idata[19:15]] &  {{20{idata[31]}}, idata[31:20]});
                end
            endcase

        end
        
        //S-type instruction
        else if (flag_s == 1) begin
            case(idata[14:12])

                case0: begin
                    //$display("SB");
                    we = 0;
                    daddr = gpr_registers[idata[19:15]] + {{20{idata[31]}}, idata[31:25], idata[11:7]};
                    dwdata = gpr_registers[idata[24:20]];
                    
                    case(daddr[1:0])

                        0: dwe = 4'b0001;
                        1: dwe = 4'b0010;
                        2: dwe = 4'b0100;
                        3: dwe = 4'b1000;

                    endcase

                end

                case1: begin
                    //$display("SH");
                    we = 0;
                    daddr = gpr_registers[idata[19:15]] + {{20{idata[31]}}, idata[31:25], idata[11:7]};
                    dwdata = gpr_registers[idata[24:20]];
                    dwe = 4'b0011;

                    case(daddr[1])

                        0: dwe = 4'b0011;
                        1: dwe = 4'b1100;

                    endcase

                end

                case2: begin
                    //$display("SW");
                    we = 0;
                    daddr = gpr_registers[idata[19:15]] + {{20{idata[31]}}, idata[31:25], idata[11:7]};
                    dwdata = gpr_registers[idata[24:20]];
                    dwe = 4'b1111;

                end


            endcase
        
        end
        
        //R-type instruction
        else if (flag_r == 1) begin
            dwe = 0;
            if (idata[6:4] == 3'b001) begin
                case (idata[14:12])

                    case1: begin
                        //$display("SLLI");
                        gpr_rd_add = idata[11:7];
                        gpr_data_in = gpr_registers[idata[19:15]] << (idata[24:20]);
                        we = 1;

                    end

                    case5: begin

                        if(idata[30] == 0) begin
                            //$display("SRLI");
                            gpr_rd_add = idata[11:7];
                            gpr_data_in = gpr_registers[idata[19:15]] >> (idata[24:20]);
                            we = 1;
                        end
                        else begin
                            //$display("SRAI");
                            gpr_rd_add = idata[11:7];
                            gpr_data_in = gpr_registers[idata[19:15]] >>> (idata[24:20]);
                            we = 1;
                        end

                    end


                endcase
            end

            else if(idata[6:4] == 3'b011) begin
                case(idata[14:12])

                    case0: begin

                        if(idata[30] == 0) begin
                            //$display("ADD");
                            gpr_rd_add = idata[11:7];
                            gpr_data_in = gpr_registers[idata[19:15]] + gpr_registers[idata[24:20]];
                            we = 1;
                        end
                        else begin
                            //$display("SUB");
                            gpr_rd_add = idata[11:7];
                            gpr_data_in = gpr_registers[idata[19:15]] - gpr_registers[idata[24:20]];
                            we = 1;
                        end

                    end

                    case1: begin
                        //$display("SLL");
                        gpr_rd_add = idata[11:7];
                        gpr_data_in = gpr_registers[idata[19:15]] << (gpr_registers[idata[24:20]][4:0]);
                        we = 1;

                    end

                    case2: begin
                        //$display("SLT");
                        we = 1;
                        gpr_rd_add = idata[11:7];
                        if(gpr_registers[idata[19:15]][31] == 0 && gpr_registers[idata[24:20]][31] == 0) begin
                            gpr_data_in = (gpr_registers[idata[19:15]] <  gpr_registers[idata[24:20]]) ? 1 : 0;
                        end
                        else if(gpr_registers[idata[19:15]][31] == 0 && gpr_registers[idata[24:20]][31] == 1) begin
                            gpr_data_in = 0;
                        end
                        else if(gpr_registers[idata[19:15]][31] == 1 && gpr_registers[idata[24:20]][31] == 0) begin
                            gpr_data_in = 1;
                        end
                        else begin
                            gpr_data_in = (gpr_registers[idata[19:15]] <  gpr_registers[idata[24:20]]) ? 1 : 0;
                        end
                    end

                    case3: begin
                        //$display("SLTU");
                        we = 1;
                        gpr_rd_add = idata[11:7];
                        gpr_data_in = (gpr_registers[idata[19:15]] <  gpr_registers[idata[24:20]]) ? 1 : 0;

                    end

                    case4: begin
                        //$display("XOR");
                        we = 1;
                        gpr_rd_add = idata[11:7];
                        gpr_data_in = (gpr_registers[idata[19:15]] ^  gpr_registers[idata[24:20]]);

                    end

                    case5: begin

                        if(idata[30] == 0) begin
                            //$display("SRL");
                            we = 1;
                            gpr_rd_add = idata[11:7];
                            gpr_data_in = gpr_registers[idata[19:15]] >>  (gpr_registers[idata[24:20]]);
                        end
                        else begin
                            //$display("SRA");
                            we = 1;
                            gpr_rd_add = idata[11:7];
                            gpr_data_in = gpr_registers[idata[19:15]] >>>  (gpr_registers[idata[24:20]]);
                        end

                    end

                    case6: begin
                        //$display("OR");
                        we = 1;
                        gpr_rd_add = idata[11:7];
                        gpr_data_in = (gpr_registers[idata[19:15]] |  gpr_registers[idata[24:20]]);

                    end

                    case7: begin
                        //$display("AND");
                        we = 1;
                        gpr_rd_add = idata[11:7];
                        gpr_data_in = (gpr_registers[idata[19:15]] & gpr_registers[idata[24:20]]);

                    end

                endcase

            end

        end

        //B-type instruction
        else if (flag_b == 1) begin
            dwe = 0;

            case(idata[14:12])

                case0: begin
                    //$display("BEQ");
                    we = 0;
                    if(gpr_registers[idata[19:15]] == gpr_registers[idata[24:20]]) begin
                        iaddr_b = iaddr_q + {{20{idata[31]}}, idata[7], idata[30:25], idata[11:8], 1'b0};
                    end
                    else begin
                        iaddr_b = iaddr_q + 4;
                    end

                end

                case1: begin
                    //$display("BNE");
                    we = 0;
                    if(gpr_registers[idata[19:15]] != gpr_registers[idata[24:20]]) begin
                        iaddr_b = iaddr_q + {{20{idata[31]}}, idata[7], idata[30:25], idata[11:8], 1'b0};
                    end
                    else begin
                        iaddr_b = iaddr_q + 4;
                    end

                end

                case4: begin
                    //$display("BLT");
                    we = 0;
                    if(gpr_registers[idata[19:15]][31] == 0 && gpr_registers[idata[24:20]][31] == 0) begin
                        iaddr_b = (gpr_registers[idata[19:15]] <  gpr_registers[idata[24:20]]) ? (iaddr_q + {{20{idata[31]}}, idata[7], idata[30:25], idata[11:8], 1'b0}) : iaddr_q + 4;
                    end
                    else if(gpr_registers[idata[19:15]][31] == 1 && gpr_registers[idata[24:20]][31] == 0) begin
                        iaddr_b = iaddr_q + {{20{idata[31]}}, idata[7], idata[30:25], idata[11:8], 1'b0};
                    end
                    else if(gpr_registers[idata[19:15]][31] == 0 && gpr_registers[idata[24:20]][31] == 1) begin
                        iaddr_b = iaddr_q + 4;
                    end
                    else begin
                        iaddr_b = (gpr_registers[idata[19:15]] <  gpr_registers[idata[24:20]]) ? (iaddr_q + {{20{idata[31]}}, idata[7], idata[30:25], idata[11:8], 1'b0}) : iaddr_q + 4;
                    end

                end

                case5: begin
                    //$display("BGE");
                    we = 0;
                    if(gpr_registers[idata[19:15]][31] == 0 && gpr_registers[idata[24:20]][31] == 0) begin
                        iaddr_b = (gpr_registers[idata[19:15]] >=  gpr_registers[idata[24:20]]) ? (iaddr_q + {{20{idata[31]}}, idata[7], idata[30:25], idata[11:8], 1'b0}) : iaddr_q + 4;
                    end
                    else if(gpr_registers[idata[19:15]][31] == 0 && gpr_registers[idata[24:20]][31] == 1) begin
                        iaddr_b = iaddr_q + {{20{idata[31]}}, idata[7], idata[30:25], idata[11:8], 1'b0};
                    end
                    else if(gpr_registers[idata[19:15]][31] == 1 && gpr_registers[idata[24:20]][31] == 0) begin
                        iaddr_b = iaddr_q + 4;
                    end
                    else begin
                        iaddr_b = (gpr_registers[idata[19:15]] >=  gpr_registers[idata[24:20]]) ? (iaddr_q + {{20{idata[31]}}, idata[7], idata[30:25], idata[11:8], 1'b0}) : iaddr_q + 4;
                    end

                end

                case6: begin
                    //$display("BLTU");
                    we = 0;
                    iaddr_b = (gpr_registers[idata[19:15]] <  gpr_registers[idata[24:20]]) ? (iaddr_q + {{20{idata[31]}}, idata[7], idata[30:25], idata[11:8], 1'b0}) : iaddr_q + 4;
                end

                case7: begin
                    //$display("BGEU");
                    we = 0;
                    iaddr_b = (gpr_registers[idata[19:15]] >  gpr_registers[idata[24:20]]) ? (iaddr_q + {{20{idata[31]}}, idata[7], idata[30:25], idata[11:8], 1'b0}) : iaddr_q + 4;
                end

            endcase


        end

        //U-Type instruction
        else if (flag_u == 1) begin
            dwe = 0;
            if (idata[6:0] == 7'b0110111) begin
                //$display("LUI");
                gpr_rd_add = idata[11:7];
                gpr_data_in = {idata[31:12],{12{1'b0}}};
                we = 1;

            end
            else begin
                //$display("AUIPC");
                gpr_rd_add = idata[11:7];
                gpr_data_in = {idata[31:12],{12{1'b0}}} + iaddr_q;
                we = 1;

            end

        end

        //J-Type instruction
        else  if (idata[6:0] == 7'b1101111 || idata[6:0] == 7'b1100111) begin
            flag_b = 1;
            dwe = 0;
            if (idata[6:0] == 7'b1101111) begin
                //$display("JAL");
                gpr_rd_add = idata[11:7];
                gpr_data_in = iaddr_q + 4;
                iaddr_b = iaddr_q + ({{12{idata[31]}}, idata[19:12], idata[20], idata[30:21], 1'b0});
                we = 1;
            end
            else begin
                //$display("JALR");
                gpr_rd_add = idata[11:7];
                gpr_data_in = iaddr_q + 4;
                iaddr_b = (gpr_registers[idata[19:15]] + {{20{idata[31]}}, idata[31:20]})&(~(32'd1));
                we = 1;
            end

        end

    
    end


    //clocking block (for making registers act like registers)
    always @(posedge clk) begin

        //initialising everything to 0
        if (reset) begin
            //daddr <= 0;
            daddr_q <= 0;
            //dwdata <= 0;
            dwdata_q <= 0;
            //dwe <= 0;
            dwe_q <= 0;
            //iaddr <= 0;
            iaddr_q <= 0;
            //iaddr_b <= 0;
            //gpr_data_in <= 0;
            gpr_data_in_q <= 0;
            //gpr_rd_add <= 0;
            gpr_rd_add_q <= 0;
            // flag_i <= 0;
            // flag_r <= 0;
            // flag_s <= 0;
            // flag_b <= 0;
            // flag_u <= 0;
            flag_i_q <= 0;
            flag_r_q <= 0;
            flag_s_q <= 0;
            flag_b_q <= 0;
            flag_u_q <= 0;
            //we <= 0;
            we_q <= 0;

            for (i = 0; i < 32; i = i + 1) begin
                gpr_registers[i] <= 0;
            end

        end

        else begin

            //transfering values from d-input to q-input of registers
            if (flag_b == 0) begin
                iaddr_q <= iaddr + 4;
            end
            else begin
                iaddr_q <= iaddr_b;
            end

            if(gpr_rd_add == 0) begin
                gpr_registers[gpr_rd_add] <= 0;
            end
            else if (we) begin
                gpr_registers[gpr_rd_add] <= gpr_data_in;
            end
            else begin
                //avoid latching
            end           
            daddr_q <= daddr;
            dwdata_q <= dwdata;
            dwe_q <= dwe;
            gpr_data_in_q <= gpr_data_in;
            gpr_rd_add_q <= gpr_rd_add;
            flag_i_q <= flag_i;
            flag_r_q <= flag_r;
            flag_s_q <= flag_s;
            flag_b_q <= flag_b;
            flag_u_q <= flag_u;
            we_q <= we;

        end
    end


endmodule