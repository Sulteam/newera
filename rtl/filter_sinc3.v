module filter_sinc3 #(
  parameter WIDTH = 16,
  parameter REG_BIT_WIDTH = 37     // reg_bit_width = x(n) + (M * log2(DR))  DR - decimation rate  
  
) (
  input                       mclkin,                // тактовая частота для модулятора
  input                       mdata1,                // входной поток данных от модулятора
  input                       word_clk,              // тактовая частота после децимации
  output reg [WIDTH - 1: 0]   DATA                   // отфильтрованные данные 

  
);

  // Внутренние провода

   reg [REG_BIT_WIDTH - 1:0] ip_data1;
   reg [REG_BIT_WIDTH - 1:0] acc1;
   reg [REG_BIT_WIDTH - 1:0] acc2;
   reg [REG_BIT_WIDTH - 1:0] acc3;
   reg [REG_BIT_WIDTH - 1:0] acc3_d2;
   reg [REG_BIT_WIDTH - 1:0] diff1;
   reg [REG_BIT_WIDTH - 1:0] diff2;
   reg [REG_BIT_WIDTH - 1:0] diff3;
   reg [REG_BIT_WIDTH - 1:0] diff1_d;
   reg [REG_BIT_WIDTH - 1:0] diff2_d;
    

  // Входные данные 
  always @(mdata1) begin
    if (mdata1 == 0) begin
	   ip_data1 <= 37'd0;
	 end else begin
	   ip_data1 <= 37'd1;
    end
  end
  
  // Блок интеграторов 
  always @(negedge mclkin) begin
   acc1 <= acc1 + ip_data1;
   acc2 <= acc2 + acc1;
   acc3 <= acc3 + acc2;
  end
	
  // Блок дифференциаторов
  always @(posedge word_clk) begin
   diff1 <= acc3 - acc3_d2;
	 diff2 <= diff1 - diff1_d;
	 diff3 <= diff2 - diff2_d;
	 acc3_d2 <= acc3; 
	 diff1_d <= diff1;
	 diff2_d <= diff2;
  end
  
  
  always @ ( posedge word_clk ) begin
    DATA <= (diff3[24:8] == 17'h10000) ? 16'hFFFF : diff3[23:8];  // Смещение на 8 битов из-за DR = 256 (2 ^ 8) 
  end
  
endmodule