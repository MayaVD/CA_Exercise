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


// Defining all wires
reg              zero_flag;

wire [       1:0] alu_op;
wire [       3:0] alu_control;
wire              reg_dst,branch,mem_read,mem_2_reg,
                  mem_write,alu_src, reg_write, jump;
wire [       4:0] regfile_waddr;
wire [      63:0] mem_data,alu_out,
                  alu_operand_2;
// Program Counters
wire [63:0] updated_pc,current_pc,updated_pc_ID;
wire [63:0] branch_pc;
wire [63:0] jump_pc;

// Control signals
wire [9:0]  control_signals_MEM,control_signals_WB,control_signals_EXE, control_signals_ID;

// Instructions
wire [31:0] instruction,instruction_ID,instruction_WB,instruction_EXE,instruction_MEM;

// Immediate
wire signed [63:0] immediate_extended,immediate_extended_EXE;

// Data Wires
wire signed [63:0] regfile_rdata_1,regfile_rdata_1_EXE;
wire signed [63:0] regfile_rdata_2,regfile_rdata_2_EXE,regfile_rdata_2_MEM;
wire [63:0] regfile_wdata;

wire [63:0] alu_out_MEM,alu_out_WB;

wire [63:0] mem_data_WB;

// Hazard unit wires
wire       PCWrite, IF_ID_Write, stall_sel;



// IF STAGE
// -----------------------------------------------------------

reg IF_ID_enable;

always@(*) begin
	assign IF_ID_enable = (IF_ID_Write & ~(zero_flag & (control_signals_ID[3] | control_signals_ID[9])));
end

// Program counter
pc #(
   .DATA_W(64)
) program_counter (
   .clk       (clk       ),
   .arst_n    (arst_n    ),
   .branch_pc (branch_pc),
   .jump_pc   (jump_pc),
   .zero_flag (zero_flag),
   .branch    (control_signals_MEM[3]),
   .jump      (control_signals_MEM[9]),
   .current_pc(current_pc), // output
   .enable    (enable   ),
   .PCWrite   (PCWrite  ),
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

// IF_ID Pipeline registers

reg_arstn_en#(
   .DATA_W(32) // width of the forwarded signal
)signal_pipe_IF_ID_instruction(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (instruction   ),
   .en       (IF_ID_enable  ),
   .dout     (instruction_ID)
);

reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)signal_pipe_IF_ID_updated_pc(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (updated_pc    ),
   .en       (IF_ID_enable  ),
   .dout     (updated_pc_ID )
);

// ID STAGE
// -----------------------------------------------------------

branch_unit#(
   .DATA_W(64)
)branch_unit(
   .updated_pc         (updated_pc_ID ),
   .immediate_extended (immediate_extended),
   .branch_pc          (branch_pc         ), // output
   .jump_pc            (jump_pc           )
);

always@(*) begin
	zero_flag = (regfile_rdata_1 == regfile_rdata_2) ? 1'b1 : 1'b0;
end

hazard_unit hazard_unit(
   .instruction_ID  (instruction_ID),
   .instruction_EXE (instruction_EXE),
   .MemRead_EXE     (control_signals_EXE[4]),
   .MemRead_ID      (control_signals_ID[4]),
   .PCWrite         (PCWrite),
   .IF_ID_Write     (IF_ID_Write),
   .stall_sel       (stall_sel)
);

control_unit control_unit(
   .opcode   (instruction_ID[6:0]),
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

mux_2 #(
   .DATA_W(10)
) control_mux (
   .input_a ({jump, reg_write, alu_src, mem_write, mem_2_reg, mem_read, branch, reg_dst, alu_op}),
   .input_b (10'b0),
   .select_a(stall_sel ),
   .mux_out (control_signals_ID) // output
);

register_file #(
   .DATA_W(64)
) register_file(
   .clk      (clk               ),
   .arst_n   (arst_n            ),
   .reg_write(control_signals_WB[8] ),
   .raddr_1  (instruction_ID[19:15]),
   .raddr_2  (instruction_ID[24:20]),
   .waddr    (instruction_WB[11:7]),
   .wdata    (regfile_wdata),
   .rdata_1  (regfile_rdata_1   ), // output
   .rdata_2  (regfile_rdata_2   )
);

immediate_extend_unit immediate_extend_u(
    .instruction         (instruction_ID),
    .immediate_extended  (immediate_extended) // output
);


// ID_EXE Pipeline signals

reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)signal_pipe_ID_EXE_immediate(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (immediate_extended),
   .en       (enable        ),
   .dout     (immediate_extended_EXE)
);

reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)signal_pipe_ID_EXE_rdata1(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (regfile_rdata_1),
   .en       (enable        ),
   .dout     (regfile_rdata_1_EXE)
);

reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)signal_pipe_ID_EXE_rdata2(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (regfile_rdata_2),
   .en       (enable        ),
   .dout     (regfile_rdata_2_EXE)
);

reg_arstn_en#(
   .DATA_W(32) // width of the forwarded signal
)signal_pipe_ID_EXE_instruction(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (instruction_ID),
   .en       (enable        ),
   .dout     (instruction_EXE)
);

