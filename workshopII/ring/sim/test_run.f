test_cnn.v

../hdl/conv_define.v
../hdl/conv_top.v
../hdl/conv3x3_16to4ch.v
../hdl/conv1x1_16to4ch.v
../hdl/matmul.v
../hdl/conv_adder.v
../hdl/postproc.v
../hdl/shift_ctrl.v
../hdl/ReLU.v
../hdl/residual_add.v
../hdl/quantization_1ch.v

+define+RING  // FIX_16, DYN_8, RING
+define+RESBLOCK1 // CONV1, RESBLOCK1, RESBLOCK2, IMAGE_OUT

// testcases: 
//  Debugging: bw8R4 (240x160)
//  HiddenImg: LR_crossing_120x80, LR_horse_75x60, LR_panda_106x60, LR_pups_85x60(Don't check result)
+define+IN_DIR=\"bw8R4\"
// +define+IN_DIR=\"LR_pups_85x60\" 
+define+BLOCK_WIDTH=240
+define+BLOCK_HEIGHT=160 
+define+CHECK_RESULT // Don't check result for hidden image because there is no golden output.

+access+r
