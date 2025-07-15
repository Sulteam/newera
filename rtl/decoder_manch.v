`timescale 1ps/1ps
module decoder_manch #(
    // UART frame parameters
    parameter DATA_BITS   = 8,        
    parameter STOP_BITS   = 2,
    // Timing parameters
    parameter BAUDRATE    = 115200,
    parameter CLK_FREQ    = 18_750_000
) (
    input  wire clk,
    input  wire reset,      // active high
    // Serial lines
    input  wire rx,
    // Received message interface
    input  wire rx_ready,
    output wire rx_valid,
    output reg  [DATA_BITS-1:0] rx_data

);
  initial begin
    $dumpfile("decoder.vcd");
    $dumpvars(1, decoder_manch);
  end
// State machine states 
parameter RESET_S    = 3'b000;
parameter IDLE_S     = 3'b001;
parameter RECEIVE_S  = 3'b010;
parameter COOLDOWN_S = 3'b100;

// Constants
localparam FULLBAUD = CLK_FREQ / BAUDRATE;
localparam HALFBAUD = FULLBAUD / 2;
localparam SR_LEN = DATA_BITS + STOP_BITS;

// Internal signals
reg [2:0] state;  
reg rx_valid_sig;
reg [SR_LEN-1:0] rx_shiftreg;
reg [31:0] clk_counter;
reg [31:0] baud_counter;
reg [STOP_BITS-1:0] fullstop;

  // Формирование rising и falling edge 
  reg  prev_data;
  wire rising_edge  = (prev_data == 0 ) && (rx == 1);
  wire falling_edge = (prev_data == 1 ) && (rx == 0);


initial begin
    fullstop = {1'b0, 1'b1};
end


// Main state machine
always @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= RESET_S;
        rx_data <= {DATA_BITS{1'b0}};
        rx_valid_sig <= 1'b0;
        rx_shiftreg <= {SR_LEN{1'b1}};
        clk_counter <= 0;
        baud_counter <= 0;
    end
    else begin

        prev_data <= rx;

        case (state)
            // IDLE STATE
            IDLE_S: begin
                clk_counter <= clk_counter + 1;
                if (rising_edge == 1'b1) begin
                  clk_counter <= 0;
                end else if (falling_edge == 1 && clk_counter >= HALFBAUD + HALFBAUD / 2 ) begin
                  state <= RECEIVE_S;
                  clk_counter <= 0;
                end
            end
            
            // RECEIVE STATE
            RECEIVE_S: begin
                clk_counter <= clk_counter + 1;
                
                // Midpoint sampling
                if (clk_counter == HALFBAUD / 2  - 1) begin
                    // If start bit is invalid, go back to idle
                    if (baud_counter == 0 && rx) begin
                        state <= IDLE_S;
                    end
                    else begin
                        rx_shiftreg <= {rx_shiftreg[SR_LEN-2:0], rx};
                        baud_counter <= baud_counter + 1;
                    end
                end
                
                if (clk_counter == HALFBAUD - 1) begin
                    clk_counter <= 0;
                end
                
                // On last cycle 
                if (baud_counter == SR_LEN + 1 && clk_counter == HALFBAUD / 2) begin
                    state <= COOLDOWN_S;
                    clk_counter <= 0;
                    baud_counter <= 0;
                    
                    // Pass data into buffer if it passes  stopbit checks
                    if (rx_shiftreg[STOP_BITS-1:0] == fullstop) begin
                        rx_valid_sig <= 1'b1;

                        rx_data <= rx_shiftreg[SR_LEN-1 -: DATA_BITS];

                    end
                end
            end
            // COOLDOWN STATE
            COOLDOWN_S: begin
                clk_counter <= clk_counter + 1;
                
                if (~rx) begin
                    state <= IDLE_S;
                    clk_counter <= 0;
                end
                else if (clk_counter >= HALFBAUD / 2 - 1 && falling_edge == 1'b1) begin
                    state <= RECEIVE_S;
                    clk_counter <= 0;
                end

            end
            // RESET STATE
            RESET_S: begin
                state <= IDLE_S;
            end
            
            default: begin
                state <= RESET_S;
                rx_data <= {DATA_BITS{1'b0}};
                rx_valid_sig <= 1'b0;
                rx_shiftreg <= {SR_LEN{1'b1}};
                clk_counter <= 0;
                baud_counter <= 0;
            end
        endcase
    end
end

assign rx_valid = rx_valid_sig;

endmodule