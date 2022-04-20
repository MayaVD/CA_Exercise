
module hazard_unit(
      input wire [31:0] instruction_ID,
      input wire [31:0] instruction_EXE,
      input wire	       MemRead_EXE,
      input wire	       MemRead_ID,
      output reg       PCWrite,
      output reg       IF_ID_Write,
      output reg       stall_sel
   );

always @(*) begin
	stall_sel = 1'b1;
	IF_ID_Write = 1'b1;
	PCWrite = 1'b1;	
	
	if (MemRead_EXE == 1'b1 && MemRead_ID == 1'b0 && ((instruction_EXE[11:7] == instruction_ID[19:15]) || (instruction_EXE[11:7] == instruction_ID[24:20]))) begin
		stall_sel = 1'b0;
		IF_ID_Write = 1'b0;
		PCWrite = 1'b0;
	end 
end

endmodule
