`timescale 1ns/1ns
module packager #(
  parameter ADC_DATA_WIDTH = 16,
  parameter ADC_COUNT      = 6
 
) (
  input wire                          clk,
  input wire                          rst,

  input wire [ADC_DATA_WIDTH - 1 : 0] data_adc0,
  input wire [ADC_DATA_WIDTH - 1 : 0] data_adc1,
  input wire [ADC_DATA_WIDTH - 1 : 0] data_adc2,
  input wire [ADC_DATA_WIDTH - 1 : 0] data_adc3,
  input wire [ADC_DATA_WIDTH - 1 : 0] data_adc4,
  input wire [ADC_DATA_WIDTH - 1 : 0] data_adc5,
 
  input wire                          write_enable,
  input wire                          sync_pulse, 
  input wire                          busy,

  output reg [7 :0]                   data_out,
  output reg                          data_valid

);
  
  initial begin
    $dumpfile("packager.vcd");
    $dumpvars(1, packager);
  end

  // state machine 
  parameter [1 :0] IDLE         = 00,
                   TR_START_BIT = 01,
                   TR_ADC_DATA  = 10;
  reg [1 : 0] state;
  // Внутренние сигналы и регистры  
  reg [ADC_DATA_WIDTH - 1 : 0] array_data_adc [0: ADC_COUNT - 1];


  localparam START_BYTE = 8'h00;
  reg [2 :0] adc_index;
  reg [1 :0] byte_index;

  always @(posedge clk or posedge rst) begin
    case ( state )
    IDLE:begin
      data_valid <= 1'b0;
      byte_index <= 1'b0;
      if (write_enable == 1'b1 ) begin
        array_data_adc[0] <= data_adc0;
        array_data_adc[1] <= data_adc1;
        array_data_adc[2] <= data_adc2;
        array_data_adc[3] <= data_adc3;
        array_data_adc[4] <= data_adc4;
        array_data_adc[5] <= data_adc5;

      end
      if (busy == 1'b0 && sync_pulse == 1'b1) begin
        state <= TR_START_BIT;
      end
    end
    TR_START_BIT:begin
      data_out   <= START_BYTE;
      data_valid <= 1'b1;
      adc_index  <= 0;
      byte_index <= 0;
      state <= TR_ADC_DATA;
    end
    TR_ADC_DATA:begin
      if (adc_index < ADC_COUNT && busy == 1'b0) begin 
        data_out <= byte_index ? array_data_adc[adc_index] [7 : 0] : array_data_adc[adc_index] [15 : 8];
        if (byte_index == 1'b0) begin
          byte_index <= 1'b1;
        end else begin
          byte_index <= 1'b0;
          adc_index  <= adc_index + 1;
        end
        if (adc_index == ADC_COUNT) begin
          data_valid <= 1'b1;
          state <= IDLE;
        end
      end
      if (adc_index == ADC_COUNT) begin
        data_valid <= 1'b1;
        data_out <= 8'hFF;
        state <= IDLE;
      end
    end
    endcase
    
  end



endmodule