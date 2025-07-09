module top #(
  parameter WIDTH = 16 
  ) (
    input    clk,              // тактовая частота в 75 МГц
    input    data_in_i,        // сигма-дельта модуляция 
    input    data_in_u,        // сигма-дельта модуляция 
    output   mclkin,           // тактовая частота для АЦП
    output   data_tx           // манчестерский код 
     

);
  
  wire      mdat_i;
  wire      mdat_u;

  wire      word_clk;

  wire  [WIDTH - 1 :0]  FILTERED_DATA_I;
  wire  [WIDTH - 1 :0]  FILTERED_DATA_U;


  clk_div_4 gen_mclkin (
    .clk(clk),
    .clk_div_4(mclkin)

  );

  word_clk gen_word_clk (
  .mclkin(mclkin),
  .word_clk(word_clk)
  
  );
  
  data_adc SIGMA_DELTA_DATA (
  .data_in_i(data_in_i),
  .data_in_u(data_in_u),
  .mclkin(mclkin),
  .mdat_i(mdat_i),
  .mdat_u(mdat_u)

  );

  filter_sinc3 data_filter_I (
  .mclkin(mclkin),
  .mdata1(mdat_i),
  .word_clk(word_clk),
  .DATA(FILTERED_DATA_I)

  );

  filter_sinc3 data_filter_U (
  .mclkin(mclkin),
  .mdata1(mdat_u),
  .word_clk(word_clk),
  .DATA(FILTERED_DATA_U)

  );
  
  uart_tx #(
  .DATA_BITS(8),
  .STOP_BITS(1),
  .FIRST_BIT("msb"),
  .BAUDRATE(115200),
  .CLK_FREQ(18_750_000)
  
) send_data (
  .clk(clk),
  .tx(data_tx),
  .tx_valid(word_clk),
  .tx_data(FILTERED_DATA_I)
  
);  
  
endmodule