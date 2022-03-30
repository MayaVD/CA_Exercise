
module forwarding_unit(
      input reg [31:0] instruction_EX,
      input reg [31:0] instruction_MEM,
      input reg [31:0] instruction_WB,
	  input reg		   RegWrite_MEM,
	  input reg		   RegWrite_WB,
      output reg [1:0]      sel_reg1,
      output reg [1:0]      sel_reg2
   );

always @(*) begin

	assign sel_reg1 = 2'd0;
	assign sel_reg2 = 2'd0;

	if (RegWrite_WB == 1'b1 && instruction_WB[11:7] == instruction_EX[19:15]) begin
		assign sel_reg1 = 2'd2;
	end
	if (RegWrite_MEM == 1'b1 && instruction_MEM[11:7] == instruction_EX[19:15]) begin
		assign sel_reg1 = 2'd1;
	end

	if (RegWrite_WB == 1'b1 && instruction_WB[11:7] == instruction_EX[24:20] ) begin
		assign sel_reg2 = 2'd2;
	end
	if (RegWrite_MEM == 1'b1 && instruction_MEM[11:7] == instruction_EX[24:20] ) begin
		assign sel_reg2 = 2'd1;
	end
end

endmodule
