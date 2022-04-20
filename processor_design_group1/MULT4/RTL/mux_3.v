module mux_3 
  #(
   parameter integer DATA_W = 16
   )(
      input  wire [DATA_W-1:0] input_a,
      input  wire [DATA_W-1:0] input_b,
      input  wire [DATA_W-1:0] input_c,
      input  wire [1:0]        select,
      output reg  [DATA_W-1:0] mux_out
   );

   always@(*)begin
      if(select == 1'b0)
         mux_out = input_a;
      else if(select == 1'b1)
         mux_out = input_b;
      else
	 mux_out = input_c;
   end
endmodule

