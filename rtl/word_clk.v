module word_clk #( 
  parameter DIVCLK = 256

) (
  input         mclkin,
  output reg    word_clk = 0

);
  
  localparam bit_width = $clog2(DIVCLK);  
  reg [bit_width :0] word_count = 0;

  always @(posedge mclkin) begin
    word_count <= word_count + 16'b1;

    if (word_count == DIVCLK-1) begin 
      word_count <= 16'b0;
      word_clk <= 1'b0;
    end else if (word_count == DIVCLK/2-1) begin 
      word_clk <= 1'b1;
    end
  end

endmodule