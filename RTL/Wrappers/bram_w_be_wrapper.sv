//////////////////////////////////////////////////////////////////////////////////
// Company: rFPGA
// Engineer: Reese Russell
// 
// Create Date: 12/20/2015 08:18:10 AM
// Design Name: Bram with byte wide write enable wrapper
// Module Name: bram_w_be_wrapper
// Project Name: rFPGA EtherIP
// Target Devices: Kintex 7 325t
// Tool Versions: Vivado 2015.4
// Description: This is a Xilinx "Infrenced" block ram, I have made a parameterized
// wrapper to ease integration. Becuase having blocks of code this large placed in
// middle of a module is very unsightly.
// 
// Dependencies: Xilinx support tested only.  
// 
// Revision: 0.01
// Revision 0.01 - File Created
// Additional Comments: GNU 3
// 
//////////////////////////////////////////////////////////////////////////////////
`include "timescale.vh"

module bram_w_be_wrapper(addra_i, addrb_i, dina_i, dinb_i, clka_i, clkb_i, wea_i, web_i, 
    ena_i, enb_i, rsta_i, rstb_i, regcea_i, regceb_i, douta_o, doutb_o);   
   
    parameter NB_COL = 4;                              // Specify number of columns (number of bytes)
    parameter COL_WIDTH = 8;                           // Specify column width (byte width, typically 8 or 9)
    parameter RAM_DEPTH = 1600;                        // Specify RAM depth (number of entries)
    parameter RAM_PERFORMANCE = "HIGH_PERFORMANCE";    // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    parameter INIT_FILE = "";                          // Specify name/location of RAM initialization file if using one (leave blank if not)
    
    input  wire [clogb2(RAM_DEPTH-1)-1:0] addra_i;     // Port A address bus, width determined from RAM_DEPTH
    input  wire [clogb2(RAM_DEPTH-1)-1:0] addrb_i;     // Port B address bus, width determined from RAM_DEPTH
    input  wire [(NB_COL*COL_WIDTH)-1:0] dina_i;       // Port A RAM input data
    input  wire [(NB_COL*COL_WIDTH)-1:0] dinb_i;       // Port B RAM input data
    input  wire clka_i;                                // Port A clock
    input  wire clkb_i;                                // Port B clock
    input  wire [NB_COL-1:0] wea_i;                    // Port A write enable
    input  wire [NB_COL-1:0] web_i;		               // Port B write enable
    input  wire ena_i;                                 // Port A RAM Enable, for additional power savings, disable BRAM when not in use
    input  wire enb_i;                                 // Port B RAM Enable, for additional power savings, disable BRAM when not in use
    input  wire rsta_i;                                // Port A output reset (does not affect memory contents)
    input  wire rstb_i;                                // Port B output reset (does not affect memory contents)
    input  wire regcea_i;                              // Port A output register enable
    input  wire regceb_i;                              // Port B output register enable
    output wire [(NB_COL*COL_WIDTH)-1:0] douta_o;      // Port A RAM output data
    output wire [(NB_COL*COL_WIDTH)-1:0] doutb_o;      // Port B RAM output data
    
    reg [(NB_COL*COL_WIDTH)-1:0] bram_int[RAM_DEPTH-1:0];
    reg [(NB_COL*COL_WIDTH)-1:0] bram_data_int = {(NB_COL*COL_WIDTH){1'b0}};
    reg [(NB_COL*COL_WIDTH)-1:0] bram_datb_int = {(NB_COL*COL_WIDTH){1'b0}};

    // The following code either initializes the memory values to a specified file or to all zeros to match hardware
    generate
        if (INIT_FILE != "") begin: use_init_file
          initial
            $readmemh(INIT_FILE, bram_int, 0, RAM_DEPTH-1);
        end else begin: init_bram_to_zero
            integer ram_index;
            initial
            for (ram_index = 0; ram_index < RAM_DEPTH; ram_index = ram_index + 1)
                bram_int[ram_index] = {(NB_COL*COL_WIDTH){1'b0}};
        end
    endgenerate

    generate
    genvar i;
        for (i = 0; i < NB_COL; i = i+1) begin: byte_write
        always @(posedge clka_i)
            if (ena_i)
            if (wea_i[i]) begin
                bram_int[addra_i][(i+1)*COL_WIDTH-1:i*COL_WIDTH] <= dina_i[(i+1)*COL_WIDTH-1:i*COL_WIDTH];
                bram_data_int[(i+1)*COL_WIDTH-1:i*COL_WIDTH] <= dina_i[(i+1)*COL_WIDTH-1:i*COL_WIDTH];
            end else begin
                bram_data_int[(i+1)*COL_WIDTH-1:i*COL_WIDTH] <= bram_int[addra_i][(i+1)*COL_WIDTH-1:i*COL_WIDTH];
            end

        always @(posedge clkb_i)
            if (enb_i)
            if (web_i[i]) begin
                bram_int [addrb_i][(i+1)*COL_WIDTH-1:i*COL_WIDTH] <= dinb_i[(i+1)*COL_WIDTH-1:i*COL_WIDTH];
                bram_datb_int[(i+1)*COL_WIDTH-1:i*COL_WIDTH] <= dinb_i[(i+1)*COL_WIDTH-1:i*COL_WIDTH];
            end else begin
                bram_datb_int [(i+1)*COL_WIDTH-1:i*COL_WIDTH] <= bram_int[addrb_i][(i+1)*COL_WIDTH-1:i*COL_WIDTH];
             end
        end
    endgenerate

    //  The following code generates HIGH_PERFORMANCE (use output register) or LOW_LATENCY (no output register)
    generate
        if (RAM_PERFORMANCE == "LOW_LATENCY") begin: no_output_register

        // The following is a 1 clock cycle read latency at the cost of a longer clock-to-out timing
            assign douta_o = bram_data_int;
            assign doutb_o = bram_datb_int;

        end else begin: output_register

        // The following is a 2 clock cycle read latency with improve clock-to-out timing

            reg [(NB_COL*COL_WIDTH)-1:0] douta_reg = {(NB_COL*COL_WIDTH){1'b0}};
            reg [(NB_COL*COL_WIDTH)-1:0] doutb_reg = {(NB_COL*COL_WIDTH){1'b0}};

        always @(posedge clka_i)
            if (rsta_i)
                douta_reg <= {(NB_COL*COL_WIDTH){1'b0}};
            else if (regcea_i)
                douta_reg <= bram_data_int;

         always @(posedge clkb_i)
            if (rstb_i)
                doutb_reg <= {(NB_COL*COL_WIDTH){1'b0}};
            else if (regceb_i)
                doutb_reg <= bram_datb_int;

            assign douta_o = douta_reg;
            assign doutb_o = doutb_reg;

        end
    endgenerate

    //  The following function calculates the address width based on specified RAM depth
    function integer clogb2;
        input integer depth;
        for (clogb2=0; depth>0; clogb2=clogb2+1)
         depth = depth >> 1;
    endfunction

endmodule
