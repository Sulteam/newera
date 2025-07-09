module uart_tx #(
  // Параметры UART
  parameter DATA_BITS = 8,
  parameter STOP_BITS = 1,
  parameter FIRST_BIT = "lsb",
  parameter PARITY_TYPE = "none",
  // Тайминг параметры
  parameter BAUDRATE = 115200,
  parameter CLK_FREQ = 75_000_000  
) (
  input wire clk,
  //Линия передачи 
  output reg tx,
  output reg busy,   
  // Передача 
  input wire tx_valid,
  input wire [DATA_BITS - 1 : 0] tx_data

);

  // Состояния конечного автомата 
parameter IDLE_S       = 2'b01;
parameter TRANSMIT_S   = 2'b10;

// Внутренние параметры 
localparam FULLBAUD = CLK_FREQ / BAUDRATE;
localparam SR_LEN = DATA_BITS +
                   ((PARITY_TYPE != "none") ? 1 : 0) + 
                   STOP_BITS;

// Внутренние провода 
reg [2:0] state;  
reg [SR_LEN-1:0] tx_shiftreg;
reg [31:0] clk_counter;
reg [31:0] baud_counter;

// Функция инвертирования данных   
function [DATA_BITS - 1 : 0] reverse_slv;
  input [DATA_BITS - 1: 0] data;
  integer i;
  begin
    reverse_slv = 0;
    for (i = 0; i < DATA_BITS; i = i + 1)
      reverse_slv[i] = data[DATA_BITS - 1 - i];
  end
endfunction

// Функция вычисления бита паритета
function parity_bit;
  input [DATA_BITS-1:0] data;
  integer i;
  reg result;
  begin
    result = 0;
    for (i = 0; i < DATA_BITS; i = i + 1)
      result = result ^ data[i];
      parity_bit = result;
  end
endfunction

// Функция проверки паритета
function parity_check;
  input [DATA_BITS-1:0] data;
  input [255:0] parity_type; 
  reg parity;
  begin
    parity = ^data; 
        
    if (parity_type == "none")
      parity_check = 1'b1;
      else if (parity_type == "even")
        parity_check = ~parity;
      else // "odd"
        parity_check = parity;
  end
endfunction

// Основной конечный автомат
always @(posedge clk) begin
  begin
    case (state)
      // IDLE STATE
        IDLE_S: begin
          busy <= 1'b0;
          // Переход к передаче данных при новых данных 
          if (tx_valid == 1'b1) begin
            state <= TRANSMIT_S;
            tx <= 1'b0;
					if (FIRST_BIT == "msb") begin
            tx_shiftreg[SR_LEN-1 -: DATA_BITS] <= tx_data;
          end else begin // "lsb"
            tx_shiftreg[SR_LEN-1 -: DATA_BITS] <= reverse_slv(tx_data);
          end
						tx_shiftreg[STOP_BITS-1:0] <= {STOP_BITS{1'b1}};
          end
          end
            
            // TRANSMIT STATE
        TRANSMIT_S: begin
          clk_counter <= clk_counter + 1;
          busy <= 1'b1;
          // Выталкивать новый бит из буфера в линию каждый полный цикл передачи данных
              if (clk_counter == FULLBAUD-1) begin
                tx <= tx_shiftreg[SR_LEN-1];
                tx_shiftreg <= {tx_shiftreg[SR_LEN-2:0], 1'b1};
                baud_counter <= baud_counter + 1;
                clk_counter <= 0; 
              end
                
            // На последнем такте передачи перейти в IDLE
              if (baud_counter == SR_LEN && clk_counter == FULLBAUD-1) begin
                state <= IDLE_S;
                tx <= 1'b1;
                clk_counter <= 0;
                baud_counter <= 0;
              end
            end
            
            default: begin
                state <= IDLE_S;
                tx <= 1'b1;
                tx_shiftreg <= {SR_LEN{1'b1}};
                clk_counter <= 0;
                baud_counter <= 0;
            end
        endcase
    end
end

endmodule