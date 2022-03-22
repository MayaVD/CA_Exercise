// 6 inputs 2 outputs still to be implemented
module forwarding_unit(
      input  wire [6:0] opcode,
      input reg  [1:0] alu_op,
      input reg        reg_dst,
      input reg        branch,
      input reg        mem_read,
      input reg        mem_2_reg,
      output reg        mem_write,
      output reg        alu_src,
   );
