//////////////////////////////////////////////////////////////////////////////////
// Company: rFPGA
// Engineer: Reese Russell 
// 
// Create Date: 12/15/2015 10:46:51 PM
// Design Name: TRI MODE ETHERNET MAC SIMPLE MAC STIMULUS 
// Module Name: TRI_MODE_MAC_STIMULUS
// Project Name: rFPGA Ethernet Core 
// Target Devices: Kintex 7 XC7325T
// Tool Versions: 2015.4 Vivado !!!ISE NOT SUPPROTED!!!
// Description: Simple tri mode full packet out stimilus; A more complete
// implementation is on the way. 
// Dependencies: VIVADO
// 
// Revision: 0.0.1
// Revision 0.0.2 Data Added
// Additional Comments: GNU 3 license, MUST DEFINE _SIMULATION 
// 
//////////////////////////////////////////////////////////////////////////////////
`include "timescale.vh"
`include "TRI_MODE_MAC_SIM_DEF.vh"
`include "TRI_MODE_MAC_SIM_CLASSES.vh"

`ifdef _SIMULATION
/* RANDOM NUMBER GENERATION */

module TRI_MODE_MAC_STIMULUS(
    /* OUTPUT FROM MAC */ 
    output reg        mac_clk_o, 
    output reg        mac_rst_o,
    output reg [31:0] mac_rxd_o,
    output reg [1:0]  mac_ben_o,
    output reg        mac_rxda_o,                            
    output reg        mac_rxsop_o,                           
    output reg        mac_rxeop_o,                           
    output reg        mac_rxdv_o,                            
    /* INPUT TO MAC */ 
    input  wire mac_rxrqrd_i                    
    );
    /* Status varibel to keep track of errors and notifications */
    int status;
    /* TRI mode PHY Class */ 
    tri_mode_phy_stim_state tri_mode_state;
    /* Parameters */
    parameter int mem_entries = 32768;
    parameter int packet_size = 20000;
    /* Memory Array that holds MAC stimilus output: Use to compare to expected memory contents */ 
    reg [31:0] mem_array [mem_entries - 1:0];
    /* Inital Statments */
    initial begin
        tri_mode_state = new();
        mac_clk_o   = `_false;       
        mac_rst_o   = `_false;       
        mac_rxd_o   = `_false;
        mac_ben_o   = `_false;       
        mac_rxda_o  = `_false;      
        mac_rxsop_o = `_false;     
        mac_rxeop_o = `_false;     
        mac_rxdv_o  = `_false;
        tsk_mem_ld();
        tsk_rst();
        /* Class: Get packet size */
        tri_mode_state.cur_state.packet_size = packet_size;
        /* Set the halt value for the data valid buffer */
        status = tri_mode_state.set_halt_value($random); 
        /* Set ready begins the transfer */
        status = tri_mode_state.set_ready();
    end 
    /* Update Class */
    always @ (posedge mac_clk_o) begin
        status = tri_mode_state.mac_rxd_update;
        $display("Read value %d at adderess %d", mem_array[tri_mode_state.cur_state.memory_address],tri_mode_state.cur_state.memory_address);
    end

    /* RXD output */
    always @ (posedge mac_clk_o) begin
        if(tri_mode_state.cur_state.data_avalible == 1) 
            force mac_rxrqrd_i = 1'b1;
        tri_mode_state.read_data = mac_rxrqrd_i;
        mac_rxda_o = tri_mode_state.cur_state.data_avalible; 
        mac_rxdv_o = tri_mode_state.cur_state.data_valid;
        mac_rxd_o  = mem_array[tri_mode_state.cur_state.memory_address];
    end
    
    /* Clock Generation */
    always begin
        #5 mac_clk_o = !mac_clk_o;
    end
    /******* TASKS GO HERE *******/
    /* RESET TASK */
     task tsk_rst;
         `_RST_DLY mac_rst_o = !mac_rst_o;
         `_RST_HLD mac_rst_o = !mac_rst_o;
         status = tri_mode_state.reset; 
     endtask
     /* MEMORY LOAD WITH RANDOM DATA */
     task tsk_mem_ld;
         for(int i = 0; i < mem_entries; i++) begin
             mem_array[i] = $random;
         end
         `ifdef `_dbg_verbose
             foreach (mem_array[i]) begin
                 $write(" %h", mem_array[i]);
                 $display;
             end
         `endif 
     endtask
endmodule
`endif 
