//Module: CPU
//Function: CPU is the top design of the RISC-V processor

//Inputs:
//	clk: main clock
//	arst_n: reset 
// enable: Starts the execution
//	addr_ext: Address for reading/writing content to Instruction Memory
//	wen_ext: Write enable for Instruction Memory
// ren_ext: Read enable for Instruction Memory
//	wdata_ext: Write word for Instruction Memory
//	addr_ext_2: Address for reading/writing content to Data Memory
//	wen_ext_2: Write enable for Data Memory
// ren_ext_2: Read enable for Data Memory
//	wdata_ext_2: Write word for Data Memory

// Outputs:
//	rdata_ext: Read data from Instruction Memory
//	rdata_ext_2: Read data from Data Memory



module cpu(
		input  wire			  clk,
		input  wire         arst_n,
		input  wire         enable,
		input  wire	[63:0]  addr_ext,
		input  wire         wen_ext,
		input  wire         ren_ext,
		input  wire [31:0]  wdata_ext,
		input  wire	[63:0]  addr_ext_2,
		input  wire         wen_ext_2,
		input  wire         ren_ext_2,
		input  wire [63:0]  wdata_ext_2,
		
		output wire	[31:0]  rdata_ext,
		output wire	[63:0]  rdata_ext_2

   );

wire              zero_flag;
wire [       1:0] alu_op;
wire [       3:0] alu_control;
wire              reg_dst,branch,mem_read,mem_2_reg,
                  mem_write,alu_src, reg_write, jump;
wire [       4:0] regfile_waddr;
wire [      63:0] mem_data,alu_out,
                  alu_operand_2;
wire [63:0] branch_pc,jump_pc;



// IF STAGE
// -----------------------------------------------------------
wire [31:0] instruction;
wire [63:0] updated_pc,current_pc,branch_pc_EXE_IF,jump_pc_EXE_IF;
wire [9:0]  control_EXE_MEM;
wire        zero_flag_EXE_IF;

pc #(
   .DATA_W(64)
) program_counter (
   .clk       (clk       ),
   .arst_n    (arst_n    ),
   .branch_pc (branch_pc_EXE_IF),
   .jump_pc   (jump_pc_EXE_IF),
   .zero_flag (zero_flag_EXE_IF),
   .branch    (control_EXE_MEM[2]),
   .jump      (control_EXE_MEM[8]),
   .current_pc(current_pc), // output
   .enable    (enable    ),
   .updated_pc(updated_pc)
);

// The instruction memory.
sram_BW32 #(
   .ADDR_W(9 ),
   .DATA_W(32)
) instruction_memory(
   .clk      (clk           ),
   .addr     (current_pc    ),
   .wen      (1'b0          ),
   .ren      (1'b1          ),
   .wdata    (32'b0         ),
   .rdata    (instruction   ), // output  
   .addr_ext (addr_ext      ), // input
   .wen_ext  (wen_ext       ), 
   .ren_ext  (ren_ext       ),
   .wdata_ext(wdata_ext     ),
   .rdata_ext(rdata_ext     ) // output
);

control_unit control_unit(
   .opcode   (instruction[6:0]),
   .alu_op   (alu_op          ), // output
   .reg_dst  (reg_dst         ),
   .branch   (branch          ),
   .mem_read (mem_read        ),
   .mem_2_reg(mem_2_reg       ),
   .mem_write(mem_write       ),
   .alu_src  (alu_src         ),
   .reg_write(reg_write       ),
   .jump     (jump            )
);

// IF_ID Pipeline register instruction signal
wire [31:0] instruction_IF_ID;
reg_arstn_en#(
   .DATA_W(32) // width of the forwarded signal
)signal_pipe_IF_ID_instruction(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (instruction   ),
   .en       (enable        ),
   .dout    (instruction_IF_ID)
);

wire [63:0] updated_pc_IF_ID;
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)signal_pipe_IF_ID_updated_pc(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (updated_pc    ),
   .en       (enable        ),
   .dout    (updated_pc_IF_ID)
);

wire [9:0] control_IF_ID;
reg_arstn_en#(
   .DATA_W(10) // width of the forwarded signal
)signal_pipe_IF_ID_control(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      ({alu_op, reg_dst, branch, mem_read, mem_2_reg, mem_write, alu_src, reg_write, jump}),
   .en       (enable        ),
   .dout    (control_IF_ID  )
);

