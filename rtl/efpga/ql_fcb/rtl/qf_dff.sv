//--------------------------------------------------------------------------------//
//--										--//
//-- QuickLogic confidential 2016     						--// 
//--										--//
//-- File name 		: qf_dff.sv						--//	
//-- Create time 	: Fri Sep 23 10:53:26 2016				--// 
//-- Owner		: jcheng 						--//
//-- 										--//
//-- Function Description :							--//
//--										--//
//--										--//
//-- Modification 	 							--//
//-- 1. 									--//
//-- Date 		:							--//
//-- Owner 		:							--//
//-- Change(s) 		:							--//
//--										--//
//--										--//
//--										--//
//--------------------------------------------------------------------------------//

module qf_dff 
#(
parameter               PAR_DFF_WIDTH = 2 
)
(
        //------------------------------------------------------------------------//
        //-- INPUT PORT                                                         --//
        //------------------------------------------------------------------------//
        	//----------------------------------------------------------------//
        	//-- CLK							--//
        	//----------------------------------------------------------------//
input logic				dest_clk ,
input logic				dest_rst_n ,
        	//----------------------------------------------------------------//
        	//-- Comment							--//
        	//----------------------------------------------------------------//
input logic [PAR_DFF_WIDTH-1:0] 	org_data ,
        //------------------------------------------------------------------------//
        //-- OUTPUT PORT                                                        --//
        //------------------------------------------------------------------------//
output logic [PAR_DFF_WIDTH-1:0] 	dest_data 
);
        //------------------------------------------------------------------------//
        //-- Declare Time Unit                                                  --//
        //------------------------------------------------------------------------//
timeunit                1ns;
timeprecision           100ps ;

        //------------------------------------------------------------------------//
        //-- Local Parameter                                                    --//
        //------------------------------------------------------------------------//
localparam              PAR_DLY = 1'b1 ;

        //------------------------------------------------------------------------//
        //-- EMUN/Flops                                                         --//
        //------------------------------------------------------------------------//
        //------------------------------------------------------------------------//
        //-- Wire/Flops                                                         --//
        //------------------------------------------------------------------------//
logic [PAR_DFF_WIDTH-1:0]		dest_data_syncff1 ;
logic [PAR_DFF_WIDTH-1:0]		dest_data_syncff2 ;

//--------------------------------------------------------------------------------//
//-- Start Functional Description                                               --//
//--------------------------------------------------------------------------------//
assign dest_data = dest_data_syncff2 ;
        //------------------------------------------------------------------------//
        //-- Comment                                                            --//
        //------------------------------------------------------------------------//
always_ff @ ( posedge dest_clk or negedge dest_rst_n )
begin
  if ( dest_rst_n == 1'b0 )
    begin
        dest_data_syncff1 <= #PAR_DLY 'b0 ;
        dest_data_syncff2 <= #PAR_DLY 'b0 ;
    end
  else
    begin
        dest_data_syncff1 <= #PAR_DLY org_data ;
        dest_data_syncff2 <= #PAR_DLY dest_data_syncff1 ;
    end
end

//--------------------------------------------------------------------------------//
//-- END                                                                        --//
//--------------------------------------------------------------------------------//
endmodule

