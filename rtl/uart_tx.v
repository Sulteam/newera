`timescale 1ns/1ns
module uart_tx #(
  // UART frame parameters
  parameter DATA_BITS   = 8,        // Range 5 to 8
  parameter FIRST_BIT   = "msb",    // "lsb" or "msb"
  // Timing parameters
  parameter BAUDRATE    = 115200,
  parameter CLK_FREQ    = 18_750_000
) (
  input  wire clk,
  input  wire reset,      // active high
  // Serial lines
  output reg  tx,
  // Transmitted message interface
  output wire tx_ready,
  input  wire tx_valid,
  output reg  tr_start,
  input  wire [DATA_BITS-1:0] tx_data  
);

  initial begin
    $dumpfile("uart.vcd");
    $dumpvars(1, uart_tx);
  end

  // State machine states 
  parameter RESET_S    = 2'b00;
  parameter IDLE_S     = 2'b01;
  parameter TRANSMIT_S = 2'b10;
  
  // Constants
  localparam FULLBAUD = CLK_FREQ / BAUDRATE;
  localparam HALFBAUD = FULLBAUD / 2;
  localparam SR_LEN = DATA_BITS;
  
  // Internal signals
  reg [2:0] state;  
  reg tx_ready_sig;
  reg [SR_LEN-1:0] tx_shiftreg;
  reg [31:0] clk_counter;
  reg [31:0] baud_counter;
  

  // Function to reverse bit order 
  function [DATA_BITS-1:0] reverse_slv;
    input [DATA_BITS-1:0] data;
    integer i;
    begin
      reverse_slv = 0;
      for (i = 0; i < DATA_BITS; i = i + 1)
          reverse_slv[i] = data[DATA_BITS-1-i];
    end
  endfunction
  
  // Main state machine
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= RESET_S;
      tx <= 1'b1;
      tx_ready_sig <= 1'b0;
      tx_shiftreg <= {SR_LEN{1'b1}};
      clk_counter <= 0;
      baud_counter <= 0;
      tr_start <= 0;
    end else begin
      case (state)
        // IDLE STATE
        IDLE_S: begin
          clk_counter <= clk_counter + 1;
          
          if (clk_counter == FULLBAUD - 1) begin
            if (tx_valid) begin
              tx_ready_sig <= 1'b1;
              clk_counter  <= 0;
            end else begin
              tr_start <= 1'b1;
              clk_counter  <= 0;
            end
            end else begin
              tr_start <= 1'b0;
          end
          // Switch to transmit state if new data available
          if (tx_ready_sig && tx_valid) begin
            state <= TRANSMIT_S;
            tx_ready_sig <= 1'b0;
            tx <= 1'b0;
            tr_start <= 1'b1;
            
            // Fill transmit shift register
            if (FIRST_BIT == "msb") begin
                tx_shiftreg[SR_LEN-1 -: DATA_BITS] <= tx_data;
            end
            else begin // "lsb"
                tx_shiftreg[SR_LEN-1 -: DATA_BITS] <= reverse_slv(tx_data);
            end
          end
        end
        
        // TRANSMIT STATE
        TRANSMIT_S: begin
          clk_counter <= clk_counter + 1;
          tr_start <= 1'b0;
          // Push new bit from buffer onto line every full baud cycle
          if (clk_counter == FULLBAUD-1) begin
            tx <= tx_shiftreg[SR_LEN-1];
            tr_start <= 1'b1;
            tx_shiftreg <= {tx_shiftreg[SR_LEN-2:0], 1'b1};
            baud_counter <= baud_counter + 1;
            clk_counter <= 0;
          end
          
          // On last clock cycle of transmission, go idle
          if (baud_counter == SR_LEN && clk_counter == FULLBAUD-1) begin
            state <= IDLE_S;
            tx <= 1'b1;
            tr_start <= 1'b1;
            clk_counter <= 0;
            baud_counter <= 0;
          end
        end
        
        // RESET STATE
        RESET_S: begin
          state <= IDLE_S;
          tx_ready_sig <= 1'b1;
        end
        
        default: begin
          state <= RESET_S;
          tx_ready_sig <= 1'b0;
          tx <= 1'b1;
          tx_shiftreg <= {SR_LEN{1'b1}};
          clk_counter <= 0;
          baud_counter <= 0;
        end
      endcase
    end
  end
  
  assign tx_ready = tx_ready_sig;

endmodule
