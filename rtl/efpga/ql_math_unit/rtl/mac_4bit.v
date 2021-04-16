module MAC_4BIT (
  //OUTPUT
  MAC_OUT,
  //INPUT
  MAC_ACC_CLK,
  EFPGA_MATHB_CLK_EN,
  MAC_OPER_DATA,
  MAC_COEF_DATA,
  MAC_ACC_RND,
  MAC_ACC_CLEAR,
  MAC_ACC_SAT,
  MAC_OUT_SEL,  
  MAC_TC,
  acc_ff_rstn
);

  parameter MULTI_WIDTH   = 4;
  parameter TC            = 1'b0;
  parameter PAD_ZERO      = 4;
  parameter DATAIN_WIDTH  = MULTI_WIDTH+PAD_ZERO ;
  parameter ACC_WIDTH     = 2*(MULTI_WIDTH+PAD_ZERO) ;

//OUTPUT
output [7:0] MAC_OUT;

//INPUT
input        MAC_ACC_CLK;
input        EFPGA_MATHB_CLK_EN;
input  [3:0] MAC_OPER_DATA;
input  [3:0] MAC_COEF_DATA;
input        MAC_ACC_RND;
input        MAC_ACC_CLEAR;
input        MAC_ACC_SAT;
input  [5:0] MAC_OUT_SEL;  
input        MAC_TC;
input        acc_ff_rstn;


/*------------------------------*/
/*                              */
/*------------------------------*/
reg  [ 5:0] fMAC_OUT_SEL; 
reg  [19:0] mux_acc_idata; 
reg  [19:0] fmux_acc_idata;
reg  [3: 0] MAC_OUT;
reg  [19:0] is_rounded_value; 
reg  [19:0] feedback_acc_data;  
reg         is_not_saturation;
reg  [3: 0] acc_data_out_sel; 

wire [19:0] DWMAC_out;

/*------------------------------*/
/*       INPUT SYNC/DELAY       */
/*------------------------------*/
//vincent@20181102always@(posedge MAC_ACC_CLK) begin : DELAY_OF_MAC_OUT_SEL
always@(posedge MAC_ACC_CLK or negedge acc_ff_rstn) begin : DELAY_OF_MAC_OUT_SEL
  if (~acc_ff_rstn)
    fMAC_OUT_SEL <= #0.2 'h0;
  else  
    fMAC_OUT_SEL <= #0.2 MAC_OUT_SEL;
end //DELAY_OF_MAC_OUT_SEL

/*------------------------------*/
/*          MAC_UNIT            */
/*------------------------------*/
   wire [5:0] oper_sign, coef_sign;
   assign oper_sign = MAC_TC ? {6{MAC_OPER_DATA[3]}} : 4'b0000;
   assign coef_sign = MAC_TC ? {6{MAC_COEF_DATA[3]}} : 4'b0000;   
DW02_mac #( 
.A_width (10),
.B_width (10)
)	
U_DW02_mac (   
//vincent@20181101.A  ({2'h0,MAC_OPER_DATA[7:0]}), 
//vincent@20181101.B  ({2'h0,MAC_COEF_DATA[7:0]}), 
.A  ({oper_sign,MAC_OPER_DATA[3:0]}), 
.B  ({coef_sign,MAC_COEF_DATA[3:0]}), 
.C  (feedback_acc_data[19:0]), 
.TC (MAC_TC), 
.MAC(DWMAC_out[19:0])
);

/*------------------------------*/
/*        LOAD of ACC           */
/*------------------------------*/
always@(*) begin: MUX_OF_IDATA_ACC
  mux_acc_idata = fmux_acc_idata;
  case (EFPGA_MATHB_CLK_EN)
    1'b0: mux_acc_idata = fmux_acc_idata;
    1'b1: mux_acc_idata = DWMAC_out;
  endcase
end //MUX_OF_IDATA_ACC

/*------------------------------*/
/*        ACCUMULATOR           */
/*------------------------------*/
//vicnent@20181029always@(posedge MAC_ACC_CLK) begin : FF_OF_ACCUMULATOR
//vincent@20181031assign acc_rstn = ~MAC_ACC_CLEAR;   

always@(posedge MAC_ACC_CLK or negedge acc_ff_rstn) begin : FF_OF_ACCUMULATOR
  if (~acc_ff_rstn)
    fmux_acc_idata <= #0.2 24'h0;
  else  
    fmux_acc_idata <= #0.2 mux_acc_idata;
