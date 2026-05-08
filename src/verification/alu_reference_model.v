module alu_reference_model(
	input CE,
	input [1:0]INP_VALID,
    input [7:0] OPA, OPB,
    input CIN, MODE,
    input [3:0] CMD,
    output reg [16:0] RES,
    output reg COUT, OFLOW, G, E, L, ERR
);

    reg [7:0] OPA_1, OPB_1;
	integer i;

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
                    			{COUT,RES[7:0]} = OPA + OPB;
                				end
					4'b0001: 	begin  // SUB
                    			OFLOW = (OPA < OPB);
								RES[7:0] = OPA - OPB;
                				end
					4'b0010: 	begin  // ADD_CIN
                    			{COUT,RES[7:0]} = OPA + OPB + CIN;
                				end
					4'b0011:	begin  // SUB_CIN
                    			OFLOW = (OPA < OPB);
								RES[7:0] = OPA - OPB - CIN;
                				end
					4'b1000: 	begin  // CMP                    			
								if (OPA == OPB) begin	E = 1'b1; G = 1'b0; L = 1'b0;	end 
								else if (OPA > OPB) begin	E = 1'b0; G = 1'b1; L = 1'b0;end 
								else if (OPA < OPB) begin	E = 1'b0; G = 1'b0; L = 1'b1;	end
								else begin	E = 1'b0; G = 1'b0; L = 1'b0;	end
                				end
					endcase
				end
			else if (INP_VALID == 2'b01 || INP_VALID == 2'b11)	//only a or ab valid
				begin
				case(CMD)
					4'b0100: 	RES[7:0] = OPA + 1;  // INC_A
                	4'b0101: 	RES[7:0] = OPA - 1;  // DEC_A
				endcase
				end
			else if (INP_VALID == 2'b10 || INP_VALID == 2'b11)	//only b or ab valid
				begin
				case(CMD)
					4'b0110: 	RES[7:0] = OPB + 1;  // INC_B
					4'b0111: 	RES[7:0] = OPB - 1;  // DEC_B
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
						4'b0000: RES[7:0] = OPA & OPB;       // AND
                		4'b0001: RES[7:0] = ~(OPA & OPB);    // NAND
		                4'b0010: RES[7:0] = OPA | OPB;       // OR
                		4'b0011: RES[7:0] = ~(OPA | OPB);    // NOR
						4'b0100: RES[7:0] = OPA ^ OPB;       // XOR
                		4'b0101: RES[7:0] = ~(OPA ^ OPB);    // XNOR
						4'b1100: begin  // ROL_A_B
									ERR = (OPB[7:4])?1:0;
                    				for( i = 0; i < 8; i = i + 1)
										RES[i] = OPA[(i - OPB[2:0] + 8) % 8];
                				end
                		4'b1101: begin  // ROR_A_B
									ERR = (OPB[7:4])?1:0;
									for( i = 0; i < 8; i = i + 1)
        								RES[i] = OPA[(i + OPB[2:0]) % 8];
                				end
					endcase
				end
			else if (INP_VALID == 2'b01 || INP_VALID == 2'b11)	//only a or ab valid
				begin
					case(CMD)
						4'b0110: RES[7:0] = ~OPA;            // NOT_A
						4'b1000: RES[7:0] = OPA >> 1;        // SHR1_A
						4'b1001: RES[7:0] = OPA << 1;        // SHL1_A
					endcase
				end
			else if (INP_VALID == 2'b10 || INP_VALID == 2'b11)	//only b or ab valid
				begin
					case(CMD)
						4'b0111: RES = {8'b0, ~OPB};            // NOT_B
                		4'b1010: RES = {8'b0, OPB >> 1};        // SHR1_B
                		4'b1011: RES = {8'b0, OPB << 1};        // SHL1_B
					endcase
				end
			else begin	RES = 0;	ERR = 1;	end
			end
		end
	end

endmodule
