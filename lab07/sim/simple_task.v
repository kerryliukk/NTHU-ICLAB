// initialize dram
task init_dram;
integer i;
begin
  en_a = 0; addr_a = 0; data = 0;
  #(CYCLE) en_a = 1;
  for(i=0; i<2**DRAM_ADDR_WIDTH; i=i+1) begin
    addr_a= i;
    #(CYCLE);
  end
  en_a = 0;
end
endtask

// read data from image and write to dram
task read_image_to_dram;
input [511:0] loc;
integer file, i, r;
begin
  i = 0; en_a = 1;
  file = $fopen(loc, "rb");
  while(!$feof(file)) begin
    r = $fscanf(file, "%c%c%c", data[7:0], data[15:8], data[23:16]);
    // $display("%d", data);
    addr_a = i;
    i = i+1;
    #(CYCLE);
  end
  $fclose(file);
  en_a = 0; data = 0; addr_a = 0;
end
endtask
