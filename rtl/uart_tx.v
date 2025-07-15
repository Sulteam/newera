`timescale 1ps/1ps
module uart_tx #(
    // UART frame parameters
    parameter DATA_BITS   = 8,        // Range 5 to 8
    parameter STOP_BITS   = 2,
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
    input  wire [DATA_BITS-1:0] tx_data
);

  initial begin
    $dumpfile("uart.vcd");
    $dumpvars(1, uart_tx);
  end

// State machine states 
parameter RESET_S         = 2'b00,
          IDLE_S          = 2'b01,
          TRANSMIT_MSB_S  = 2'b10,
          TRANSMIT_LSB_S =  2'b11;      
// Constants
localparam FULLBAUD = CLK_FREQ / BAUDRATE;
localparam HALFBAUD = FULLBAUD / 2;
localparam SR_LEN = DATA_BITS + STOP_BITS;

// Internal signals
reg [1:0] state; 
reg tx_ready_sig;
reg [SR_LEN-1:0] tx_shiftreg;
reg [31:0] clk_counter;
reg [31:0] baud_counter;
wire [DATA_BITS*2 - 1 : 0] data_manchester;
reg nibble;

// Generate manchester DATA for lsb
genvar i;
generate for (i = 0; i < DATA_BITS; i = i + 1)
  begin : gen_manchester
     assign data_manchester[2*i] =      tx_data[i];
     assign data_manchester[2*i + 1] =  ~tx_data[i];
  end
endgenerate


// Main state machine
always @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= RESET_S;
        tx <= 1'b0;
        tx_ready_sig <= 1'b0;
        tx_shiftreg <= {SR_LEN{1'b1}};
        clk_counter <= 0;
        baud_counter <= 0;
    end
    else begin

        case (state)
            // IDLE STATE
            IDLE_S: begin
                clk_counter <= clk_counter + 1;
                tx_ready_sig <= 1'b1;
                if (clk_counter == HALFBAUD-1) begin
                  tx <= 1'b1;
                end else if (clk_counter == FULLBAUD-1 && tx_valid == 0) begin
                  tx <= 1'b0;
                  clk_counter <= 0;
                end
                // Switch to transmit state if new data available
                if (tx_ready_sig && tx_valid && clk_counter == FULLBAUD-1) begin
                    state <= TRANSMIT_MSB_S;
                    clk_counter <= 0;
                    tx_ready_sig <= 1'b0;
                    tx <= 1'b1;
                    tx_shiftreg[SR_LEN-1 -: DATA_BITS] <= data_manchester[DATA_BITS*2 - 1 : DATA_BITS];
                    // Add stop bits
                    tx_shiftreg[STOP_BITS-1:0] <= {1'b0, 1'b1};
                end
            end
            
            // TRANSMIT STATE
            TRANSMIT_MSB_S: begin
                clk_counter <= clk_counter + 1;
                
                // The second half of the Manchester code for the start bit
                if (clk_counter == HALFBAUD-1 && baud_counter == 0) begin
                  tx <= 1'b0;
                end
                
                // Push new bit from buffer onto line every full baud cycle
                if (clk_counter == FULLBAUD-1) begin
                    tx <= tx_shiftreg[SR_LEN-1];
                    tx_shiftreg <= {tx_shiftreg[SR_LEN-2:0], 1'b1};
                    baud_counter <= baud_counter + 1;
                    clk_counter <= 0;
                end

                if (clk_counter == HALFBAUD-1 && baud_counter !== 0) begin
                    baud_counter <= baud_counter + 1;
                    tx <= tx_shiftreg[SR_LEN-1];
                    tx_shiftreg <= {tx_shiftreg[SR_LEN-2:0], 1'b1};
                end
                
                // On last clock cycle of transmission, go idle
                if (baud_counter == SR_LEN && clk_counter == FULLBAUD-1) begin
                    state <= TRANSMIT_LSB_S;
                    tx_shiftreg[SR_LEN-1 -: DATA_BITS] <= data_manchester[DATA_BITS - 1 : 0];
                    tx <= 1'b1;
                    clk_counter <= 0;
                    baud_counter <= 0;
                    //add stop bit
                    tx_shiftreg[STOP_BITS-1:0] <= {1'b0, 1'b1};
                end
            end

            // TRANSMIT STATE
            TRANSMIT_LSB_S: begin
                clk_counter <= clk_counter + 1;
                
                // The second half of the Manchester code for the start bit
                if (clk_counter == HALFBAUD-1 && baud_counter == 0) begin
                  tx <= 1'b0;
                end
                
                // Push new bit from buffer onto line every full baud cycle
                if (clk_counter == FULLBAUD-1) begin
                    tx <= tx_shiftreg[SR_LEN-1];
                    tx_shiftreg <= {tx_shiftreg[SR_LEN-2:0], 1'b1};
                    baud_counter <= baud_counter + 1;
                    clk_counter <= 0;
                end

                if (clk_counter == HALFBAUD-1 && baud_counter !== 0) begin
                    tx <= tx_shiftreg[SR_LEN-1];
                    tx_shiftreg <= {tx_shiftreg[SR_LEN-2:0], 1'b1};
                    baud_counter <= baud_counter + 1;
                end
                
                // On last clock cycle of transmission, go idle
                if (baud_counter == SR_LEN - 2 && clk_counter == FULLBAUD-1) begin
                    state <= IDLE_S;
                    tx <= 1'b0;
                    clk_counter <= 0;
                    baud_counter <= 0;
                end
            end
            
            // RESET STATE
            RESET_S: begin
                state <= IDLE_S;
                tx_ready_sig <= 1'b0;
            end
            
            default: begin
                state <= RESET_S;
                tx_ready_sig <= 1'b0;
                tx <= 1'b0;
                tx_shiftreg <= {SR_LEN{1'b1}};
                clk_counter <= 0;
                baud_counter <= 0;
            end
        endcase
    end
end

assign tx_ready = tx_ready_sig;

endmodule