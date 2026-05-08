//`timescale 1ns / 1ps

module Eight_bit_ALU_rtl_design #(
    parameter width = 8, 
    parameter cmd_width = 4, 
    parameter out_width = 2*width 
) (
    input [(width-1):0] OPA, OPB,
    input CLK, RST, CE, MODE, CIN,
    input [1:0] inp_valid,
    input [(cmd_width-1):0] CMD,
    
    output reg [(out_width-1):0] RES,
    output reg COUT, OFLOW, G, E, L, ERR
);
    
    reg signed [(out_width-1):0] temp_signed;
    reg [(out_width-1):0] temp_res;
    reg temp_cout, temp_oflow, temp_g, temp_e, temp_l, temp_err;
    reg signed [width-1:0] A_signed, B_signed;
    integer count = 1;
    integer count1 = 1;

    
    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            RES <= 0; COUT <= 0; OFLOW <= 0; G <= 0; E <= 0; L <= 0; ERR <= 0;
        end else if (CE) begin
            if (MODE && (CMD == 4'b1001)) begin
                if (count == 3) begin 
                RES <= temp_res; 
                ERR <= temp_err; end
                else if(count == 2) 
                RES <= {out_width{1'bx}};
            end 
            else if (MODE && (CMD == 4'b1010)) begin
                if (count1 == 3) begin 
                RES <= temp_res;
                 ERR <= temp_err; end
                else if(count1 == 2) 
                RES <= {out_width{1'bx}};
            end
            
            else begin
                RES   <= temp_res;
                COUT  <= temp_cout;
                OFLOW <= temp_oflow;
                G     <= temp_g;
                E     <= temp_e;
                L     <= temp_l;
                ERR   <= temp_err;
            end
        end
    end

    always @(*) begin
        temp_res = 0;
         temp_cout = 0;
          temp_oflow = 0;
        temp_g = 0;
         temp_e = 0; 
         temp_l = 0; 
         temp_err = 0;
        temp_signed = 0;
        A_signed = 0;
         B_signed = 0;

        if (MODE) begin
            case (CMD)
                4'b0000: begin // CMD 0: ADD
                    if(inp_valid == 2'b11) begin
                        temp_res = OPA + OPB;
                        temp_cout = temp_res[width]; 
                    end else temp_err = 1'b1;
                end
                
                4'b0001: begin // CMD 1: SUB
                    if(inp_valid == 2'b11) begin
                        temp_res = OPA - OPB;
                        temp_oflow = (OPA < OPB);
                    end else temp_err = 1'b1;
                end
                
                4'b0010: begin // CMD 2: ADD_CIN
                    if(inp_valid == 2'b11) begin
                        temp_res = OPA + OPB + CIN;
                        temp_cout = temp_res[width];
                    end else temp_err = 1'b1;
                end
                
                4'b0011: begin // CMD 3: SUB_CIN
                    if(inp_valid == 2'b11) begin
                        temp_res = OPA - OPB - CIN;
                        temp_oflow = (OPA < (OPB + CIN));
                    end else temp_err = 1'b1;
                end
                4'b0100: if(inp_valid[0]) 
                            temp_res = OPA + 1'b1;
                        else 
                            temp_err = 1'b1;
                4'b0101: if(inp_valid[0]) 
                            temp_res = OPA - 1'b1;
                        else
                            temp_err = 1'b1;
                4'b0110: if(inp_valid[1])
                            temp_res = OPB + 1'b1;
                        else
                            temp_err = 1'b1;
                4'b0111: if(inp_valid[1])
                            temp_res = OPB - 1'b1;
                        else
                            temp_err = 1'b1;
                4'b1000: if(inp_valid == 2'b11) begin
                            temp_e = (OPA == OPB); 
                            temp_g = (OPA > OPB); 
                            temp_l = (OPA < OPB);
                         end 
                        else
                            temp_err = 1'b1;
                4'b1001: if(inp_valid == 2'b11) 
                                temp_res = (OPA + 1'b1) * (OPB + 1'b1); 
                            else
                                temp_err = 1'b1;
                4'b1010: if(inp_valid == 2'b11) 
                                temp_res = (OPA << 1) * OPB;
                            else
                                temp_err = 1'b1;
                4'b1011: if(inp_valid == 2'b11) begin 
                            A_signed = OPA; 
                            B_signed = OPB;
                            temp_signed = A_signed + B_signed;
                             temp_res = temp_signed;
                            temp_oflow = temp_res[width-1];
                            temp_e = (A_signed == B_signed);
                             temp_l = (A_signed < B_signed);
                              temp_g = (A_signed > B_signed);
                         end 
                         else
                             temp_err = 1'b1;
                4'b1100: if(inp_valid == 2'b11) begin 
                            A_signed = OPA;
                             B_signed = OPB;
                            temp_signed = A_signed - B_signed; 
                            temp_res = temp_signed;
                            temp_oflow = temp_res[width-1];
                            temp_e = (A_signed == B_signed);
                            temp_l = (A_signed < B_signed);
                            temp_g = (A_signed > B_signed);
                         end
                          else 
                            temp_err = 1'b1;
                default: temp_err = 1'b1;
            endcase
        end 
        else begin
            case (CMD)
                4'b0000: if(inp_valid == 2'b11) 
                             temp_res = {{width{1'b0}}, OPA & OPB};
                         else
                             temp_err = 1'b1;
                4'b0001: if(inp_valid == 2'b11)
                             temp_res = {{width{1'b0}}, ~(OPA & OPB)}; 
                         else
                             temp_err = 1'b1;
                4'b0010: if(inp_valid == 2'b11)
                             temp_res = {{width{1'b0}}, OPA | OPB};
                         else   
                             temp_err = 1'b1;
                4'b0011: if(inp_valid == 2'b11)
                             temp_res = {{width{1'b0}}, ~(OPA | OPB)};
                         else
                             temp_err = 1'b1;
                4'b0100: if(inp_valid == 2'b11) 
                             temp_res = {{width{1'b0}}, OPA ^ OPB};
                         else
                             temp_err = 1'b1;
                4'b0101: if(inp_valid == 2'b11)
                             temp_res = {{width{1'b0}}, ~(OPA ^ OPB)};
                         else
                             temp_err = 1'b1;
                4'b0110: if(inp_valid[0])
                             temp_res = {{width{1'b0}}, ~OPA};
                         else   
                             temp_err = 1'b1;
                4'b0111: if(inp_valid[1])
                             temp_res = {{width{1'b0}}, ~OPB}; 
                         else
                             temp_err = 1'b1;
                4'b1000: if(inp_valid[0])
                             temp_res = {{width{1'b0}}, OPA >> 1};
                         else
                             temp_err = 1'b1;
                4'b1001: if(inp_valid[0])
                             temp_res = {{width{1'b0}}, OPA << 1}; 
                        else
                             temp_err = 1'b1;
                4'b1010: if(inp_valid[1])
                             temp_res = {{width{1'b0}}, OPB >> 1};
                        else
                             temp_err = 1'b1;
                4'b1011: if(inp_valid[1])
                             temp_res = {{width{1'b0}}, OPB << 1};
                        else    
                             temp_err = 1'b1;
                4'b1100: if(inp_valid == 2'b11) begin
                            if (|OPB[(width-1):3]) temp_err = 1'b1; 
                            else temp_res = {{width{1'b0}}, (OPA << OPB[2:0]) | (OPA >> (width - OPB[2:0]))};
                         end else temp_err = 1'b1;
                4'b1101: if(inp_valid == 2'b11) begin
                            if (|OPB[(width-1):3]) temp_err = 1'b1; 
                            else temp_res = {{width{1'b0}}, (OPA >> OPB[2:0]) | (OPA << (width - OPB[2:0]))};
                         end else temp_err = 1'b1;
                default: temp_err = 1'b1;
            endcase
        end
    end

    always @(posedge CLK or posedge RST) begin
        if (RST) count <= 1;
        else if (CE && MODE && CMD == 4'b1001)
             count <= (count >= 3) ? 1 : count + 1;
        else count <= 1;
    end

    always @(posedge CLK or posedge RST) begin
        if (RST) count1 <= 1;
        else if (CE && MODE && CMD == 4'b1010)
             count1 <= (count1 >= 3) ? 1 : count1 + 1;
        else count1 <= 1;
    end

endmodule
