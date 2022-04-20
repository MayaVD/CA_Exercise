
module hazard_unit(
      input reg [31:0] instruction_ID,
      input reg [31:0] instruction_EXE,
      input reg	       MemRead_EXE,
      input reg	       MemRead_ID,
      output reg       PCWrite,
      output reg       IF_ID_Write,
      output reg       stall_sel
   );

always @(*) begin
	assign stall_sel = 1'b1;
	assign IF_ID_Write = 1'b1;
	assign PCWrite = 1'b1;	
	
	if (MemRead_EXE == 1'b1 && MemRead_ID == 1'b0 && ((instruction_EXE[11:7] == instruction_ID[19:15]) || (instruction_EXE[11:7] == instruction_ID[24:20]))) begin
		assign stall_sel = 1'b0;
		assign IF_ID_Write = 1'b0;
		assign PCWrite = 1'b0;
	end 
end

endmodule