// ID STAGE
// -----------------------------------------------------------
wire signed [63:0] immediate_extended;
wire signed [63:0] regfile_rdata_1,regfile_rdata_2;
wire [63:0] regfile_wdata;
wire [31:0] instruction_MEM_WB;
wire [9:0]  control_MEM_WB;

register_file #(
   .DATA_W(64)
) register_file(
   .clk      (clk               ),
   .arst_n   (arst_n            ),
   .reg_write(control_MEM_WB[8] ),
   .raddr_1  (instruction_IF_ID[19:15]),
   .raddr_2  (instruction_IF_ID[24:20]),
   .waddr    (instruction_MEM_WB[11:7]),
   .wdata    (regfile_wdata),
   .rdata_1  (regfile_rdata_1   ), // output
   .rdata_2  (regfile_rdata_2   )
);

immediate_extend_unit immediate_extend_u(
    .instruction         (instruction_IF_ID),
    .immediate_extended  (immediate_extended) // output
);


// ID_EXE Pipeline signals
wire signed [63:0] immediate_extended_ID_EXE;
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)signal_pipe_ID_EXE_immediate(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (immediate_extended),
   .en       (enable        ),
   .dout    (immediate_extended_ID_EXE)
);

wire signed [63:0] regfile_rdata_1_ID_EXE;
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)signal_pipe_ID_EXE_rdata1(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (regfile_rdata_1),
   .en       (enable        ),
   .dout    (regfile_rdata_1_ID_EXE)
);

wire signed [63:0] regfile_rdata_2_ID_EXE;
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)signal_pipe_ID_EXE_rdata2(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (regfile_rdata_2),
   .en       (enable        ),
   .dout    (regfile_rdata_2_ID_EXE)
);

wire [31:0] instruction_ID_EXE;
reg_arstn_en#(
   .DATA_W(32) // width of the forwarded signal
)signal_pipe_ID_EXE_instruction(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (instruction_IF_ID),
   .en       (enable        ),
   .dout    (instruction_ID_EXE)
);

wire [63:0] updated_pc_ID_EXE;
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)signal_pipe_ID_EXE_updated_pc(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (updated_pc_IF_ID),
   .en       (enable        ),
   .dout    (updated_pc_ID_EXE)
);

wire [9:0] control_ID_EXE;
reg_arstn_en#(
   .DATA_W(10) // width of the forwarded signal
)signal_pipe_ID_EXE_control(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (control_IF_ID ),
   .en       (enable        ),
   .dout    (control_ID_EXE)
);

// EXE STAGE
// -----------------------------------------------------------
mux_2 #(
   .DATA_W(64)
) alu_operand_mux (
   .input_a (immediate_extended_ID_EXE),
   .input_b (regfile_rdata_2_ID_EXE),
   .select_a(control_ID_EXE[7] ),
   .mux_out (alu_operand_2     ) // output
);

alu_control alu_ctrl(
   .func7_5       ({instruction_ID_EXE[30],instruction_ID_EXE[25]}   ),
   .func3          (instruction_ID_EXE[14:12]),
   .alu_op         (control_ID_EXE[1:0] ),
   .alu_control    (alu_control       ) // output
);

alu#(
   .DATA_W(64)
) alu(
   .alu_in_0 (regfile_rdata_1_ID_EXE),
   .alu_in_1 (alu_operand_2   ),
   .alu_ctrl (alu_control     ),
   .alu_out  (alu_out         ), // output
   .zero_flag(zero_flag       ),
   .overflow (                )
);

