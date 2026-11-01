// PicoRV32 SoC. Memory map (region = mem_addr[31:28]):
// 0x0000_0000 - 0x0000_03FF  EBR, 1 KB (CPU starts here)
// 0x1000_0000 - 0x1001_FFFF  SPRAM, 128 KB
// 0x2000_0000 - 0x203F_FFFF  SPI flash, 4 MB (not connected yet)
// 0x3000_0000 - 0x3000_FFFF  I/O, 64 KB (LEDs at 0x3000_0000, write only)
module softcore_soc (
    input wire clk, spi_miso,
    output wire spi_sck, spi_ssn, spi_mosi,
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
    wire        mem_valid, mem_instr, trap, spram_sel, spram_sel0, spram_sel1;
    wire        flash_valid, flash_ready;
    wire [3:0]  mem_wstrb;
    wire [31:0] mem_addr, mem_wdata, mem_rdata, spram_rdata, spram0_rdata, spram1_rdata;
    wire [31:0] flash_rdata;
    reg         mem_ready;
    reg  [31:0] bus_rdata;

    assign spram_rdata = (mem_addr[16] == 1'b1) ? spram1_rdata : spram0_rdata;
    assign spram_sel = (mem_valid && !mem_ready && mem_addr[31:28] == 4'h1);
    assign spram_sel0 = (spram_sel && mem_addr[16] == 1'b0);
    assign spram_sel1 = (spram_sel && mem_addr[16] == 1'b1);

    assign mem_rdata = (mem_addr[31:28] == 4'h1) ? spram_rdata : bus_rdata;

    assign flash_valid = (mem_addr[31:28] == 4'h2 && mem_valid);

    SB_SPRAM256KA spram0_lo (
        .ADDRESS(mem_addr[15:2]),
        .DATAIN(mem_wdata[15:0]),
        .MASKWREN({mem_wstrb[1], mem_wstrb[1], mem_wstrb[0], mem_wstrb[0]}),
        .WREN(|mem_wstrb),
        .CHIPSELECT(spram_sel0),
        .CLOCK(clk),
        .STANDBY(1'b0),
        .SLEEP(1'b0),
        .POWEROFF(1'b1),
        .DATAOUT(spram0_rdata[15:0])
    );

    SB_SPRAM256KA spram0_hi (
        .ADDRESS(mem_addr[15:2]),
        .DATAIN(mem_wdata[31:16]),
        .MASKWREN({mem_wstrb[3], mem_wstrb[3], mem_wstrb[2], mem_wstrb[2]}),
        .WREN(|mem_wstrb),
        .CHIPSELECT(spram_sel0),
        .CLOCK(clk),
        .STANDBY(1'b0),
        .SLEEP(1'b0),
        .POWEROFF(1'b1),
        .DATAOUT(spram0_rdata[31:16])
    );

    SB_SPRAM256KA spram1_lo (
        .ADDRESS(mem_addr[15:2]),
        .DATAIN(mem_wdata[15:0]),
        .MASKWREN({mem_wstrb[1], mem_wstrb[1], mem_wstrb[0], mem_wstrb[0]}),
        .WREN(|mem_wstrb),
        .CHIPSELECT(spram_sel1),
        .CLOCK(clk),
        .STANDBY(1'b0),
        .SLEEP(1'b0),
        .POWEROFF(1'b1),
        .DATAOUT(spram1_rdata[15:0])
    );

    SB_SPRAM256KA spram1_hi (
        .ADDRESS(mem_addr[15:2]),
        .DATAIN(mem_wdata[31:16]),
        .MASKWREN({mem_wstrb[3], mem_wstrb[3], mem_wstrb[2], mem_wstrb[2]}),
        .WREN(|mem_wstrb),
        .CHIPSELECT(spram_sel1),
        .CLOCK(clk),
        .STANDBY(1'b0),
        .SLEEP(1'b0),
        .POWEROFF(1'b1),
        .DATAOUT(spram1_rdata[31:16])
    );

    spimemio flash(
        .clk(clk), .resetn(resetn),
        .valid(flash_valid), .ready(flash_ready), .rdata(flash_rdata),
        .addr(mem_addr[23:0]), // Aliasing
        .flash_csb(spi_ssn), .flash_clk(spi_sck),
        .flash_io0_do(spi_mosi),
        .flash_io1_di(spi_miso),
        .flash_io0_di(1'b0), .flash_io2_di(1'b0), .flash_io3_di(1'b0), 
        .flash_io0_oe(), .flash_io1_oe(), .flash_io2_oe(), .flash_io3_oe(),
        .flash_io1_do(), .flash_io2_do(), .flash_io3_do(),
        .cfgreg_we(4'b0), .cfgreg_di(32'h0), .cfgreg_do()
    );

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
                    bus_rdata <= mem[mem_addr[9:2]];
                    if (mem_wstrb[0]) mem[mem_addr[9:2]][ 7: 0] <= mem_wdata[ 7: 0];    // one strobe per byte
                    if (mem_wstrb[1]) mem[mem_addr[9:2]][15: 8] <= mem_wdata[15: 8]; 
                    if (mem_wstrb[2]) mem[mem_addr[9:2]][23:16] <= mem_wdata[23:16];  
                    if (mem_wstrb[3]) mem[mem_addr[9:2]][31:24] <= mem_wdata[31:24];
                end

                4'h1: begin
                    // SPRAM goes here
                    bus_rdata <= 32'h0000_0000;
                end

                4'h2: begin
                    // Flash (spimemio) goes here
                    bus_rdata <= 32'h0000_0000;
                end

                4'h3: begin
                    // I/O. LEDs take bits 22:20 so changes are slow per scale w/ counter
                    bus_rdata <= 32'h0000_0000;
                    if (|mem_wstrb) leds <= mem_wdata[22:20];
                end

                default: begin
                    // Unmapped.
                    bus_rdata <= 32'h0000_0000;
                end
            endcase
        end
        if (!resetn) mem_ready <= 0;
    end


endmodule