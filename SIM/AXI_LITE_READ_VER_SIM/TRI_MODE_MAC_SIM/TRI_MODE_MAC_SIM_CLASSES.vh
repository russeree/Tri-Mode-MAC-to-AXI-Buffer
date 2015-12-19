/** 
 * Creator: Reese Russell
 * Date: 12/19/2015
 * Classes Include File
 */
  
 /**
  * Class Random int generator with seed and range 
  */
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

/**
 * Tri_mode_phy_stimilus_state_machine_class 
 */
class tri_mode_phy_stim_state;
    /* MAC Varibles */
    typedef struct packed{
        int packet_size;               // SIZE OF PACKET 
        int memory_address;            // CURRENT MEMORY ADDRESS OUTPUT
        int packet_halted;             // IS THE PACKET IN A HALT STATE
        int data_avalible;             // IS DATA AVALIBLE TO BE READ
        int data_valid;                // IS THE DATA READ VALID
        int start_of_packet;           // IS IT THE START OF THE PACKET
        int end_of_packet;             // IS IT THE END OF THE PACKET
    } tri_mode_vars;
    tri_mode_vars cur_state = {0,0,0,0,0,0,0};
    tri_mode_vars nxt_state;
    int read_data; 
    /* LOCAL VARS */
    local int status;                   // CLASS STATUS
    local int data_valid_state;         // THIS INTEGER TRACKS THE STATE OF THE DATA VLID FOR TOGGLE DELAYS 
    local int current_packet_count;     // CURRENT NUMBER VALUE OF RXD_ADDRESS
    local int packet_halt_count;        // HALT DURATION COUNTER
    local int data_valid_count = 0;     // COUNTS UPWARD TO SIMULATE DATA VALID DELAY
    local int data_not_avalible_count;  // COUNTS UPWARD TO SIMULATE DATA NOT VALID DELAY
    /* Add function new here please */
    /* Run this per clock cycle to update the class state */ 
    function int mac_rxd_update;
        if(nxt_state.data_avalible == 1) begin
            if(read_data == 1) begin
                data_valid_count = data_valid_count + 1; 
                if(data_valid_count == 4) begin
                    cur_state.data_valid = 1;
                    data_valid_state = 1;
                end
            end
        end
        if(nxt_state.data_valid == 1)
            status = rxd_transfer;
        nxt_state = cur_state;
    endfunction  
    /* VERIFIED: Determine the packet halt value */
    function int set_halt_value (int seed);
        random_range_seed random_val = new();
        random_val.range = {0, cur_state.packet_size};
        random_val.seed = seed;
        packet_halt_count = random_val.rand_range_gen();
        $display("Cycles in packet to halt = %d", packet_halt_count);
        return (0);
    endfunction
    /* Transfer a packet by moving the address counter up 1 */
    function int rxd_transfer;
        if (current_packet_count != packet_halt_count) begin
            current_packet_count = current_packet_count + 1;
        end
        cur_state.memory_address = cur_state.memory_address + 1;
        if (current_packet_count == packet_halt_count) begin
            cur_state.packet_halted = 1;
            cur_state.data_valid = 0; 
        end 
        return 0;
    endfunction
    /* VERIFIED: Set the MAC data out as ready */
    function int set_ready;
        cur_state.data_avalible = 1;
        $display("@ %0dns DATA NOW AVALIBLE", $time);
        return 0;
    endfunction
    /* VERIFIED: Reset the MAC state */
    function int reset;
        cur_state.memory_address = 0;
        cur_state.packet_halted = 0;
        cur_state.data_avalible = 0;
        cur_state.data_valid = 0;
        cur_state.start_of_packet = 0;
        cur_state.end_of_packet = 0;
        read_data = 0;
        current_packet_count = 0;
        $display("@ %0dns, RESET SUCCESSFULL", $time);
        return 0;
    endfunction
endclass 