branch_unit#(
   .DATA_W(64)
)branch_unit(
   .updated_pc         (updated_pc_ID_EXE ),
   .immediate_extended (immediate_extended_ID_EXE),
   .branch_pc          (branch_pc         ), // output
   .jump_pc            (jump_pc           )
);

// EXE_IF Pipeline signals
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)signal_pipe_EXE_IF_branch_pc(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (branch_pc     ),
   .en       (enable        ),
   .dout    (branch_pc_EXE_IF)
);

reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)signal_pipe_EXE_IF_jump_pc(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (jump_pc       ),
   .en       (enable        ),
   .dout    (jump_pc_EXE_IF)
);

reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)signal_pipe_EXE_IF_zero_pc(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (zero_flag     ),
   .en       (enable        ),
   .dout    (zero_flag_EXE_IF)
);

// EXE_MEM Pipeline signals
wire [63:0] alu_out_EXE_MEM;
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)signal_pipe_EXE_MEM_alu_out(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (alu_out       ),
   .en       (enable        ),
   .dout    (alu_out_EXE_MEM)
);

wire signed [63:0] regfile_rdata_2_EXE_MEM;
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)signal_pipe_EXE_MEM_rdata2(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (regfile_rdata_2_ID_EXE),
   .en       (enable        ),
   .dout    (regfile_rdata_2_EXE_MEM)
);

wire [31:0] instruction_EXE_MEM;
reg_arstn_en#(
   .DATA_W(32) // width of the forwarded signal
)signal_pipe_EXE_MEM_instruction(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (instruction_ID_EXE),
   .en       (enable        ),
   .dout    (instruction_EXE_MEM)
);

reg_arstn_en#(
   .DATA_W(10) // width of the forwarded signal
)signal_pipe_EXE_MEM_control(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (control_ID_EXE),
   .en       (enable        ),
   .dout    (control_EXE_MEM)
);

// MEM STAGE
// -----------------------------------------------------------
// The data memory.
sram_BW64 #(
   .ADDR_W(10),
   .DATA_W(64)
) data_memory(
   .clk      (clk            ),
   .addr     (alu_out_EXE_MEM),
   .wen      (control_EXE_MEM[6]),
   .ren      (control_EXE_MEM[4]),
   .wdata    (regfile_rdata_2_EXE_MEM),
   .rdata    (mem_data       ), // output
   .addr_ext (addr_ext_2     ), // input
   .wen_ext  (wen_ext_2      ),
   .ren_ext  (ren_ext_2      ),
   .wdata_ext(wdata_ext_2    ),
   .rdata_ext(rdata_ext_2    ) // output
);

// MEM_WB Pipeline signals
wire [63:0] alu_out_MEM_WB;
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)signal_pipe_MEM_WB_alu_out(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (alu_out_EXE_MEM),
   .en       (enable        ),
   .dout    (alu_out_MEM_WB)
);

wire [63:0] mem_data_MEM_WB;
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)signal_pipe_MEM_WB_mem_data(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (mem_data      ),
   .en       (enable        ),
   .dout    (mem_data_MEM_WB)
);

reg_arstn_en#(
   .DATA_W(32) // width of the forwarded signal
)signal_pipe_MEM_WB_instruction(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (instruction_EXE_MEM),
   .en       (enable        ),
   .dout    (instruction_MEM_WB)
);

reg_arstn_en#(
   .DATA_W(10) // width of the forwarded signal
)signal_pipe_MEM_WB_control(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (control_EXE_MEM),
   .en       (enable        ),
   .dout    (control_MEM_WB)
);

// WB STAGE
// -----------------------------------------------------------

mux_2 #(
   .DATA_W(64)
) regfile_data_mux (
   .input_a  (mem_data_MEM_WB),
   .input_b  (alu_out_MEM_WB),
   .select_a (control_MEM_WB[5]),
   .mux_out  (regfile_wdata) // output
);

endmodule


