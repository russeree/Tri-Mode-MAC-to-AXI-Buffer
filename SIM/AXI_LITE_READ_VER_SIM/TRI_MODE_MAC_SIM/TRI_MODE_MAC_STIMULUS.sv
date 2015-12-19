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
    parameter int halt_count  = 10000;
    parameter int halt_length = 55;
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
    end 
    /* Reading State Machine */
    enum logic [2:0] {IDLE, READ_AVALIBLE, READING, HALT}
        state, nxt_state;
    reg [31:0] address;
    reg [31:0] read_valid_delay_coutner;
    reg [31:0] read_halt_counter;
    /* Reade Meale state machine */ 
    always_ff @ (posedge mac_clk_o) begin
        if (mac_rst_o)
            state <= IDLE;
        else begin
            state <= nxt_state;
            case(state)
                IDLE: begin
                    mac_rxda_o <= `_true;
                    nxt_state <= READ_AVALIBLE;
                end
                READ_AVALIBLE: begin
                    if(mac_rxrqrd_i) begin
                        nxt_state <= READING;
                        read_valid_delay_counter <= 1;
                        read_halt_counter <= 1;    
                    end
                    else begin
                        read_valid_delay_counter <= 0;
                    end
                end
            endcase  
        end
    end
    /* Clock Generation */
    always begin
        #5 mac_clk_o = !mac_clk_o;
    end
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
         `ifdef `_DBG_VERBOSE
             foreach (mem_array[i]) begin
                 $write(" %h", mem_array[i]);
                 $display;
             end
         `endif 
     endtask
endmodule
`endif 
