// ALU_DESIGN

module alu_design #(
//PARAMETERS
parameter A = 8,
parameter B = 8,
parameter C = 4
)
//INPUT OUTPUTS
(
	//Contoelpins
	input wire CLK, RST,
	input wire [1:0]INP_VALID,//00_no 01_A 10_B 11_AB VALID
	input wire MODE,// 1 arithmetic 0 logical
	input wire [C-1:0]CMD,
	input wire CE,
	
	// Data pins
	input wire [A-1:0]OPA, 
	input wire [B-1:0]OPB,
	input wire CIN,
	
	// Outputs
	output reg ERR,
	output reg [(A+B)-1:0]RES,
	output reg OFLOW,COUT,G,L,E
);

//Count reg
reg cnt = 0;

always@(posedge CLK or posedge RST)
begin

	if (RST)				// 1st priority
	begin
		ERR <= 0;
		RES <= 0;
		OFLOW <= 0;
		G <= 0;
		L <= 0;
		E <= 0;
		cnt <= 0;
	end
	else if (CE)			// 2nd priority
	begin
		if (MODE)			// 3rd priority
		// MODE HIGH ARITHMETIC
		begin
			case (CMD)
				4'd0	:	begin	//ADD
								if (INP_VALID == 2'b11)
									RES <= OPA + OPB;
								else 
									RES <= RES;
							end
				4'd1	:	begin	//SUB
								if (INP_VALID == 2'b11)
									RES <= OPA - OPB;
								else 
									RES <= RES;
							end
				4'd2	:	begin 	//ADD_CIN
								if (INP_VALID == 2'b11)
									RES <= CIN + OPA + OPB;
								else 
									RES <= RES;
							end
				4'd3	:	begin	//SUB_CIN
								if (INP_VALID == 2'b11)
									RES <= CIN - OPA - OPB;
								else 
									RES <= RES;
							end
				4'd4	:	begin 	//INC_A
								if (INP_VALID == 2'b11 || INP_VALID == 2'b01)
									RES <= OPA + 1;
								else 
									RES <= RES;
							end
				4'd5	:	begin	//DEC_A
								if (INP_VALID == 2'b11 || INP_VALID == 2'b01)
									RES <= OPA - 1;
								else 
									RES <= RES;
							end
				4'd6	:	begin 	//INC_B
								if (INP_VALID == 2'b11 || INP_VALID == 2'b10)
									RES <= OPB + 1;
								else 
									RES <= RES;
							end
				4'd7	:	begin	//DEC_B
								if (INP_VALID == 2'b11 || INP_VALID == 2'b10)
									RES <= OPB - 1;
								else 
									RES <= RES;
							end
				4'd8	:	begin	//CMP
								if (INP_VALID == 2'b11)
								begin
									if (OPA == OPB)
										E <= 1;
									else if (OPA < OPB)
										L <= 1;
									else 
										G <= 1;
								end
								else 
									RES <= RES;
							end
				4'd9	:	begin	// A+1 B+1 nA * nB
								if (INP_VALID == 2'b11)
								begin
									RES <= (OPA + 1) * (OPB + 1);
								end
							end
				4'd10	:	begin	// A<<1 nA * B
								if( INP_VALID == 2'b11)
									RES <= (OPA <<< 1) * OPB;  
							end
				4'd11	:	begin	//A n B signed A+B
							end
				4'd12	:	begin	//A n B signed A-B
							end	
				default	:	RES = RES;
			endcase
		end
		else
		// MODE LOW LOGICAL
		begin
			case (CMD)
				4'd0	:	begin 	//AND
								if (INP_VALID == 2'b11)
									RES <= OPA & OPB;
								else 
									RES <= RES;
							end
				4'd1	:	begin	//NAND
								if (INP_VALID == 2'b11)
									RES <= ~(OPA & OPB);
								else
									RES <= RES;
							end
				4'd2	:	begin	//OR
								if (INP_VALID == 2'b11)
									RES <= OPA | OPB;
								else 
									RES <= RES;
							end
				4'd3	:	begin 	//NOR
								if (INP_VALID == 2'b11)
									RES <= ~(OPA | OPB);
								else 
									RES <= RES;
							end
								
				4'd4	:	begin	//XOR
								if (INP_VALID == 2'b11)
									RES <= OPA ^ OPB;
								else 
									RES <= RES;
							end
				4'd5	:	begin	//XNOR
								if (INP_VALID == 2'b11)
									RES <= OPA ~^ OPB;
								else 
									RES <= RES;
							end
				4'd6	:	begin	//NOT_A
								if (INP_VALID == 2'b11 || INP_VALID == 2'b01)
									RES <= ~OPA;
								else 
									RES <= RES;
							end
				4'd7	:	begin 	//NOT_B
								if (INP_VALID == 2'b11 || INP_VALID == 2'b10)
									RES <= ~OPB;
								else 
									RES <= RES;
							end
				4'd8	:	begin	//SHR1_A
								if (INP_VALID == 2'b11 || INP_VALID == 2'b01)
									RES <= OPA >> 1;
								else 
									RES <= RES;
							end
							
				4'd9	:	begin	//SHL1_A
								if (INP_VALID == 2'b11 || INP_VALID == 2'b01)
									RES <= OPA << 1;
								else 
									RES <= RES;
							end
				4'd10	:	begin	//SHR1_B
								if (INP_VALID == 2'b11 || INP_VALID == 2'b10)
									RES <= OPB >> 1;
								else 
									RES <= RES;
							end
				4'd11	:	begin	//SHL1_B
								if (INP_VALID == 2'b11 || INP_VALID == 2'b10)
									RES <= OPB << 1;
								else 
									RES <= RES;
							end
				4'd12	:	begin	//ROL_A_B
								if (INP_VALID == 2'b11)
								begin
									casez(OPB[3:0])
										4'b?000	:	RES <= OPA;
										4'b?001	:	RES <= {OPA[6:0],OPA[7]};
										4'b?010	:	RES <= {OPA[5:0],OPA[7:6]};
										4'b?011	:	RES <= {OPA[4:0],OPA[7:5]};
										4'b?100	:	RES <= {OPA[3:0],OPA[7:4]};
										4'b?101	:	RES <= {OPA[2:0],OPA[7:3]};
										4'b?110	:	RES <= {OPA[1:0],OPA[7:2]};
										4'b?111	:	RES <= {OPA[0],OPA[7:1]};
										default :	RES <= RES;
							         endcase
							     end
					       end
				4'd13	:	begin	//ROR_A_B
								if (INP_VALID == 2'b11)
								begin
									casez(OPB[3:0])
										4'b?000	:	RES <= OPA;
										4'b?001	:	RES <= {OPA[0],OPA[7:1]};
										4'b?010	:	RES <= {OPA[1:0],OPA[7:2]};
										4'b?011	:	RES <= {OPA[2:0],OPA[7:3]};
										4'b?100	:	RES <= {OPA[3:0],OPA[7:4]};
										4'b?101	:	RES <= {OPA[4:0],OPA[7:5]};
										4'b?110	:	RES <= {OPA[5:0],OPA[7:6]};
										4'b?111	:	RES <= {OPA[6:0],OPA[7]};
										default :	RES <= RES;
							         endcase
							     end
							end
				default	:	RES <= RES;
			endcase	
		end
end
end
endmodule
