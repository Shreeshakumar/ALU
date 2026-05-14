// ALU_DESIGN
`default_nettype none

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

reg [(A+B)-1:0]RES_temp;
reg ERR_temp,OFLOW_temp,COUT_temp,G_temp,L_temp,E_temp;

//Count reg
	reg [1:0]cnt_9 =0;
	reg [1:0]cnt_10 =0;

//temp variables
reg [A-1:0]OPA_1;
reg [B-1:0]OPB_1;
reg [A-1:0]OPA_L1;

	//signed reg
	wire signed [A-1:0]sOPA = OPA;
	wire signed [B-1:0]sOPB = OPB;
	//signes calculus
	wire signed [A-1:0] s_add = sOPA + sOPB;
	wire signed [A-1:0] s_sub = sOPA - sOPB;
	

always@(posedge CLK or posedge RST)
begin

	if (RST)				// 1st priority
	begin
		ERR_temp <= 0;
		ERR <=0;
		RES_temp <= 0;
		RES <= 0;
		COUT_temp <= 0;
		COUT<=0;
		OFLOW_temp <= 0;
		G_temp <= 0;	L_temp <= 0;	E_temp <= 0;
		G<=0;L<=0;E<=0;
		cnt_9 <= 0;
		cnt_10 <= 0;
	end
	else if (CE)			// 2nd priority
	begin
	RES <= RES_temp;
	ERR<=ERR_temp;
	OFLOW<=OFLOW_temp;
	COUT<=COUT_temp;
	G<=G_temp;
	L<=L_temp;
	E<=E_temp;
			G_temp <= 0;	L_temp <= 0;	E_temp <= 0;
			OFLOW_temp <= 0;
			COUT_temp <= 0;
			ERR_temp <= 0;
			RES_temp <= 0;
			
            if (!(MODE && CMD == 4'd9))  cnt_9  <= 0;
            if (!(MODE && CMD == 4'd10)) cnt_10 <= 0;
		
		if (MODE)			// 3rd priority
		// MODE HIGH ARITHMETIC
		begin
			
			case (CMD)
				4'd0	:	begin	//ADD
								if (INP_VALID == 2'b11)
									{COUT_temp,RES_temp[A-1:0]} <= OPA + OPB;
								else begin	RES_temp <= 0;	ERR_temp <= 1;	end
							end
				4'd1	:	begin	//SUB
								if (INP_VALID == 2'b11)
								begin
									if(OPB > OPA)
									begin
										OFLOW_temp <= 1;
										RES_temp[A-1:0] <= OPA - OPB;
									end
									else
										RES_temp[A-1:0] <= OPA - OPB;
								end
								else
									begin	ERR_temp <= 1;	RES_temp <= 0;	end
							end
				4'd2	:	begin 	//ADD_CIN
								if (INP_VALID == 2'b11)
									{COUT_temp,RES_temp[A-1:0]} <= OPA + OPB + CIN;
								else begin	ERR_temp <= 1;	RES_temp <= 0;	end
							end
				4'd3	:	begin	//SUB_CIN
								if (INP_VALID == 2'b11)
								begin
									if((OPB + CIN) > OPA)
									begin
										OFLOW_temp <= 1;
										RES_temp[A-1:0] <= OPA - OPB - CIN;
									end
									else
										RES_temp[A-1:0] <= OPA - OPB - CIN;
								end	
								else begin	ERR_temp <= 1;	RES_temp <= 0;	end
							end
				4'd4	:	begin 	//INC_A
								if (INP_VALID == 2'b11 || INP_VALID == 2'b01)
									RES_temp[A-1:0] <= OPA + 1;
								else begin	ERR_temp <= 1;	RES_temp <= 0;	end
							end
				4'd5	:	begin	//DEC_A
								if (INP_VALID == 2'b11 || INP_VALID == 2'b01)
									RES_temp[A-1:0] <= OPA - 1;
								else begin	ERR_temp <= 1; 	RES_temp <= 0;	end
							end
				4'd6	:	begin 	//INC_B
								if (INP_VALID == 2'b11 || INP_VALID == 2'b10)
									RES_temp[A-1:0] <= OPB + 1;
								else begin ERR_temp <= 1;	RES_temp <= 0;	end
							end
				4'd7	:	begin	//DEC_B
								if (INP_VALID == 2'b11 || INP_VALID == 2'b10)
									RES_temp[A-1:0] <= OPB - 1;
								else begin	ERR_temp <= 1;	RES_temp <= 0;	end
							end
				4'd8	:	begin	//CMP
								if (INP_VALID == 2'b11)
									begin
										E_temp <= (OPA == OPB);
										L_temp <= (OPA < OPB);
										G_temp <= (OPA > OPB);
										RES_temp <= 0;
									end
								else begin	ERR_temp <= 1;	RES_temp <= 0;	end
							end
				4'd9	:	begin	// A+1 B+1 nA * nB
								if (INP_VALID == 2'b11)
								begin
									if (cnt_9 == 0)	begin	OPA_1 <= OPA + 1; OPB_1 <= OPB + 1; RES_temp <= RES_temp;	cnt_9 <= cnt_9 +1;	end
									else if (cnt_9 == 1)	begin	RES_temp <= OPA_1 * OPB_1; 	cnt_9 <= 0;	end
									else cnt_9 <= 0;
								end
								else begin 	ERR_temp <= 1; 	RES_temp <= 0;	end
							end
				4'd10	:	begin	// A<<1 nA * B
								if (INP_VALID == 2'b11)
								begin
									if (cnt_10 == 0)	begin	OPA_L1 <= OPA << 1; RES_temp <= RES_temp;	cnt_10 <= cnt_10 +1;	end
									else if (cnt_10 == 1)	begin	RES_temp <= OPA_L1 * OPB; 	cnt_10 <= 0;	end
									else cnt_10 <= 0;
								end
								else begin	ERR_temp <= 1;	RES_temp <= 0;	end
							end
				4'd11	:	begin	//A n B signed A+B
								if( INP_VALID == 2'b11)
									begin
										RES_temp[A-1:0] <= s_add[A-1:0];
										OFLOW_temp <= ( (OPA[A-1] == OPB[A-1]) && (s_add[A-1] != OPA[A-1]) );
									end// msb opa = msb opb msb opa is not equal msb res then oflow high
								else	begin	ERR_temp <= 1;	RES_temp <= 0;	end
							end
				4'd12	:	begin	//A n B signed A-B
								if( INP_VALID == 2'b11)
									begin
										RES_temp[A-1:0] <= s_sub[A-1:0];
										OFLOW_temp <= ( (OPA[A-1] != OPB[A-1]) && (s_sub[A-1] != OPA[A-1]) );
									end// msb opa ~= msb opb msb opa is not equal msb res then oflow high
								else	begin	ERR_temp <= 1;	RES_temp <= 0;	end
							end	
				default	:	begin ERR_temp <= 1; RES_temp <= 0;	end
			endcase
		end
		else
		// MODE LOW LOGICAL
		begin
		RES <= RES_temp;
			case (CMD)
				4'd0	:	begin 	//AND
								if (INP_VALID == 2'b11)
									RES_temp <= OPA & OPB;
								else begin	ERR_temp <= 1;	RES_temp <= 0;	end
							end
				4'd1	:	begin	//NAND
								if (INP_VALID == 2'b11)
									RES_temp <= ~(OPA & OPB);
								else	begin	ERR_temp <= 1;	RES_temp <= 0;	end
							end
				4'd2	:	begin	//OR
								if (INP_VALID == 2'b11)
									RES_temp <= OPA | OPB;
								else begin 	ERR_temp <= 1;	RES_temp <= 0;	end
							end
				4'd3	:	begin 	//NOR
								if (INP_VALID == 2'b11)
									RES_temp <= ~(OPA | OPB);
								else begin 	ERR_temp <= 1;	RES_temp <= 0;	end
							end
								
				4'd4	:	begin	//XOR
								if (INP_VALID == 2'b11)
									RES_temp <= OPA ^ OPB;
								else begin	ERR_temp <= 1;	RES_temp <= 0;	end
							end
				4'd5	:	begin	//XNOR
								if (INP_VALID == 2'b11)
									RES_temp <= ~(OPA ^ OPB);
								else begin	ERR_temp <= 1;	RES_temp <= 0;	end
							end
				4'd6	:	begin	//NOT_A
								if (INP_VALID == 2'b11 || INP_VALID == 2'b01)
									RES_temp <= ~OPA;
								else begin	ERR_temp <= 1;	RES_temp <= 0;	end
							end
				4'd7	:	begin 	//NOT_B
								if (INP_VALID == 2'b11 || INP_VALID == 2'b10)
									RES_temp <= ~OPB;
								else begin	ERR_temp <= 1;	RES_temp <= 0;	end
							end
				4'd8	:	begin	//SHR1_A
								if (INP_VALID == 2'b11 || INP_VALID == 2'b01)
									RES_temp <= OPA >> 1;
								else begin	ERR_temp <= 1;	RES_temp <= 0;	end
							end
				4'd9	:	begin	//SHL1_A
								if (INP_VALID == 2'b11 || INP_VALID == 2'b01)
									RES_temp <= OPA << 1;
								else begin	ERR_temp <= 1;	RES_temp <= 0;	end
							end
				4'd10	:	begin	//SHR1_B
								if (INP_VALID == 2'b11 || INP_VALID == 2'b10)
									RES_temp <= OPB >> 1;
								else begin	ERR_temp <= 1;	RES_temp <= 0;	end
							end
				4'd11	:	begin	//SHL1_B
								if (INP_VALID == 2'b11 || INP_VALID == 2'b10)
									RES_temp <= OPB << 1;
								else begin	ERR_temp <= 1;	RES_temp <= 0;	end
							end
				4'd12	:	begin	//ROL_A_B
								if (INP_VALID == 2'b11)
								begin
									casez(OPB[2:0])
										'b000	:	RES_temp[A-1:0] <= OPA;
										'b001	:	RES_temp[A-1:0] <= {OPA[A-2:0],OPA[A-1]};
										'b010	:	RES_temp[A-1:0] <= {OPA[A-3:0],OPA[A-1:A-2]};
										'b011	:	RES_temp[A-1:0] <= {OPA[A-4:0],OPA[A-1:A-3]};
										'b100	:	RES_temp[A-1:0] <= {OPA[A-5:0],OPA[A-1:A-4]};
										'b101	:	RES_temp[A-1:0] <= {OPA[A-6:0],OPA[A-1:A-5]};
										'b110	:	RES_temp[A-1:0] <= {OPA[A-7:0],OPA[A-1:A-6]};
										'b111	:	RES_temp[A-1:0] <= {OPA[A-8:0],OPA[A-1:A-7]};
										default :	RES_temp[A-1:0] <= 0;
							         endcase
									ERR_temp <= (OPB[B-1:4])?1:0;
							     end
								else	begin	ERR_temp <= 1; RES_temp <= 0; end
					       end
				4'd13	:	begin	//ROR_A_B
								if (INP_VALID == 2'b11)
								begin
									casez(OPB[2:0])
										'b000	:	RES_temp[A-1:0] <= OPA;										
										'b001 : RES_temp[A-1:0] <= {OPA[0],   OPA[A-1:1]};
										'b010 : RES_temp[A-1:0] <= {OPA[1:0], OPA[A-1:2]};
										'b011 : RES_temp[A-1:0] <= {OPA[2:0], OPA[A-1:3]};
										'b100 : RES_temp[A-1:0] <= {OPA[3:0], OPA[A-1:4]};
										'b101 : RES_temp[A-1:0] <= {OPA[4:0], OPA[A-1:5]};
										'b110 : RES_temp[A-1:0] <= {OPA[5:0], OPA[A-1:6]};
										'b111 : RES_temp[A-1:0] <= {OPA[6:0], OPA[A-1:7]};
										default :	RES_temp[A-1:0] <= 0;
							         endcase
									ERR_temp <= (OPB[B-1:4])?1:0;
							     end
								else	begin	ERR_temp <= 1; RES_temp <= 0; end
							end
				default	:	begin 	ERR_temp <= 1; RES_temp <= 0;	end
			endcase	
		end
end
end
endmodule
