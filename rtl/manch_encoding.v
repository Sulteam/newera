module manch_encoding #(
  // Timing parameters
  parameter BAUDRATE    = 115200,
  parameter CLK_FREQ    = 18_750_000

) (
  input  wire mclkin,
  input  wire rst,

  input  wire tx,
  input  wire tr_start,
  output reg  tx_manch

);


  // Constants
  localparam FULLBAUD = CLK_FREQ / BAUDRATE;
  localparam HALFBAUD = FULLBAUD / 2;

  // Internal wires
  reg [31:0] clk_counter;


  always @(posedge mclkin) begin
    if (rst) begin
      clk_counter <= 0;
      tx_manch    <= 0;

    end else 
      begin 
        if (tr_start) begin
          clk_counter <= 1;
          tx_manch <= ~tx;
        end
        if (clk_counter > 0) begin
          clk_counter <= clk_counter + 1; 
        end
        if (clk_counter == HALFBAUD - 1) begin
          tx_manch <= tx;
        end
      end
  end

endmodule