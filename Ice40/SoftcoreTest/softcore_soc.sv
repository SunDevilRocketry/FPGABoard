// PicoRV32 SoC. Memory map (region = mem_addr[31:28]):
// 0x0000_0000 - 0x0000_03FF  EBR, 1 KB (CPU starts here)
// 0x1000_0000 - 0x1001_FFFF  SPRAM, 128 KB (not connected yet)
// 0x2000_0000 - 0x203F_FFFF  SPI flash, 4 MB (not connected yet)
// 0x3000_0000 - 0x3000_FFFF  I/O, 64 KB (LEDs at 0x3000_0000, write only)
module softcore_soc (
    input wire clk, 
    output reg [2:0] leds = 3'b000
);
    // Hold CPU in reset for 255 cycles after power-up
    reg [7:0] rst_cnt = 0;
    wire resetn = &rst_cnt;
    always @(posedge clk) begin
        if (!resetn)
            rst_cnt <= rst_cnt + 1;
    end

    // One bus for both instruction fetches and data. Choosen: RV32IC 
    wire        mem_valid, mem_instr, trap;
    reg         mem_ready;
    wire [31:0] mem_addr, mem_wdata;
    wire [3:0]  mem_wstrb;
    reg  [31:0] mem_rdata;

    picorv32 #(
        .ENABLE_COUNTERS        (0),
        .ENABLE_COUNTERS64      (0),
        .ENABLE_REGS_16_31      (1),   // Set 0 for RV32E (would mean C compiles w/ '-mabi=ilp32e')
        .ENABLE_REGS_DUALPORT   (1),
        .BARREL_SHIFTER         (0),
        .TWO_STAGE_SHIFT        (1),
        .TWO_CYCLE_COMPARE      (0),
        .TWO_CYCLE_ALU          (0),
        .CATCH_MISALIGN         (1),
        .CATCH_ILLINSN          (1),
        .COMPRESSED_ISA         (1),
        .ENABLE_MUL             (0),
        .ENABLE_DIV             (0),
        .ENABLE_IRQ             (0),
        .ENABLE_PCPI            (0),
        .ENABLE_TRACE           (0),
        .LATCHED_MEM_RDATA      (0),
        .PROGADDR_RESET         (32'h0000_0000)
    ) cpu (
        .clk(clk), .resetn(resetn),
        .mem_valid(mem_valid), .mem_instr(mem_instr), .trap(trap),
        .mem_ready(mem_ready),
        .mem_addr(mem_addr), .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb), .mem_rdata(mem_rdata),
        .mem_la_read(), .mem_la_write(), .mem_la_addr(), .mem_la_wdata(), .mem_la_wstrb(),
        .pcpi_valid(), .pcpi_insn(), .pcpi_rs1(), .pcpi_rs2(),
        .pcpi_wr(1'b0), .pcpi_wait(1'b0), .pcpi_ready(1'b0),
        .pcpi_rd(32'h0000_0000),
        .irq(32'h0000_0000),
        .eoi(),
        .trace_valid(), .trace_data()
    );

    // EBR, preloaded with Firmware/firmware.hex
    reg [31:0] mem [0:255];
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) 
            mem[i] = 32'h0;
        $readmemh("Firmware/firmware.hex", mem);
    end

    // Address Decode (Top 4 bits pick the region). mem_ready one clock after mem_valid
    always @(posedge clk) begin
        mem_ready <= 0;
        if (mem_valid && !mem_ready) begin
            mem_ready <= 1;
            case(mem_addr[31:28])
                4'h0: begin
                    // EBR. Only bits 9:2 used, so the 1 KB repeats through the region
                    mem_rdata <= mem[mem_addr[9:2]];
                    if (mem_wstrb[0]) mem[mem_addr[9:2]][ 7: 0] <= mem_wdata[ 7: 0];    // one strobe per byte
                    if (mem_wstrb[1]) mem[mem_addr[9:2]][15: 8] <= mem_wdata[15: 8]; 
                    if (mem_wstrb[2]) mem[mem_addr[9:2]][23:16] <= mem_wdata[23:16];  
                    if (mem_wstrb[3]) mem[mem_addr[9:2]][31:24] <= mem_wdata[31:24];
                end

                4'h1: begin
                    // SPRAM goes here
                    mem_rdata <= 32'h0000_0000;
                end

                4'h2: begin
                    // Flash (spimemio) goes here
                    mem_rdata <= 32'h0000_0000;
                end

                4'h3: begin
                    // I/O. LEDs take bits 22:20 so changes are slow per scale w/ counter
                    mem_rdata <= 32'h0000_0000;
                    if (|mem_wstrb) leds <= mem_wdata[22:20];
                end

                default: begin
                    // Unmapped.
                    mem_rdata <= 32'h0000_0000;
                end
            endcase
        end
        if (!resetn) mem_ready <= 0;
    end

endmodule