module SoftcoreTest (
    output wire led_red,
    output wire led_green,
    output wire led_blue
);
    // ---- 12 MHz internal oscillator (no external clock pin needed) ----
    wire clk;
    SB_HFOSC #(.CLKHF_DIV("0b10")) osc (
        .CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(clk)
    );

    // ---- Reset generator ----
    reg [7:0] rst_cnt = 0;
    wire resetn = &rst_cnt;
    always @(posedge clk) if (!resetn) rst_cnt <= rst_cnt + 1;

    // ---- CPU ----
    wire        mem_valid, mem_instr;
    reg         mem_ready;
    wire [31:0] mem_addr, mem_wdata;
    wire [3:0]  mem_wstrb;
    reg  [31:0] mem_rdata;

    picorv32 #(
        .ENABLE_COUNTERS     (0),
        .ENABLE_COUNTERS64   (0),
        .ENABLE_REGS_16_31   (1),   // set 0 for RV32E (smaller)
        .ENABLE_REGS_DUALPORT(1),
        .BARREL_SHIFTER      (0),
        .TWO_STAGE_SHIFT     (1),
        .TWO_CYCLE_COMPARE   (0),
        .TWO_CYCLE_ALU       (0),
        .CATCH_MISALIGN      (1),
        .CATCH_ILLINSN       (1),
        .COMPRESSED_ISA      (1),
        .ENABLE_MUL          (0),
        .ENABLE_DIV          (0),
        .ENABLE_IRQ          (0),
        .ENABLE_PCPI         (0),
        .ENABLE_TRACE        (0),
        .LATCHED_MEM_RDATA   (0),
        .PROGADDR_RESET      (32'h0000_0000)
    ) cpu (
        .clk(clk), .resetn(resetn),
        .mem_valid(mem_valid), .mem_instr(mem_instr),
        .mem_ready(mem_ready),
        .mem_addr(mem_addr), .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb), .mem_rdata(mem_rdata)
    );

    // ---- 1 KB RAM (infers EBR block RAM) with tiny firmware ----
    reg [31:0] mem [0:255];
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) mem[i] = 32'h0;
        mem[0] = 32'h800000b7; // lui  x1, 0x80000   (x1 = IO base)
        mem[1] = 32'h00000113; // addi x2, x0, 0
        mem[2] = 32'h00110113; // loop: addi x2, x2, 1
        mem[3] = 32'h0020a023; // sw   x2, 0(x1)
        mem[4] = 32'hff9ff06f; // j    loop
    end

    // ---- Memory / IO bus ----
    wire is_io  = mem_addr[31];
    reg  [2:0] leds = 0;

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

    // ---- RGB LED driver (active-low LEDs on UPduino) ----
    SB_RGBA_DRV #(
        .CURRENT_MODE("0b1"),
        .RGB0_CURRENT("0b000001"),
        .RGB1_CURRENT("0b000001"),
        .RGB2_CURRENT("0b000001")
    ) rgb (
        .CURREN(1'b1), .RGBLEDEN(1'b1),
        .RGB0PWM(leds[0]), .RGB1PWM(leds[1]), .RGB2PWM(leds[2]),
        .RGB0(led_green), .RGB1(led_blue), .RGB2(led_red)
    );
endmodule