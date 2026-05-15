module alu_reference_model(
	input CE,
	input [1:0]INP_VALID,
    input [7:0] OPA, OPB,
    input CIN, MODE,
    input [3:0] CMD,
	output reg [15:0] RES,
    output reg COUT, OFLOW, G, E, L, ERR
);

	//signed reg
	wire signed [7:0]sOPA = OPA;
	wire signed [7:0]sOPB = OPB;
	//signes calculus
	wire signed [15:0] s_add = sOPA + sOPB;
	wire signed [15:0] s_sub = sOPA - sOPB;
	
    always @(*) begin
        // Default values
        RES = 16'b0;
        COUT = 1'b0;
        OFLOW = 1'b0;
        G = 1'b0;
        E = 1'b0;
        L = 1'b0;
        ERR = 1'b0;

		if (CE)
		begin
        if (MODE) 
		begin  // Arithmetic Mode
			if (INP_VALID == 2'b00)	//both invalid
				begin RES = 0; ERR = 1;	end
			else 
			if (INP_VALID == 2'b11)
				begin	
					case(CMD)
                	4'b0000: 	begin  // ADD
                    			RES = OPA + OPB;
								COUT = RES[8];
                				end
					4'b0001: 	begin  // SUB
                    			OFLOW = (OPA < (OPB + CIN));
								RES = OPA - OPB;
                				end
					4'b0010: 	begin  // ADD_CIN
                    			RES = OPA + OPB + CIN;
								COUT = RES[8];
                				end
					4'b0011:	begin  // SUB_CIN
								OFLOW = (OPA < (OPB + CIN));
								RES = OPA - OPB - CIN;
                				end
					4'b0100: 	RES = OPA + 8'd1;  // INC_A
                	4'b0101: 	RES = OPA - 8'd1;  // DEC_A
					4'b0110: 	RES = OPB + 8'd1;  // INC_B
					4'b0111: 	RES = OPB - 8'd1;  // DEC_B
					4'b1000: 	begin  // CMP                    			
								if (OPA == OPB) begin	E = 1'b1; G = 1'b0; L = 1'b0;	end 
								else if (OPA > OPB) begin	E = 1'b0; G = 1'b1; L = 1'b0;end 
								else  begin	E = 1'b0; G = 1'b0; L = 1'b1;	end
								//else begin	E = 1'b0; G = 1'b0; L = 1'b0;	end
                				end
					4'd9	:	begin	// A+1 B+1 nA * nB
						RES = ((OPA + 1'b1) * (OPB + 1'b1)); 
								end
					4'd10	:	begin	// A<<1 nA * B
									RES = (OPA << 1) * OPB; 
								end
					4'd11	:	begin	//A n B signed A+B
										RES = s_add;
										OFLOW = ( (OPA[7] == OPB[7]) && (s_add[7] != OPA[7]) );
									end// msb opa = msb opb msb opa is not equal msb res then oflow high
						
					4'd12	:	begin	//A n B signed A-B
										RES = s_sub;
										OFLOW = ( (OPA[7] != OPB[7]) && (s_sub[7] != OPA[7]) );
									end// msb opa ~= msb opb msb opa is not equal msb res then oflow high
					default	:	begin	RES = 0;	ERR = 1;	end
					endcase	
				end
			else if (INP_VALID == 2'b01)	//only a or ab valid
				begin 
				case(CMD)
					4'b0100: 	RES = OPA + 1;  // INC_A
                	4'b0101: 	RES = OPA - 1;  // DEC_A
					default	:	begin	RES = 0;	ERR = 1;	end
				endcase 
				end
			else if (INP_VALID == 2'b10 )	//only b or ab valid
				begin 
				case(CMD)
					4'b0110: 	RES = OPB + 1;  // INC_B
					4'b0111: 	RES = OPB - 1;  // DEC_B
					default	:	begin	RES = 0;	ERR = 1;	end
				endcase 
				end
			else begin	RES = 0;	ERR = 1;	end
		end
					
        else begin  // Logical Mode
			if (INP_VALID == 2'b00)	//both invalid
				begin RES = 0; ERR = 1;	end
			else
			if (INP_VALID == 2'b11)
				begin 
					case(CMD)
						4'b0000: RES[7:0] =  OPA & OPB;       // AND
						4'b0001: RES[7:0] =  ~(OPA & OPB);    // NAND
						4'b0010: RES[7:0] =  OPA | OPB;       // OR
						4'b0011: RES[7:0] =  ~(OPA | OPB);    // NOR
						4'b0100: RES[7:0] =  OPA ^ OPB;       // XOR
						4'b0101: RES[7:0] =  ~(OPA ^ OPB);    // XNOR
						4'b0110: RES[7:0] =  ~OPA;       // NOT_A
						4'b0111: RES[7:0] =  ~OPB;    // NOT_B
						4'b1000: RES[7:0] =  OPA >> 1;      // SHR1_A
						4'b1001: RES[7:0] =  OPA << 1;      // SHL1_A
						4'b1010: RES[7:0] = OPB >> 1;   // SHR1_B
						4'b1011: RES[7:0] = OPB << 1;   // SHL1_B
						4'b1100: begin  // ROL_A_B
									case(OPB[2:0])
										'b000	:	RES[7:0] = OPA;
										'b001	:	RES[7:0] = {OPA[6:0],OPA[7]};
										'b010	:	RES[7:0] = {OPA[5:0],OPA[7:6]};
										'b011	:	RES[7:0] = {OPA[4:0],OPA[7:5]};
										'b100	:	RES[7:0] = {OPA[3:0],OPA[7:4]};
										'b101	:	RES[7:0] = {OPA[2:0],OPA[7:3]};
										'b110	:	RES[7:0] = {OPA[1:0],OPA[7:2]};
										'b111	:	RES[7:0] = {OPA[0],OPA[7:1]};
										default :	RES[7:0] = 0;
							         endcase
									ERR = (OPB[7:4])?1:0;
							     end
                		4'b1101: begin  // ROR_A_B
									case(OPB[2:0])
										'b000	:	RES[7:0] = OPA;										
										'b001 : RES[7:0] = {OPA[0],   OPA[7:1]};
										'b010 : RES[7:0] = {OPA[1:0], OPA[7:2]};
										'b011 : RES[7:0] = {OPA[2:0], OPA[7:3]};
										'b100 : RES[7:0] = {OPA[3:0], OPA[7:4]};
										'b101 : RES[7:0] = {OPA[4:0], OPA[7:5]};
										'b110 : RES[7:0] = {OPA[5:0], OPA[7:6]};
										'b111 : RES[7:0] = {OPA[6:0], OPA[7:7]};
										default :	RES[7:0] = 0;
							         endcase
									ERR = (OPB[7:4])?1:0;
							     end
						default	:	begin	RES = 0;	ERR = 1;	end
					endcase 
				end
			else if (INP_VALID == 2'b01 )	//only a or ab valid
				begin 
					case(CMD)
						4'b0110: RES[7:0] = ~OPA;            // NOT_A
						4'b1000: RES[7:0] = OPA >> 1;        // SHR1_A
						4'b1001: RES[7:0] = OPA << 1;        // SHL1_A
						default	:	begin	RES = 0;	ERR = 1;	end
					endcase 
				end
			else if (INP_VALID == 2'b10 )	//only b or ab valid
				begin 
					case(CMD)
						4'b0111: RES = {8'b0, ~OPB};            // NOT_B
                		4'b1010: RES = {8'b0, OPB >> 1};        // SHR1_B
                		4'b1011: RES = {8'b0, OPB << 1};        // SHL1_B
						default	:	begin	RES = 0;	ERR = 1;	end
					endcase 
				end
			else begin	RES = 0;	ERR = 1;	end
			end
		end
	end

endmodule
