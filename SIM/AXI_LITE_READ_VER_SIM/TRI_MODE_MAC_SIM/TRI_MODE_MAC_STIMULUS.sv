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
    /* Parameters */
    parameter int mem_entries = 32768;
    parameter int packet_size = 20000;
    parameter int halt_count  = 10000;
    parameter int halt_length = 10000;
    /* Memory Array that holds MAC stimilus output: Use to compare to expected memory contents */ 
    reg [31:0] mem_array [mem_entries - 1:0];
    /* Inital Statments */
    initial begin
        mac_clk_o   = `_false;        
        mac_rst_o   = `_false;       
        mac_rxd_o   = `_false;
        mac_ben_o   = 2'b11;       
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
    reg [31:0] read_valid_delay_counter;
    reg [31:0] read_halt_counter;
    reg sop_set; 
    /* Reade Meale state machine */ 
    always @ (posedge mac_clk_o) begin
        if (mac_rst_o)
            state <= IDLE;
        else begin
            state <= nxt_state;
            case(state)
                IDLE: begin
                    mac_rxda_o <= `_true;
                    nxt_state  <= READ_AVALIBLE;
                end
                READ_AVALIBLE: begin
                    force mac_rxrqrd_i = 1;
                    if(mac_rxrqrd_i) begin
                        nxt_state                <= READING;
                        read_valid_delay_counter <= 1;
                        read_halt_counter        <= 1;   
                        address                  <= 0;
                        sop_set                  <= 0;
                        mac_rxeop_o              <= 0;
                        mac_rxdv_o               <= 0;
                    end
                    else begin
                        read_valid_delay_counter<= 0;
                    end
                end
                READING: begin
                    read_halt_counter <= read_halt_counter + 1;
                    address <= address + 1;
                    if (read_valid_delay_counter < 4) begin
                        read_valid_delay_counter <= read_valid_delay_counter + 1;
                    end
                    if (read_valid_delay_counter == 4) begin
                        address <= address + 1'b1;
                        if (sop_set == 0) begin
                            mac_rxsop_o <= 1;
                            sop_set <= 1'b1;
                            mac_rxdv_o <= 1;
                        end
                        else
                            mac_rxsop_o <= 0;
                    end
                    if (read_halt_counter == halt_count) begin
                        nxt_state <= HALT;
                    end
                    if (address == (packet_size - 1)) begin
                        mac_rxeop_o <=1;
                    end
                    if (address == packet_size) begin
                        mac_rxeop_o <= 0;
                        nxt_state <= IDLE; 
                    end
                end 
                HALT: begin
                    read_halt_counter <= read_halt_counter + 1;
                    if (read_halt_counter == halt_count  + 4) begin
                        mac_rxda_o <= `_false;
                        mac_rxdv_o <= 0;
                    end 
                    if (read_halt_counter == (halt_count  + 4 + halt_length)) begin
                        mac_rxda_o <= `_true;
                        mac_rxdv_o <= 1;
                        read_valid_delay_counter <= 0;
                        nxt_state <= READING;
                    end
                end
            endcase  
        end
    end
    /* Clock Generation */
    always begin
        #5 mac_clk_o = !mac_clk_o;
    end
    
    always @ (posedge mac_clk_o) begin
        mac_rxd_o <= mem_array[address];
    end 
    /* RESET TASK */
    task tsk_rst;
         `_RST_DLY mac_rst_o = !mac_rst_o;
         `_RST_HLD mac_rst_o = !mac_rst_o;
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
