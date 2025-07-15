module top #(
  parameter WIDTH = 16 
  ) (
    input    clk,               // тактовая частота в 75 МГц
    input    data_in_i1,        // сигма-дельта модуляция 
    input    data_in_u1,        // сигма-дельта модуляция 
    input    data_in_i2,
    input    data_in_u2,
    input    data_in_i3,
    input    data_in_u3,
    output   mclkin,           // тактовая частота для АЦП
    output   data_tx           // манчестерский код 
     

);
  
  wire      mdat_i1;
  wire      mdat_u1;
  wire      mdat_i2;
  wire      mdat_u2;
  wire      mdat_i3;
  wire      mdat_u3;

  // internal wires for packager
  wire      data_out;
  wire      tx_ready_pac;
  wire      tx_valid_pac;

  wire      word_clk;

  wire  [WIDTH - 1 :0]  FILTERED_DATA_I1;
  wire  [WIDTH - 1 :0]  FILTERED_DATA_U1;
  wire  [WIDTH - 1 :0]  FILTERED_DATA_I2;
  wire  [WIDTH - 1 :0]  FILTERED_DATA_U2;
  wire  [WIDTH - 1 :0]  FILTERED_DATA_I3;
  wire  [WIDTH - 1 :0]  FILTERED_DATA_U3;


  clk_div_4 gen_mclkin (
    .clk(clk),
    .clk_div_4(mclkin)

  );

  word_clk gen_word_clk (
  .mclkin(mclkin),
  .word_clk(word_clk)
  
  );
  
  data_adc SIGMA_DELTA_DATA (
  .data_in_i1(data_in_i1),
  .data_in_u1(data_in_u1),
  .data_in_i2(data_in_i2),
  .data_in_u2(data_in_u2),
  .data_in_i3(data_in_i3),
  .data_in_u3(data_in_u3),
  .mclkin(mclkin),
  .mdat_i1(mdat_i1),
  .mdat_u1(mdat_u1)
  .mdat_i2(mdat_i2),
  .mdat_u2(mdat_u2)
  .mdat_i3(mdat_i3),
  .mdat_u3(mdat_u3)

  );

  filter_sinc3 data_filter_I1 (
  .mclkin(mclkin),
  .mdata1(mdat_i1),
  .word_clk(word_clk),
  .DATA(FILTERED_DATA_I1)

  );

  filter_sinc3 data_filter_U1 (
  .mclkin(mclkin),
  .mdata1(mdat_u1),
  .word_clk(word_clk),
  .DATA(FILTERED_DATA_U1)

  );
  filter_sinc3 data_filter_I2 (
  .mclkin(mclkin),
  .mdata1(mdat_i2),
  .word_clk(word_clk),
  .DATA(FILTERED_DATA_I2)

  );

  filter_sinc3 data_filter_U2 (
  .mclkin(mclkin),
  .mdata1(mdat_u2),
  .word_clk(word_clk),
  .DATA(FILTERED_DATA_U2)

  );
  filter_sinc3 data_filter_I3 (
  .mclkin(mclkin),
  .mdata1(mdat_i3),
  .word_clk(word_clk),
  .DATA(FILTERED_DATA_I3)

  );

  filter_sinc3 data_filter_U3 (
  .mclkin(mclkin),
  .mdata1(mdat_u3),
  .word_clk(word_clk),
  .DATA(FILTERED_DATA_U3)

  );

  packager form_pack (
  .clk(mclkin),
  .data_adc0(FILTERED_DATA_I1),
  .data_adc1(FILTERED_DATA_U1),
  .data_adc2(FILTERED_DATA_I2),
  .data_adc3(FILTERED_DATA_U2),
  .data_adc4(FILTERED_DATA_I3),
  .data_adc5(FILTERED_DATA_U3),

  .write_enable(word_clk),
  .tx_ready(tx_ready_pac),
  .tx_valid(tx_valid_pac),
  .data_out(data_out)

);
  
  uart_tx #(
  .DATA_BITS(8),
  .STOP_BITS(2),
  .BAUDRATE(115200),
  .CLK_FREQ(18_750_000)
  
) send_data (
  .clk(clk),
  .tx(data_tx),
  .tx_valid(tx_ready_pac),
  .tx_ready(tx_valid_pac),
  .tx_data(data_out)
  
);  
  
endmodule