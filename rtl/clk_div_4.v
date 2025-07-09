module clk_div_4 (
  input     wire clk,
  output    reg  clk_div_4 = 0
  
);

  reg clk_div_2;
  
  // Деление частоты на 2 
  always @(posedge clk) begin
    clk_div_2 <= !clk_div_2;
  end

  // Деление частоты на 4
  always @(posedge clk_div_2) begin
    clk_div_4 <= !clk_div_4; 
  end


endmodule