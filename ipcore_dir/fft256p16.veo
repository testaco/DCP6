/*******************************************************************************
*     This file is owned and controlled by Xilinx and must be used solely      *
*     for design, simulation, implementation and creation of design files      *
*     limited to Xilinx devices or technologies. Use with non-Xilinx           *
*     devices or technologies is expressly prohibited and immediately          *
*     terminates your license.                                                 *
*                                                                              *
*     XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" SOLELY     *
*     FOR USE IN DEVELOPING PROGRAMS AND SOLUTIONS FOR XILINX DEVICES.  BY     *
*     PROVIDING THIS DESIGN, CODE, OR INFORMATION AS ONE POSSIBLE              *
*     IMPLEMENTATION OF THIS FEATURE, APPLICATION OR STANDARD, XILINX IS       *
*     MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION IS FREE FROM ANY       *
*     CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE FOR OBTAINING ANY        *
*     RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY        *
*     DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE    *
*     IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR           *
*     REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF          *
*     INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A    *
*     PARTICULAR PURPOSE.                                                      *
*                                                                              *
*     Xilinx products are not intended for use in life support appliances,     *
*     devices, or systems.  Use in such applications are expressly             *
*     prohibited.                                                              *
*                                                                              *
*     (c) Copyright 1995-2013 Xilinx, Inc.                                     *
*     All rights reserved.                                                     *
*******************************************************************************/

/*******************************************************************************
*     Generated from core with identifier: xilinx.com:ip:xfft:7.1              *
*                                                                              *
*     The Fast Fourier Transform (FFT) is a computationally efficient          *
*     algorithm for computing the Discrete Fourier Transform (DFT). The FFT    *
*     Core can compute 8 to 65536-point forward or inverse complex             *
*     transforms on up to 12 parallel channels. The input data is a vector     *
*     of complex values represented as two's-complement numbers 8 to 34        *
*     bits wide or single precision floating point numbers 32 bits wide.       *
*     The phase factors can be 8 to 34 bits wide. All memory is on-chip        *
*     using either Block RAM or Distributed RAM. Three arithmetic types are    *
*     available: full-precision unscaled, scaled fixed-point, and              *
*     block-floating point. Several parameters are run-time configurable:      *
*     the point size, the choice of forward or inverse transform, and the      *
*     scaling schedule. Four architectures are available to provide a          *
*     tradeoff between size and transform time.                                *
*******************************************************************************/