end //FF_OF_ACCUMULATOR

/*------------------------------*/
/*         ACC_ROUNDED          */
/*------------------------------*/
always@(*) begin : ACC_ROUNDED
  case(MAC_OUT_SEL[5:0])
    6'd1  : is_rounded_value = 20'b0000_0000_0000_0000_0001;
    6'd2  : is_rounded_value = 20'b0000_0000_0000_0000_0010;
    6'd3  : is_rounded_value = 20'b0000_0000_0000_0000_0100;
    6'd4  : is_rounded_value = 20'b0000_0000_0000_0000_1000;
    6'd5  : is_rounded_value = 20'b0000_0000_0000_0001_0000;
    6'd6  : is_rounded_value = 20'b0000_0000_0010_0000;
    6'd7  : is_rounded_value = 20'b0000_0000_0100_0000;
    6'd8  : is_rounded_value = 20'b0000_0000_0000_1000_0000;
    6'd9  : is_rounded_value = 20'b0000_0000_0001_0000_0000;
    6'd10 : is_rounded_value = 20'b0000_0000_0010_0000_0000;
    6'd11 : is_rounded_value = 20'b0000_0000_0100_0000_0000;
    6'd12 : is_rounded_value = 20'b0000_0000_1000_0000_0000;
    6'd13 : is_rounded_value = 20'b0000_0001_0000_0000_0000;
    6'd14 : is_rounded_value = 20'b0000_0010_0000_0000_0000;
    6'd15 : is_rounded_value = 20'b0000_0100_0000_0000_0000;
    6'd16 : is_rounded_value = 20'b0000_1000_0000_0000_0000;
  default: is_rounded_value = 20'h0;
  endcase
end                             

