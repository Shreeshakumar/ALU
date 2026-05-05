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
	input wire [1:0]INP_VALID,//00_no 01_A 10_B 11_AB VALIDD
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
reg [1:0]cnt = 0;

//temp variables
reg [A-1:0]OPA_1;
reg [B-1:0]OPB_1;
//signed reg
reg signed [A-1:0]sOPA;
reg signed [B-1:0]sOPB;

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
			G <= 0;
			L <= 0;
			E <= 0;
			OFLOW <= 0;
			COUT <= 0;
			ERR <= 0;

			case (CMD)
				4'd0	:	begin	//ADD
								if (INP_VALID == 2'b11)
									{COUT,RES[A-1:0]} <= OPA + OPB;
								else 
									RES <= RES;
							end
				4'd1	:	begin	//SUB
								if (INP_VALID == 2'b11)
								begin
									if(OPB > OPA)
										OFLOW <= 1;
									else
										RES[A-1:0] <= OPA - OPB;
								end
							end
				4'd2	:	begin 	//ADD_CIN
								if (INP_VALID == 2'b11)
									{COUT,RES[A-1:0]} <= OPA + OPB + CIN;
								else 
									RES <= RES;
							end
				4'd3	:	begin	//SUB_CIN
								if (INP_VALID == 2'b11)
								begin
									if((OPB + CIN) > OPA)
										OFLOW <= 1;
									else
										RES[A-1:0] <= OPA - OPB - CIN;
								end							
							end
				4'd4	:	begin 	//INC_A
								if (INP_VALID == 2'b11 || INP_VALID == 2'b01)
									RES[A-1:0] <= OPA + 1;
								else 
									RES <= RES;
							end
				4'd5	:	begin	//DEC_A
								if (INP_VALID == 2'b11 || INP_VALID == 2'b01)
									RES[A-1:0] <= OPA - 1;
								else 
									RES <= RES;
							end
				4'd6	:	begin 	//INC_B
								if (INP_VALID == 2'b11 || INP_VALID == 2'b10)
									RES[A-1:0] <= OPB + 1;
								else 
									RES <= RES;
							end
				4'd7	:	begin	//DEC_B
								if (INP_VALID == 2'b11 || INP_VALID == 2'b10)
									RES[A-1:0] <= OPB - 1;
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
									if (cnt == 0) 	begin	OPA_1 <= OPA + 1; 	cnt <= cnt +1;	end
									else if (cnt == 1)	begin	OPB_1 <= OPB + 1; 	cnt <= cnt +1;	end
									else if (cnt == 2)	begin	RES <= OPA_1 * OPB_1; 	cnt <= 0;	end
								end
							end
				4'd10	:	begin	// A<<1 nA * B
								if( INP_VALID == 2'b11)
									RES <= (OPA <<< 1) * OPB;  
							end
				4'd11	:	begin	//A n B signed A+B
								sOPA = OPA;
								sOPB = OPB;
								{COUT,RES[A-1:0]} <= sOPA + sOPB;
								// msb opa = msb opb is not equal msb res then oflow high
							end
				4'd12	:	begin	//A n B signed A-B
								sOPA = OPA;
								sOPB = OPB;
								RES[A-1:0] <= sOPA - sOPB;
							end	
				default	:	RES <= RES;
			endcase
		end
		else
		// MODE LOW LOGICAL
		begin
			OFLOW <= 0;
			COUT <= 0;
			G <= 0;
			L <= 0;
			E <= 0;

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
										4'b?000	:	RES[A-1:0] <= OPA;
										4'b?001	:	RES[A-1:0] <= {OPA[A-2:0],OPA[A-1:A-1]};
										4'b?010	:	RES[A-1:0] <= {OPA[A-3:0],OPA[A-1:A-2]};
										4'b?011	:	RES[A-1:0] <= {OPA[A-4:0],OPA[A-1:A-3]};
										4'b?100	:	RES[A-1:0] <= {OPA[A-5:0],OPA[A-1:A-4]};
										4'b?101	:	RES[A-1:0] <= {OPA[A-6:0],OPA[A-1:A-5]};
										4'b?110	:	RES[A-1:0] <= {OPA[A-7:0],OPA[A-1:A-6]};
										4'b?111	:	RES[A-1:0] <= {OPA[A-8:0],OPA[A-1:A-7]};
										default :	RES[A-1:0] <= RES;
							         endcase
							     end
					       end
				4'd13	:	begin	//ROR_A_B
								if (INP_VALID == 2'b11)
								begin
									casez(OPB[3:0])
										4'b?000	:	RES[A-1:0] <= OPA;
										4'b?001	:	RES[A-1:0] <= {OPA[A-8:0],OPA[A-1:A-7};
										4'b?010	:	RES[A-1:0] <= {OPA[A-7:0],OPA[A-1:A-6]};
										4'b?011	:	RES[A-1:0] <= {OPA[A-6:0],OPA[A-1:A-5]};
										4'b?100	:	RES[A-1:0] <= {OPA[A-5:0],OPA[A-1:A-4]};
										4'b?101	:	RES[A-1:0] <= {OPA[A-4:0],OPA[A-1:A-3]};
										4'b?110	:	RES[A-1:0] <= {OPA[A-3:0],OPA[A-1:A-2]};
										4'b?111	:	RES[A-1:0] <= {OPA[A-2:0],OPA[A-1:A-1]};
										default :	RES[A-1:0] <= RES;
							         endcase
							     end
							end
				default	:	RES <= RES;
			endcase	
		end
end
end
endmodule
