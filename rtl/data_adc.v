module data_adc (
  input     wire     mclkin,
  input     wire     data_in_i,   
  input     wire     data_in_u,    
  output    reg      mdat_i,       
  output    reg      mdat_u       
  
);


  always @(posedge mclkin) begin
    mdat_i <= data_in_i;
    mdat_u <= data_in_u;      
    
  end
  
endmodule