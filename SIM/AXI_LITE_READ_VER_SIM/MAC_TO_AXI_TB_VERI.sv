/* AUTHOR: Reese Russell
 * LICENSE: GNU3
 * DATE_DMY: 12/14/15
 * NAME: UDP PACKET PARSER MODULE AXI VERIFICATION TESTBENCH
 * DESCRIPTION: This module is designed to test the AXI lite 4 Memory read interface
 */ 
 // DEFINE SIMULATION
`define _SIMULATION
`include "timescale.vh" 

module MAC_TO_AXI_VERI_TB;
    wire        axi_ra_addr_r_int;
    wire [1:0]  axi_r_resp_int;
    wire [31:0] axi_r_data_int;
    wire        axi_r_vald_int ;
    
    reg axi_clk_i;
    reg axi_rst_i;
    reg axi_ra_addr_v_int;
    reg axi_r_ready_int;
    reg [31:0] axi_ra_addr_int;
    
    MAC_TO_AXI_BUFFER AXI_BUF_0(
        .mac_clk_i(mac_clk_o), 
        .mac_rst_i(mac_rst_o), 
        .mac_rxd_i(mac_rxd_o), 
        .mac_ben_i(mac_ben_o), 
        .mac_rxda_i(1'b0), 
        .mac_rxsop_i(1'b0),
        .mac_rxeop_i(1'b0), 
        .mac_rxdv_i(1'b0), 
        .mac_rxrqrd_i(),
        /* AXI SIGNALS */
        .ACLK(axi_clk_i),
        .ARESETN(axi_rst_i),
        .S_AXI_ARADDR(axi_ra_addr_int),
        .S_AXI_ARVALID(axi_ra_addr_v_int),
        .S_AXI_ARREADY(axi_ra_addr_r_int),
        .S_AXI_RDATA(axi_r_data_int),
        .S_AXI_RRESP(axi_r_resp_int), 
        .S_AXI_RVALID(axi_r_vald_int), 
        .S_AXI_RREADY(axi_r_ready_int)
        );
    wire mac_clk_o;
    wire mac_rst_o;
    wire [31:0] mac_rxd_o;
    wire [1:0] mac_ben_o;
    TRI_MODE_MAC_STIMULUS mac_stim_0(
        .mac_clk_o   (mac_clk_o), 
        .mac_rst_o   (mac_rst_o),
        .mac_rxd_o   (mac_rxd_o),
        .mac_ben_o   (mac_ben_o),
        .mac_rxda_o  (),                            
        .mac_rxsop_o (),                           
        .mac_rxeop_o (),                           
        .mac_rxdv_o  (),                            
            /* INPUT TO MAC */ 
        .mac_rxrqrd_i                    
     ); 
    initial begin
        axi_clk_i          =  1'b0;
        axi_rst_i          =  1'b1;
        axi_ra_addr_int    = 32'b0;
        axi_ra_addr_v_int  =  1'b0; 
        axi_r_ready_int    =  1'b0;
        #20 axi_rst_i      =  1'b0;
        #20 axi_rst_i      =  1'b1; 
    end
        
    /* FULL AXI4 LITE READ ADDRESS AND DARA CHANNEL CYCLE */
    task axi4_lite_read_full;
        axi_r_ready_int <= 1'b1; 
        axi_ra_addr_int <= axi_ra_addr_int + 1'b1;
        @(posedge axi_clk_i)
            axi_r_ready_int <= 1'b0;  
            axi_ra_addr_v_int <= 1'b1;
        @(posedge axi_clk_i)
            if (axi_r_vald_int)
                axi_r_ready_int <= 1'b0;
        @(posedge axi_clk_i)
            if (axi_r_vald_int)
                axi_ra_addr_v_int <= 1'b0;
    endtask

    /* Run the teask forever */
    always begin
        axi4_lite_read_full();
    end    
        
        always begin
            #2.5 axi_clk_i = !axi_clk_i;
        end 
            
/* END OF MODULE */
endmodule 