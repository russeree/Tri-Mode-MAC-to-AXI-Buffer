//////////////////////////////////////////////////////////////////////////////////
// Company: rFPGA 
// Engineer: Reese Russell
// 
// Create Date: 12/03/2015 11:12:41 PM
// Design Name: AXI Minimal UDP Parser
// Module Name: UDP_PACKET_PARSER
// Project Name: rFPGA Stereo Vision
// Target Devices: Kintex 7
//                 Virtex 7
// Tool Versions: Vivado 2015.4
// Description: This is designed to be a minimal AXI UDP parser designed to get packet
// data into "memory" for processing, in the process the header is removed from the
// data. There is also a 32 bit packet counter for tracking packets received.
// 
// Dependencies: None: Low level module, desined to interface tri-mode MAC
// from opencores 'http://opencores.com/project,ethernet_tri_mode' src can
// be found in sources tri_mode_mac_88e1111. 
// 
// NOT INTENDED FOR NON XILINX PRODUCTS WITHOUT PRIMITAVE MODIFICATION
// 
// Revision 0.01 - File Created
// Additional Comments: GNU 3.0 Licence, lines 4-7 and 20 may not be modified
// line 3 may be appended to. Line count begins at 1. rCG ver 1.1 utilized.
// 
//////////////////////////////////////////////////////////////////////////////////

`include "timescale.vh"
`include "MAC_TO_AXI_BUFFER.vh"  

