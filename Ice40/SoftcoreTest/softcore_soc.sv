// PicoRV32 + 1 KB RAM + LED register
// 0x0000_0000  RAM (firmware runs from here)
// bit 31 set   LED register, write only
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

    // RAM, preloaded with a counter loop that writes to the LEDs
    reg [31:0] mem [0:255];
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) 
            mem[i] = 32'h0;
        $readmemh("Firmware/firmware.hex", mem);
    end

    // Address decode [mem_ready one clock after mem_valid]
    wire is_io  = mem_addr[31];

    always @(posedge clk) begin
        mem_ready <= 0;
        if (mem_valid && !mem_ready) begin
            mem_ready <= 1;
            if (is_io) begin
                if (|mem_wstrb) leds <= mem_wdata[22:20]; // slow enough to see
                mem_rdata <= 32'h0;
            end else begin
                mem_rdata <= mem[mem_addr[9:2]];
                if (mem_wstrb[0]) mem[mem_addr[9:2]][ 7: 0] <= mem_wdata[ 7: 0];
                if (mem_wstrb[1]) mem[mem_addr[9:2]][15: 8] <= mem_wdata[15: 8];
                if (mem_wstrb[2]) mem[mem_addr[9:2]][23:16] <= mem_wdata[23:16];
                if (mem_wstrb[3]) mem[mem_addr[9:2]][31:24] <= mem_wdata[31:24];
            end
        end
        if (!resetn) mem_ready <= 0;
    end

endmodule