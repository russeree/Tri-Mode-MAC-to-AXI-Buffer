//////////////////////////////////////////////////////////////////////////////////
// Company: rFPGA
// Engineer: Reese Russell
// 
// Create Date: 12/21/2015 06:59:09 AM
// Design Name: rFPGA ETHERNET IP
// Module Name: top_intercon
// Project Name: rFPGA EtherIP 
// Target Devices: Kintex7 325T
// Tool Versions: Vivado 2015.4
// Description: 14.4
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "timescale.vh"

module top_intercon();
    /** 
     * MicroBlaze Soft Processor instatiation
     */
    microblaze_0 microblaze_0 (
        .Clk (),
        .Reset(), 
        .Interrupt(),
        .Interrupt_Address(), 
        .Interrupt_Ack(), 
        .Instr_Addr(), 
        .Instr(), 
        .IFetch(), 
        .I_AS(), 
        .IReady(), 
        .IWAIT(), 
        .ICE(), 
        .IUE(),
        .Data_Addr(), 
        .Data_Read(), 
        .Data_Write(), 
        .D_AS(), 
        .Read_Strobe(), 
        .Write_Strobe(), 
        .DReady(), 
        .DWait(), 
        .DCE(), 
        .DUE(), 
        .Byte_Enable(), 
        .M_AXI_DP_AWADDR(), 
        .M_AXI_DP_AWPROT(), 
        .M_AXI_DP_AWVALID(), 
        .M_AXI_DP_AWREADY(), 
        .M_AXI_DP_WDATA(), 
        .M_AXI_DP_WSTRB(), 
        .M_AXI_DP_WVALID(), 
        .M_AXI_DP_WREADY(), 
        .M_AXI_DP_BRESP(), 
        .M_AXI_DP_BVALID(), 
        .M_AXI_DP_BREADY(), 
        .M_AXI_DP_ARADDR(), 
        .M_AXI_DP_ARPROT(), 
        .M_AXI_DP_ARVALID(), 
        .M_AXI_DP_ARREADY(), 
        .M_AXI_DP_RDATA(), 
        .M_AXI_DP_RRESP(), 
        .M_AXI_DP_RVALID(), 
        .M_AXI_DP_RREADY());
endmodule
