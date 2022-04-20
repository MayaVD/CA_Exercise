
module forwarding_unit(
      input wire [31:0] instruction_EX,
      input wire [31:0] instruction_MEM,
      input wire [31:0] instruction_WB,
	  input wire		   RegWrite_MEM,
	  input wire		   RegWrite_WB,
      output reg [1:0]      sel_reg1,
      output reg [1:0]      sel_reg2
   );

always @(*) begin

	sel_reg1 = 2'd0;
	sel_reg2 = 2'd0;

	if (RegWrite_WB == 1'b1 && instruction_WB[11:7] == instruction_EX[19:15]) begin
		sel_reg1 = 2'd2;
	end
	if (RegWrite_MEM == 1'b1 && instruction_MEM[11:7] == instruction_EX[19:15]) begin
		sel_reg1 = 2'd1;
	end

	if (RegWrite_WB == 1'b1 && instruction_WB[11:7] == instruction_EX[24:20] ) begin
		sel_reg2 = 2'd2;
	end
	if (RegWrite_MEM == 1'b1 && instruction_MEM[11:7] == instruction_EX[24:20] ) begin
		sel_reg2 = 2'd1;
	end
end

endmodule
