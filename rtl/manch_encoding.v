`timescale 1ns/1ns
module manch_encoding #(
  parameter BAUDRATE = 115200,
  parameter CLK_FREQ = 18_750_000

) (
  input  wire clk,
  input  wire tx_data,
  input  wire start_tr,
  output reg  tx_manch

);

  initial begin
    $dumpfile("manch.vcd");
    $dumpvars(1, manch_encoding);
  end

  localparam FULLBAUD  = CLK_FREQ / BAUDRATE;
  localparam bit_width = $clog2(FULLBAUD);

  reg [bit_width - 1 :0] clk_counter;

  parameter IDLE          = 2'b00,
            TRANSMIT_ONE  = 2'b01,
            TRANSMIT_ZERO = 2'b10;
  
  reg [2 :0] state;

  always @(posedge clk) begin
    case (state)
    IDLE: begin
      clk_counter <= 0;
      if (tx_data == 1 || start_tr == 1) begin
        tx_manch <= 1'b0;
        state <= TRANSMIT_ONE;
      end else begin
        tx_manch <= 1'b1;
        state <= TRANSMIT_ZERO;
      end
    end
    TRANSMIT_ONE:begin
      clk_counter <= clk_counter + 1;

      if (clk_counter == FULLBAUD/2 - 1) begin
        tx_manch <= 1'b1;
      end else if (clk_counter == FULLBAUD - 1) begin
        clk_counter <= 0;
        if (tx_data == 1'b1 ) begin
          tx_manch <= 1'b0;
        end else begin
          tx_manch <= 1'b1;
          state <= TRANSMIT_ZERO;
        end
      end
    end
    TRANSMIT_ZERO:begin
      clk_counter <= clk_counter + 1;

      if (clk_counter == FULLBAUD/2 - 1) begin
        tx_manch <= 1'b0;
      end else if (clk_counter == FULLBAUD - 1) begin
        clk_counter <= 0;
        if (tx_data == 1'b1 ) begin
          tx_manch <= 1'b0;
          state <= TRANSMIT_ONE;
        end else begin
          tx_manch <= 1'b1;
        end
      end
    end
    endcase
  end
  
endmodule