module MAC_TO_AXI_BUFFER (mac_clk_i, mac_rst_i, mac_rxd_i, mac_ben_i, mac_rxda_i, mac_rxsop_i, mac_rxeop_i, mac_rxdv_i, mac_rxrqrd_i,
    ACLK,ARESETN,S_AXI_ARADDR,S_AXI_ARVALID,S_AXI_ARREADY,S_AXI_RDATA,S_AXI_RRESP, S_AXI_RVALID, S_AXI_RREADY);
    /* Parameters: MAC INTERFACE and FIFO CONFIG */
    parameter integer _dat_w_mac                  = 32;                  // MAC BITS RX Data output width
    parameter integer _ben_w_mac                  = 2;                   // MAC BITS RX Data output byte enable width; 
    parameter integer _addr_w_mem                 = 14;                  // XIL BITS FIFO MACRO ENTRIES SIZE
    parameter integer _dat_w_mem                  = 32;                  // XIL BITS FIFO MACRO WORD SIZE
    parameter integer C_S_AXI_ADDR_WIDTH          = 32;
    parameter integer C_S_AXI_DATA_WIDTH          = 32;
    /* INPUT FROM MAC */
    input mac_rst_i;
    input mac_clk_i;                              // FAB -O MAC -> MEMORY INTERFACE CLOCK
    input [_dat_w_mac-1:0] mac_rxd_i;             // MAC -O RX DATA
    input [_ben_w_mac-1:0] mac_ben_i;             // MAC -O RX DATA BYTE ENABLE
    input mac_rxda_i;                             // MAC -O READ AVALIBLE
    input mac_rxsop_i;                            // MAC -O READ START OF PACKET
    input mac_rxeop_i;                            // MAC -O READ END OF PACKET 
    input mac_rxdv_i;                             // MAC -O READ DATA VALID
    /* OUTPUT TO MAC */ 
    output reg mac_rxrqrd_i;                      // MAC -I READ REQUEST
    /* AXI4 LITE SIGNALS, INPUTS, OUTPUTS */
    /* AXI4 LTIE System Signals */ 
    input wire ACLK;
    input wire ARESETN;
    /* Read Channels */
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]   S_AXI_ARADDR;
    input  wire                            S_AXI_ARVALID;
    output reg                             S_AXI_ARREADY;
    /* Slave Interface Read Data Ports */
    output reg [C_S_AXI_DATA_WIDTH-1:0]    S_AXI_RDATA;
    output reg [2-1:0]                     S_AXI_RRESP;
    output reg                             S_AXI_RVALID;
    input  wire                            S_AXI_RREADY;
    /* INTERNAL REGISTERS */
    reg [_addr_w_mem:1] pkt_wr_addr_int;
    reg [_addr_w_mem:1] pkt_rd_addr_int; 
    reg [_dat_w_mac:0]  mac_rxd_buf_int;
    reg [_dat_w_mem:0]  pkt_rd_dout_int;
    reg [31:0]          pkt_count_int;
    reg                 pkt_wr_int;
    reg [1:0]           pkt_start_det;
    reg                 pip_int; /* Packet in Progress */
    /* Byte enable input mask */
    wire [_dat_w_mac-1:0] mac_d_mask_int;
    generate
        if ((_dat_w_mac == 32) && (_ben_w_mac == 2)) begin
            assign mac_d_mask_int = 
                (mac_ben_i == 2'b00) ? {{24{1'b0}},{8{1'b1}}} :
                (mac_ben_i == 2'b01) ? {{16{1'b0}},{{16'b1}}} :
                (mac_ben_i == 2'b10) ? {{8{1'b0}},{{24'b1}}} :
                (mac_ben_i == 2'b11) ? {32{1'b1}} : 32'b0; 
        end
        else begin
            $error("Not a supported config: please add an ertry"); 
        end 
    endgenerate
    /* UDP SINGLE PACKET BUFFER, INFERED BLOCK RAM MEMORIES */  
`ifdef _ARCH_XIL (* ram_style="block" *) `endif
    reg [_dat_w_mem-1:0] packet_buffer_mem [(2**_addr_w_mem)-1:0];
    /* Write the contents of _MEMORY_CONTENTS_BIN to the memory interface for AXI SIMULTATION
     * The file location is defined in the verilog header file 
     */ 
`ifdef _SIMULATION
    integer r, file;
    integer mem_size = (2**_addr_w_mem);
    initial begin
        file = $fopen(`_MEMORY_CONTENTS_BIN,"rb");
        r    = $fread(packet_buffer_mem, file, 0, mem_size);
        $write("$fread read %0d  bytes: ", r);
        foreach (packet_buffer_mem[i])
            $write(" %h", packet_buffer_mem[i]);
            $display;
        end 
`endif
    /* MAC -> MEMORY INTERFACE */
    /* Packet to memory mealy state machine
     * This will gaurentee 1 whole packet will be received from the MAC 
     */
    enum logic [0:0] {s_idle    = 1'b0,
                      s_wr      = 1'b1} mem_state_int;
    always @ (posedge mac_clk_i) begin
        if (mac_rst_i) begin
            mem_state_int   <= s_idle;
            pip_int         <= 1'b0;
            mac_rxrqrd_i    <= 1'b0;
            pkt_wr_addr_int <= 1'b0;
            pkt_count_int   <= 1'b0;
        end 
        else
            case(mem_state_int)
                s_idle: begin
                    if(mac_rxda_i) begin
                        mem_state_int   <= s_wr;
                        mac_rxrqrd_i    <= 1'b1;
                        pkt_wr_addr_int <= 1'b0; 
                    end 
                end
                s_wr: begin
                    casex({mac_rxda_i, mac_rxsop_i, mac_rxeop_i})
                        3'b000: begin
                            mac_rxrqrd_i  <= 1'b0;
                        end 
                        3'b010: begin
                            mac_rxrqrd_i  <= 1'b0;
                            pip_int       <= 1'b1;
                            pkt_count_int <= pkt_count_int <= 1'b1;
                        end 
                        3'b0x1: begin
                            mac_rxrqrd_i  <= 1'b0;
                            pip_int       <= 1'b0;
                            mem_state_int <= s_idle;
                        end 
                        3'b100: begin
                            mac_rxrqrd_i  <= 1'b1;
                        end 
                        3'b110: begin
                            mac_rxrqrd_i  <= 1'b1;
                            pip_int       <= 1'b1;
                            pkt_count_int <= pkt_count_int <= 1'b1;
                        end
                        3'b1x1: begin
                            mac_rxrqrd_i  <= 1'b1;
                            pip_int       <= 1'b0;
                            mem_state_int <= s_idle;
                        end
                        default:
                            /* CASE STUB */
                            pip_int       <= pip_int;
                    endcase 
                    if(mac_rxdv_i) begin
                        pkt_wr_addr_int <= pkt_wr_addr_int + 1'b1; 
                        packet_buffer_mem[pkt_wr_addr_int] <= (mac_rxd_i & mac_d_mask_int);
                    end
                end
            endcase
    end      
    /* MEMORY TO AXI4 LITE READ Lite Interface */
    enum logic [0:0] {axi_addr = 1'b0,
                      axi_rd   = 1'b1} axi_rd_state_int;               
    always @ (posedge ACLK) begin
        if(!ARESETN) begin
            axi_rd_state_int <= axi_addr;
            S_AXI_ARREADY    <= 1'b0;
            S_AXI_RDATA      <= 1'b0;
            S_AXI_RRESP      <= 1'b0;
            S_AXI_RVALID     <= 1'b0;
        end
        else begin
            case(axi_rd_state_int)
                axi_addr: begin
                    if(S_AXI_ARVALID) begin
                        S_AXI_ARREADY    <= 1'b1;
                        S_AXI_RVALID     <= 1'b1;
                        axi_rd_state_int <= axi_rd;
                    end
                    if(S_AXI_ARADDR > {_addr_w_mem{1'b1}}) begin
                        S_AXI_RDATA <= 1'b0;
                        S_AXI_RRESP <= 2'b10;
                    end
                    if(S_AXI_ARADDR <= {_addr_w_mem{1'b1}}) begin
                        S_AXI_RDATA <= packet_buffer_mem[S_AXI_ARADDR];
                        S_AXI_RRESP <= 2'b00; 
                    end
                end
                axi_rd: begin
                    S_AXI_ARREADY        <= 1'b0;
                    if(S_AXI_RREADY) begin
                        S_AXI_RVALID     <= 1'b0;
                        axi_rd_state_int <= axi_addr; 
                    end
                end 
            endcase 
        end 
    end
/* END OF MODULE */ 
endmodule