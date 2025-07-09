`timescale 1ns/1ns
module decoder_manch #(
  parameter BAUDRATE = 115200 * 2,
  parameter CLK_FREQ = 18_750_000

) (
  input  wire clk, 
  input  wire rx_data,
  output reg  tx_data

);
  initial begin
    $dumpfile("decoder_manch.vcd");
    $dumpvars(1, decoder_manch);
  end

  localparam FULLBAUD =  CLK_FREQ / BAUDRATE;
  localparam HALFBAUD = FULLBAUD / 2;
  localparam bit_width = $clog2(FULLBAUD);

  reg [bit_width  :0] clk_counter; 


  // Формирование rising и falling edge 
  reg  prev_data;
  wire rising_edge  = (prev_data == 0 ) && (rx_data == 1);
  wire falling_edge = (prev_data == 1 ) && (rx_data == 0);

  always @(posedge clk) begin
    prev_data    <= rx_data;
    clk_counter  <= clk_counter + 1;
    if (rising_edge == 1'b1) begin
      if ((clk_counter >= FULLBAUD ) && (clk_counter <= FULLBAUD + FULLBAUD )) begin
        tx_data <= 1'b1;
        clk_counter <= 0; 
      end
    end

    if (falling_edge == 1'b1) begin
      if ((clk_counter >= FULLBAUD ) && (clk_counter <= FULLBAUD + FULLBAUD )) begin
        tx_data <= 1'b0;
        clk_counter <= 0; 
      end
    end

    if (clk_counter > 2 * FULLBAUD) clk_counter <= 0;

  end

endmodule