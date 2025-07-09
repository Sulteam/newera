`timescale 1ns/1ns
module manch_encoding #(
  parameter BAUDRATE = 115200 * 2,
  parameter CLK_FREQ = 18_750_000

) (
  input  wire clk,
  input  wire rst,
  input  wire tx_data,
  output wire tx_manch

);

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(1, manch_encoding);
  end

  localparam FULLBAUD =  CLK_FREQ / BAUDRATE;
  localparam bit_width = $clog2(FULLBAUD);

  reg [bit_width - 1 :0] clk_counter; 
  reg CLK_TX;

  always @(posedge clk) begin
    if ( rst == 1 ) begin
      clk_counter <= 0;
      CLK_TX <= 0;
    end else begin
      clk_counter <= clk_counter + 1;
      if (clk_counter == FULLBAUD-1) begin
        CLK_TX <= ~ CLK_TX;
        clk_counter <= 0;
      end 
    end
    
  end

  assign tx_manch = CLK_TX ^ tx_data;
  
endmodule