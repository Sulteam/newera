module data_adc (
  input     wire     mclkin,
  input     wire     rst,

  input     wire     data_in_i1,   
  input     wire     data_in_u1,
  input     wire     data_in_i2,   
  input     wire     data_in_u2,
  input     wire     data_in_i3,   
  input     wire     data_in_u3,

  output    reg      mdat_i1,       
  output    reg      mdat_u1,
  output    reg      mdat_i2,       
  output    reg      mdat_u2, 
  output    reg      mdat_i3,       
  output    reg      mdat_u3     
  
);


  always @(posedge mclkin, posedge rst) begin
    if(rst) begin
      mdat_i1 <= 0;
      mdat_u1 <= 0;  
      mdat_i2 <= 0;
      mdat_u2 <= 0;
      mdat_i3 <= 0;
      mdat_u3 <= 0;
      
    end else begin  
      mdat_i1 <= data_in_i1;
      mdat_u1 <= data_in_u1;  
      mdat_i2 <= data_in_i2;
      mdat_u2 <= data_in_u2;
      mdat_i3 <= data_in_i3;
      mdat_u3 <= data_in_u3;  
    
    end
  end
  
endmodule