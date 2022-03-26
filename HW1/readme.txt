⚫ How you organize the testbench in Part 2, Part 3 and Part4.
Part 2中，輸入的部分我用了四層迴圈去iter該有的組合，包含了i j k都從0跑到2的N次方，而l從0跑到14，代表了第一大題中LUT接受的15種Mode。而這些i j k l就分別是P S D Mode餵給lut16以及smart。
測試的部分我仿照之前lab的方法，用相同的迴圈在時間對起來之後，逐個檢查兩者的輸出是否相同，若有不同則印出並結束。
Part 3中，和Part 2極為類似，只是四層迴圈都是跑0~2^N，也就是會iter過所有的P S D Mode，並作和Part 2相同的檢查。
Part 4中，我只是將原本的給輸入的迴圈，以及對答案的迴圈都變成task寫到外面而已，其餘不變。

⚫ How you find out all the 256 functions.
觀察作業第一頁的LUT，可以發現將Mode寫出來之後，Mode的哪幾個bit=1，就代表Result是哪幾項的sum of minterm，最後我用Python將之實作出來。
比如說Mode = 8'hC0 (也就是8'b11000000)時，代表Result = P&S&D | P&S&~D。

⚫ Corresponding commands for mode=0-63, 64-127 and 128-255 in test_rop3.v (Part4).
$ ncverilog test_rop3.v rop3_lut256.v rop3_smart.v +define+ MODE_L=0+MODE_U=63
$ ncverilog test_rop3.v rop3_lut256.v rop3_smart.v +define+ MODE_L=64+MODE_U=127
$ ncverilog test_rop3.v rop3_lut256.v rop3_smart.v +define+ MODE_L=128+MODE_U=255