/*------------------------------*/
/*         CLR_AND_RND          */
/*------------------------------*/
always@(*) begin: CLR_AND_RND
  if (MAC_ACC_CLEAR == 1'b1)
    feedback_acc_data = 16'h0;
  else if (MAC_ACC_RND == 1'b1)
    feedback_acc_data = is_rounded_value;
  else
    feedback_acc_data = fmux_acc_idata;  
end //CLR_AND_RND

/*------------------------------*/
/*     MAC_DATA_OUT_wo_SAT      */
/*------------------------------*/
always@(*) begin : ACC_DATA_OUT_SEL
  case(fMAC_OUT_SEL[5:0])
    6'd0  : acc_data_out_sel = fmux_acc_idata[3:0];
    6'd1  : acc_data_out_sel = fmux_acc_idata[4:1];
    6'd2  : acc_data_out_sel = fmux_acc_idata[5:2];
    6'd3  : acc_data_out_sel = fmux_acc_idata[6:3];
    6'd4  : acc_data_out_sel = fmux_acc_idata[7:4];
    6'd5  : acc_data_out_sel = fmux_acc_idata[8:5];
    6'd6  : acc_data_out_sel = fmux_acc_idata[9:6];
    6'd7  : acc_data_out_sel = fmux_acc_idata[10:7];
    6'd8  : acc_data_out_sel = fmux_acc_idata[11:8];
    6'd9  : acc_data_out_sel = fmux_acc_idata[12:9];
    6'd10 : acc_data_out_sel = fmux_acc_idata[13:10];
    6'd11 : acc_data_out_sel = fmux_acc_idata[14:11];
    6'd12 : acc_data_out_sel = fmux_acc_idata[15:12];
    6'd13 : acc_data_out_sel = fmux_acc_idata[16:13];
    6'd14 : acc_data_out_sel = fmux_acc_idata[17:14];
    6'd15 : acc_data_out_sel = fmux_acc_idata[18:15];
    6'd16 : acc_data_out_sel = fmux_acc_idata[19:16];
    default : acc_data_out_sel = fmux_acc_idata[3:0];
  endcase
end

/*------------------------------*/
/*           ACC_SAT            */
/*------------------------------*/
//vincent@20181031always@(*) begin : CHECK_SAT_CONDITION
//vincent@20181031  case(fMAC_OUT_SEL[5:0])
//vincent@20181031  6'd0  : is_not_saturation = &fmux_acc_idata[19:8]  || !(|fmux_acc_idata[19:8]) ;
//vincent@20181031  6'd1  : is_not_saturation = &fmux_acc_idata[19:9]  || !(|fmux_acc_idata[19:9]) ;
//vincent@20181031  6'd2  : is_not_saturation = &fmux_acc_idata[19:10] || !(|fmux_acc_idata[19:10]) ;
//vincent@20181031  6'd3  : is_not_saturation = &fmux_acc_idata[19:11] || !(|fmux_acc_idata[19:11]) ;
//vincent@20181031  6'd4  : is_not_saturation = &fmux_acc_idata[19:12] || !(|fmux_acc_idata[19:12]) ;
//vincent@20181031  6'd5  : is_not_saturation = &fmux_acc_idata[19:13] || !(|fmux_acc_idata[19:13]) ;
//vincent@20181031  6'd6  : is_not_saturation = &fmux_acc_idata[19:14] || !(|fmux_acc_idata[19:14]) ;
//vincent@20181031  6'd7  : is_not_saturation = &fmux_acc_idata[19:15] || !(|fmux_acc_idata[19:15]) ;
//vincent@20181031  6'd8  : is_not_saturation = &fmux_acc_idata[19:16] || !(|fmux_acc_idata[19:16]) ;
//vincent@20181031  6'd9  : is_not_saturation = &fmux_acc_idata[19:17] || !(|fmux_acc_idata[19:17]) ;
//vincent@20181031  6'd10 : is_not_saturation = &fmux_acc_idata[19:18] || !(|fmux_acc_idata[19:18]) ;
//vincent@20181031  default : is_not_saturation = &fmux_acc_idata[19:8] || !(|fmux_acc_idata[19:8]) ;
//vincent@20181031  endcase
//vincent@20181031end

always@(*) begin : CHECK_SAT_CONDITION
  case(fMAC_OUT_SEL[5:0])
    6'd0  : is_not_saturation = &fmux_acc_idata[19:3]  || !(|fmux_acc_idata[19:3]) ;
    6'd1  : is_not_saturation = &fmux_acc_idata[19:4]  || !(|fmux_acc_idata[19:4]) ;
    6'd2  : is_not_saturation = &fmux_acc_idata[19:5]  || !(|fmux_acc_idata[19:5]) ;
    6'd3  : is_not_saturation = &fmux_acc_idata[19:6] || !(|fmux_acc_idata[19:6]) ;
    6'd4  : is_not_saturation = &fmux_acc_idata[19:7] || !(|fmux_acc_idata[19:7]) ;
    6'd5  : is_not_saturation = &fmux_acc_idata[19:8] || !(|fmux_acc_idata[19:8]) ;
    6'd6  : is_not_saturation = &fmux_acc_idata[19:9] || !(|fmux_acc_idata[19:9]) ;
    6'd7  : is_not_saturation = &fmux_acc_idata[19:10] || !(|fmux_acc_idata[19:10]) ;
    6'd8  : is_not_saturation = &fmux_acc_idata[19:11] || !(|fmux_acc_idata[19:11]) ;
    6'd9  : is_not_saturation = &fmux_acc_idata[19:12] || !(|fmux_acc_idata[19:12]) ;
    6'd10 : is_not_saturation = &fmux_acc_idata[19:13] || !(|fmux_acc_idata[19:13]) ;
    6'd11 : is_not_saturation = &fmux_acc_idata[19:14] || !(|fmux_acc_idata[19:14]) ;
    6'd12  : is_not_saturation = &fmux_acc_idata[19:15] || !(|fmux_acc_idata[19:15]) ;
    6'd13  : is_not_saturation = &fmux_acc_idata[19:16] || !(|fmux_acc_idata[19:16]) ;
    6'd14 : is_not_saturation = &fmux_acc_idata[19:17] || !(|fmux_acc_idata[19:17]) ;
    6'd15 : is_not_saturation = &fmux_acc_idata[19:18] || !(|fmux_acc_idata[19:18]) ;

    default : is_not_saturation = &fmux_acc_idata[19:7] || !(|fmux_acc_idata[19:7]) ;
  endcase
end

always@(*) begin : ACC_SAT_DATA_OUT
  if (MAC_ACC_SAT)
    if ( is_not_saturation )
      MAC_OUT = acc_data_out_sel;
    else begin
      if (fmux_acc_idata[19] == 1'b1)
        MAC_OUT = {1'b1,3'h0};
      else 
        MAC_OUT = {1'b0,3'h7};
    end
  else 
     MAC_OUT = acc_data_out_sel;	  
end


endmodule

