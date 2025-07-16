`timescale 1ns/1ns
module packager #(
  parameter ADC_DATA_WIDTH = 16,
  parameter ADC_COUNT = 6 
) (
  input wire                         mclkin,
  input wire                         rst,
  
  // Data ADC
  input wire [ADC_DATA_WIDTH - 1: 0] data_adc_0,
  input wire [ADC_DATA_WIDTH - 1: 0] data_adc_1,
  input wire [ADC_DATA_WIDTH - 1: 0] data_adc_2,
  input wire [ADC_DATA_WIDTH - 1: 0] data_adc_3,
  input wire [ADC_DATA_WIDTH - 1: 0] data_adc_4,
  input wire [ADC_DATA_WIDTH - 1: 0] data_adc_5,

  input wire                         write_enable,
  
  // Transmit interface
  input  wire                       sync_pulse,
  input  wire                       tx_ready,
  output wire                       tx_valid,
  output reg [7 :0]                 tx_data

);
  initial begin
    $dumpfile("packager.vcd");
    $dumpvars(1, packager);
  end

  parameter IDLE_S      = 2'b00,
            TR_DATA_S   = 2'b10;

  //Internal wires
  reg [1 :0] state;
  reg tx_valid_sig;
  reg [3 :0] adc_index;
  reg byte_index;
  // buffer for adc_data
  reg [ADC_DATA_WIDTH - 1 : 0] array_data_adc [0: ADC_COUNT - 1];

  localparam FIRST_DATA = 8'hFF;

 always @(posedge mclkin, negedge rst) begin
    if (rst) begin 
      state <= IDLE_S;
    end else begin
        case (state)
          IDLE_S:begin
            byte_index <= 1'b0;
            adc_index  <= 1'b0;
            
            if (write_enable) begin 
              array_data_adc[0] <= data_adc_0; 
              array_data_adc[1] <= data_adc_1; 
              array_data_adc[2] <= data_adc_2; 
              array_data_adc[3] <= data_adc_3; 
              array_data_adc[4] <= data_adc_4; 
              array_data_adc[5] <= data_adc_5; 
            end

            if (sync_pulse) begin
              state    <= TR_DATA_S;
              tx_data  <= FIRST_DATA;
              tx_valid_sig <= 1'b1;
            end

          end
          TR_DATA_S: begin
            if (tx_ready) begin
              tx_data <= !byte_index ? array_data_adc[adc_index] [15 :8] : array_data_adc[adc_index] [7 :0];
              tx_valid_sig <= 1'b1;
            end
            if (tx_ready && tx_valid_sig ) begin
              tx_valid_sig <= 1'b0;
              if (byte_index) begin
                adc_index  <= adc_index + 1;
                byte_index <= 1'b0;
              end else begin
                byte_index <= 1'b1;
              end
            end
            if (adc_index == ADC_COUNT - 1 && byte_index == 1'b1) begin 
              state <= IDLE_S;
              tx_valid_sig <= 1'b0;
              adc_index  <= 0;
              byte_index <= 1'b0;
            end
          end

        endcase

    end
    

 end
  assign tx_valid = tx_valid_sig;
endmodule