// Interfaces:
//    nfft_intf
//    clk_intf
//    sclr_intf
//    ce_intf
//    nfft_we_intf
//    start_intf
//    unload_intf
//    cp_len_intf
//    cp_len_we_intf
//    xn_re_intf
//    xn_im_intf
//    fwd_inv_intf
//    fwd_inv_we_intf
//    scale_sch_intf
//    scale_sch_we_intf
//    xn0_re_intf
//    xn0_im_intf
//    xn1_re_intf
//    xn1_im_intf
//    xn2_re_intf
//    xn2_im_intf
//    xn3_re_intf
//    xn3_im_intf
//    xn4_re_intf
//    xn4_im_intf
//    xn5_re_intf
//    xn5_im_intf
//    xn6_re_intf
//    xn6_im_intf
//    xn7_re_intf
//    xn7_im_intf
//    xn8_re_intf
//    xn8_im_intf
//    xn9_re_intf
//    xn9_im_intf
//    xn10_re_intf
//    xn10_im_intf
//    xn11_re_intf
//    xn11_im_intf
//    fwd_inv0_intf
//    fwd_inv0_we_intf
//    fwd_inv1_intf
//    fwd_inv1_we_intf
//    fwd_inv2_intf
//    fwd_inv2_we_intf
//    fwd_inv3_intf
//    fwd_inv3_we_intf
//    fwd_inv4_intf
//    fwd_inv4_we_intf
//    fwd_inv5_intf
//    fwd_inv5_we_intf
//    fwd_inv6_intf
//    fwd_inv6_we_intf
//    fwd_inv7_intf
//    fwd_inv7_we_intf
//    fwd_inv8_intf
//    fwd_inv8_we_intf
//    fwd_inv9_intf
//    fwd_inv9_we_intf
//    fwd_inv10_intf
//    fwd_inv10_we_intf
//    fwd_inv11_intf
//    fwd_inv11_we_intf
//    scale_sch0_intf
//    scale_sch0_we_intf
//    scale_sch1_intf
//    scale_sch1_we_intf
//    scale_sch2_intf
//    scale_sch2_we_intf
//    scale_sch3_intf
//    scale_sch3_we_intf
//    scale_sch4_intf
//    scale_sch4_we_intf
//    scale_sch5_intf
//    scale_sch5_we_intf
//    scale_sch6_intf
//    scale_sch6_we_intf
//    scale_sch7_intf
//    scale_sch7_we_intf
//    scale_sch8_intf
//    scale_sch8_we_intf
//    scale_sch9_intf
//    scale_sch9_we_intf
//    scale_sch10_intf
//    scale_sch10_we_intf
//    scale_sch11_intf
//    scale_sch11_we_intf
//    rfd_intf
//    xn_index_intf
//    busy_intf
//    edone_intf
//    done_intf
//    dv_intf
//    xk_index_intf
//    cpv_intf
//    rfs_intf
//    xk_re_intf
//    xk_im_intf
//    blk_exp_intf
//    ovflo_intf
//    xk0_re_intf
//    xk0_im_intf
//    xk1_re_intf
//    xk1_im_intf
//    xk2_re_intf
//    xk2_im_intf
//    xk3_re_intf
//    xk3_im_intf
//    xk4_re_intf
//    xk4_im_intf
//    xk5_re_intf
//    xk5_im_intf
//    xk6_re_intf
//    xk6_im_intf
//    xk7_re_intf
//    xk7_im_intf
//    xk8_re_intf
//    xk8_im_intf
//    xk9_re_intf
//    xk9_im_intf
//    xk10_re_intf
//    xk10_im_intf
//    xk11_re_intf
//    xk11_im_intf
//    blk_exp0_intf
//    blk_exp1_intf
//    blk_exp2_intf
//    blk_exp3_intf
//    blk_exp4_intf
//    blk_exp5_intf
//    blk_exp6_intf
//    blk_exp7_intf
//    blk_exp8_intf
//    blk_exp9_intf
//    blk_exp10_intf
//    blk_exp11_intf
//    ovflo0_intf
//    ovflo1_intf
//    ovflo2_intf
//    ovflo3_intf
//    ovflo4_intf
//    ovflo5_intf
//    ovflo6_intf
//    ovflo7_intf
//    ovflo8_intf
//    ovflo9_intf
//    ovflo10_intf
//    ovflo11_intf

// The following must be inserted into your Verilog file for this
// core to be instantiated. Change the instance name and port connections
// (in parentheses) to your own signal names.

//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
fft256p16 your_instance_name (
  .clk(clk), // input clk
  .nfft(nfft), // input [4 : 0] nfft
  .nfft_we(nfft_we), // input nfft_we
  .start(start), // input start
  .unload(unload), // input unload
  .xn_re(xn_re), // input [15 : 0] xn_re
  .xn_im(xn_im), // input [15 : 0] xn_im
  .fwd_inv(fwd_inv), // input fwd_inv
  .fwd_inv_we(fwd_inv_we), // input fwd_inv_we
  .scale_sch(scale_sch), // input [15 : 0] scale_sch
  .scale_sch_we(scale_sch_we), // input scale_sch_we
  .rfd(rfd), // output rfd
  .xn_index(xn_index), // output [7 : 0] xn_index
  .busy(busy), // output busy
  .edone(edone), // output edone
  .done(done), // output done
  .dv(dv), // output dv
  .xk_index(xk_index), // output [7 : 0] xk_index
  .xk_re(xk_re), // output [15 : 0] xk_re
  .xk_im(xk_im) // output [15 : 0] xk_im
);
// INST_TAG_END ------ End INSTANTIATION Template ---------

// You must compile the wrapper file fft256p16.v when simulating
// the core, fft256p16. When compiling the wrapper file, be sure to
// reference the XilinxCoreLib Verilog simulation library. For detailed
// instructions, please refer to the "CORE Generator Help".

