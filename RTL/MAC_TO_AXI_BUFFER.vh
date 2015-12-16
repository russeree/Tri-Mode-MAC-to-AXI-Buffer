/* AUTHOR: Reese Russell
 * LICENSE: GNU 3
 * UDP PARSER HEADER FILE
 */
 `ifndef _UDP_PARSER_DEFINES
 `define _UDP_PARSER_DEFINES
    // architecture to syn 
    `define _ARCH_XIL 1
    // EDA USED 
    `define _EDA_XIL_WIN
    // Define build paths for indiviual EDA enviorments
    `define _MEMORY_CONTENTS_BIN
    // Define Simulation
    `define _SIMULATION
    // Memory contents processing
    `ifdef _EDA_XIL_WIN
        `define _MEMORY_CONTENTS_BIN "C:\\Users\\Reese\\udp_packet_parser_module\\udp_packet_parser_module.srcs\\sources_1\\new\\udp_sim_mem.mem"
    `endif
    `ifdef _EDA_XIL_LIN
        `define _MEMORY_CONTENTS_BIN ./
    `endif
`endif 