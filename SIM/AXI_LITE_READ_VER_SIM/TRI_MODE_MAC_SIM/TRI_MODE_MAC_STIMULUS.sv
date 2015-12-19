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

`ifdef _SIMULATION
/* RANDOM NUMBER GENERATION */
class random_range_seed;
    typedef struct packed{
        int low,high;
    } low_high;
    int seed = 42;
    low_high range = {0,10};
    function int rand_range_gen;
        int out;
        out = range.low + {$random(seed)} % (range.high - range.low);
        return out; 
    endfunction
endclass

class tri_mode_phy_stim_state;
    /* MAC Varibles */
    typedef struct packed{
        int packet_size;
        int memory_address;
        int packet_halted;
        int data_valid;
        int start_of_packet;
        int end_of_packet;
    } tri_mode_vars;
    tri_mode_vars cur_state = {0,0,0,0,0,0}; 
    /* LOCAL VARS */
    local int current_packet_count;
    local int packet_halt_count; 
    /* Determine the packet halt value */
    function int set_halt_value (int seed);
        random_range_seed random_val = new();
        random_val.range = {0, cur_state.packet_size};
        random_val.seed = seed;
        packet_halt_count = random_val.rand_range_gen();
        $display("Cycles in packet to halt = %d \n", packet_halt_count);
        return (0);
    endfunction
    /* Transfer a packet by moving the address counter up 1 */
    function int rxd_transfer;
        current_packet_count = current_packet_count + 1;
        cur_state.memory_address = cur_state.memory_address + 1;
        if (current_packet_count == packet_halt_count) begin
            cur_state.packet_halted = 1;
            cur_state.data_valid = 0; 
        end 
        return 0;
    endfunction 
    /* Set the MAC data out as ready */
    function int set_ready;
        cur_state.data_valid = 1;
        return cur_state.data_valid;
    endfunction
    /* Reset the MAC state */
    function int reset;
        cur_state.memory_address = 0;
        cur_state.packet_halted = 0;
        cur_state.data_valid = 0;
        cur_state.start_of_packet = 0;
        cur_state.end_of_packet = 0;
        current_packet_count = 0;
        return 0;
    endfunction
endclass 

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
    input         wire mac_rxrqrd_i                    
    );
    int status;
    tri_mode_phy_stim_state tri_mode_state;
    //Parameters
    parameter int mem_entries = 32768;
    parameter int packet_size = 20000;
    
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
        tri_mode_state.cur_state.packet_size = packet_size;
        status = tri_mode_state.set_halt_value($random); 
        status = tri_mode_state.set_ready();
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
        foreach (mem_array[i]) begin
            $write(" %h", mem_array[i]);
            $display;
        end
    endtask
    
    always @ (posedge mac_clk_o) begin
        if (tri_mode_state.cur_state.data_valid == 1) begin
            status = tri_mode_state.rxd_transfer;
            $display("%d at adderess %d", mem_array[tri_mode_state.cur_state.memory_address],tri_mode_state.cur_state.memory_address);
        end
    end
    /* RXD output */
    always @ (posedge mac_clk_o) begin
        mac_rxd_o <= mem_array[tri_mode_state.cur_state.memory_address];
    end
    
    /* Clock Generation */
    always begin
        #5 mac_clk_o = !mac_clk_o;
    end
 //   status = tri_mode_state.set_halt_value(42);
endmodule
`endif 