reg_arstn_en#(
   .DATA_W(10) // width of the forwarded signal
)signal_pipe_ID_EXE_control(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (control_signals_ID),
   .en       (enable        ),
   .dout     (control_signals_EXE)
);

// EXE STAGE
// -----------------------------------------------------------

// Wires for forwarding
wire [1:0] sel_reg1,sel_reg2;
wire [63:0] alu_mux_out;
wire [63:0] alu_operand_1;

mux_2 #(
   .DATA_W(64)
) alu_operand_mux (
   .input_a (immediate_extended_EXE),
   .input_b (alu_mux_out),
   .select_a(control_signals_EXE[7] ),
   .mux_out (alu_operand_2     ) // output
);

mux_3 #(
   .DATA_W(64)
) alu_forw_mux1 (
   .input_a (regfile_rdata_1_EXE),
   .input_b (alu_out_MEM),
   .input_c (regfile_wdata),
   .select  (sel_reg1 ),
   .mux_out (alu_operand_1     ) // output
);

mux_3 #(
   .DATA_W(64)
) alu_forw_mux2 (
   .input_a (regfile_rdata_2_EXE),
   .input_b (alu_out_MEM),
   .input_c (regfile_wdata),
   .select  (sel_reg2 ),
   .mux_out (alu_mux_out     ) // output
);

alu_control alu_ctrl(
   .func7_5        ({instruction_EXE[30],instruction_EXE[25]}),
   .func3          (instruction_EXE[14:12]),
   .alu_op         (control_signals_EXE[1:0] ),
   .alu_control    (alu_control       ) // output
);

alu#(
   .DATA_W(64)
) alu(
   .alu_in_0 (alu_operand_1   ),
   .alu_in_1 (alu_operand_2   ),
   .alu_ctrl (alu_control     ),
   .alu_out  (alu_out         ), // output
   .zero_flag(                ),
   .overflow (                )
);

forwarding_unit forw_u(
	.instruction_EX(instruction_EXE),
    .instruction_MEM(instruction_MEM),
    .instruction_WB(instruction_WB),
	.RegWrite_MEM(control_signals_MEM[8]),
	.RegWrite_WB(control_signals_WB[8]),
    .sel_reg1(sel_reg1),
    .sel_reg2(sel_reg2)
);

// EXE_MEM Pipeline signals

reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)signal_pipe_EXE_MEM_alu_out(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (alu_out       ),
   .en       (enable        ),
   .dout     (alu_out_MEM)
);

reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)signal_pipe_EXE_MEM_rdata2(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (regfile_rdata_2_EXE),
   .en       (enable        ),
   .dout     (regfile_rdata_2_MEM)
);

reg_arstn_en#(
   .DATA_W(32) // width of the forwarded signal
)signal_pipe_EXE_MEM_instruction(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (instruction_EXE),
   .en       (enable        ),
   .dout     (instruction_MEM)
);

reg_arstn_en#(
   .DATA_W(10) // width of the forwarded signal
)signal_pipe_EXE_MEM_control(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (control_signals_EXE),
   .en       (enable        ),
   .dout     (control_signals_MEM)
);

// MEM STAGE
// -----------------------------------------------------------

// The data memory.
sram_BW64 #(
   .ADDR_W(10),
   .DATA_W(64)
) data_memory(
   .clk      (clk            ),
   .addr     (alu_out_MEM),
   .wen      (control_signals_MEM[6]),
   .ren      (control_signals_MEM[4]),
   .wdata    (regfile_rdata_2_MEM),
   .rdata    (mem_data       ), // output
   .addr_ext (addr_ext_2     ), // input
   .wen_ext  (wen_ext_2      ),
   .ren_ext  (ren_ext_2      ),
   .wdata_ext(wdata_ext_2    ),
   .rdata_ext(rdata_ext_2    ) // output
);

// MEM_WB Pipeline signals

reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)signal_pipe_MEM_WB_alu_out(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (alu_out_MEM   ),
   .en       (enable        ),
   .dout     (alu_out_WB    )
);

reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)signal_pipe_MEM_WB_mem_data(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (mem_data      ),
   .en       (enable        ),
   .dout     (mem_data_WB   )
);

reg_arstn_en#(
   .DATA_W(32) // width of the forwarded signal
)signal_pipe_MEM_WB_instruction(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (instruction_MEM),
   .en       (enable        ),
   .dout     (instruction_WB)
);

reg_arstn_en#(
   .DATA_W(10) // width of the forwarded signal
)signal_pipe_MEM_WB_control(
   .clk      (clk           ),
   .arst_n   (arst_n        ),
   .din      (control_signals_MEM),
   .en       (enable        ),
   .dout     (control_signals_WB)
);

// WB STAGE
// -----------------------------------------------------------

mux_2 #(
   .DATA_W(64)
) regfile_data_mux (
   .input_a  (mem_data_WB),
   .input_b  (alu_out_WB),
   .select_a (control_signals_WB[5]),
   .mux_out  (regfile_wdata) // output
);

endmodule
