//////////////////////////////////////////////////////////////////////////////////
// Company: rFPGA
// Engineer: Reese Russell 
// 
// Create Date: 12/15/2015 10:46:51 PM
// Design Name: TRI MODE ETHERNET MAC SIMPLE MAC STIMULUS 
// Module Name: TRI_MODE_MAC_STIMULUS
// Project Name: rFPGA Ethernet Core 
// Target Devices: Kintex 7 XC7325T
// Tool Versions: 2015.4 Vivado
// Description: Simple tri mode full packet out stimilus; A more complete
// implementation is on the way. 
// Dependencies: None
// 
// Revision: 0.0.1
// Revision 0.01 - File Created
// Additional Comments: GNU 3 license, MUST DEFINE _SIMULATION 
// 
//////////////////////////////////////////////////////////////////////////////////
`include "timescale.vh"
`include "TRI_MODE_MAC_SIM_DEF.vh"

`ifdef _SIMULATION
module TRI_MODE_MAC_STIMULUS(
    /* OUTPUT FROM MAC */ 
    output reg        mac_clk_o, 
    output reg        mac_rst_o,
    output reg [31:0] mac_rxd_o,
    output reg [1:0]  mac_ben_i,
    output reg        mac_rxda_i,                            
    output reg        mac_rxsop_i,                           
    output reg        mac_rxeop_i,                           
    output reg        mac_rxdv_i,                            
    /* INPUT TO MAC */ 
    input         wire mac_rxrqrd_i                    
    );
    parameter mem_entries = 32768;
    reg [31:0] mem_array [mem_entries - 1:0];
    int i;
    
    /* Inital Statments */
    initial begin
        mac_clk_o   = `_false;       
        mac_rst_o   = `_false;       
        mac_rxd_o   = `_false;
        mac_ben_i   = `_false;       
        mac_rxda_i  = `_false;      
        mac_rxsop_i = `_false;     
        mac_rxeop_i = `_false;     
        mac_rxdv_i  = `_false;
        tsk_mem_ld();
        tsk_rst();
    end 
    /* RESET TASK */
    task tsk_rst;
        `_RST_DLY mac_rst_o = !mac_rst_o;
        `_RST_HLD mac_rst_o = !mac_rst_o; 
    endtask
    /* MEMORY LOAD WITH RANDOM DATA */
    task tsk_mem_ld;
        for(i = 0; i < mem_entries; i++) begin
            mem_array[i] = $random;
        end
        foreach (mem_array[i]) begin
            $write(" %h", mem_array[i]);
            $display;
        end
    endtask
    /* Task Set Packet Ready */ 
    task tsk_set_
    
endmodule
`endif 
