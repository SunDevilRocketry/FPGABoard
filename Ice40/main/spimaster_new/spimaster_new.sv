//----------------------------------------------------------------------------//
// New SPI Module
// Last updated: 2026-10-18

/*

SPI mode 0 or mode 3 
 - MOSI changes on falling edge of SCLK
 - MISO sampled on rsiing edge of SCLK

Assuming 1.8V 
(i think we need to change these in spi_pkg.sv?)

BMP581: (page 32, table 18 in datasheet)
https://www.bosch-sensortec.com/media/boschsensortec/downloads/datasheets/bst-bmp581-ds004.pdf#page=31.0 
- F_SCLK_MAX_HZ = 12 MHz
- T_CS_SETUP_NS = 40 ns
- T_CS_HOLD_NS = 40 ns 
- T_CS_IDLE_NS = 80 ns
- T_SCLK_MIN_NS = 37.5 ns
- T_SDO_NS = 27.8 ns

LSM6DSV320: (page 17, table 6 in datasheet) 
https://mm.digikey.com/Volume0/opasdata/d220001/medias/docus/9033/DS_lsm6dsv320x.pdf
- F_SCLK_MAX_HZ = 10 MHz
- T_CS_SETUP_NS = 20 ns 
- T_CS_HOLD_NS = 20 ns
- T_CS_IDLE_NS = 80 ns
- T_SCLK_MIN_NS = 45 ns
- T_SDO_NS = 25 ns

take the restraint of the slower one, so:
10 MHz, 40 ns, 40 ns, 80 ns, 45 ns, 27.8 ns

ICE40UP5K: (page 37, table 4.21 in datasheet)
https://www.farnell.com/datasheets/3215488.pdf
- T_CO = 10.0 ns

*/

//----------------------------------------------------------------------------//

module spimaster_new #(
    parameter int CLK_HZ = 12_000_000, // 12 MHz
    parameter int CLK_DIV = 4, // SCLK = CLK_HZ / (2*CLK_DIV)
    parameter int N_BYTES = 1, // bytes to read after address byte
    parameter bit CPOL = 1'b0, // 0: mode 0, 1: mode 1

    parameter int F_SCLK_MAX_HZ = 12_000_000, // BMP581 max SCLK freq 
    parameter int T_CS_SETUP_NS = 40,         // NCS fall, first SCLK edge
    parameter int T_CS_HOLD_NS = 40,          // last SCLK rising edge
    parameter int T_CS_IDLE_NS = 80,          // NCS high time between transactions
    parameter real T_SCLK_MIN_NS = 45,        // min SCLK high/low pulse width 
    parameter real T_SDO_NS = 27.8,           // SCLK fall -> SDO valid 
    parameter real T_BOARD_NS = 15.0          //  
)
// Ports
(   
    input logic clk, reset, 
    input logic start, input logic [6:0] addr,

    output logic busy,
    output logic done, output logic [8*N_BYTES-1:0] rdata, 
    // first byte read will be rdata[8*N_BYTES-1:0 -: 8]

    output logic SCLK, NCS, MOSI, MISO
);

// Local Paramters 
    // 10kHz resolution 
    // takes whatever clock we have, adds 9,999 Hz to it and divides by 10k
    // EX: 12,009,999 / 10,000 = 1200 (it rounds up)
    // we need to scale the time and multiply by the clock bc doing directly in Hz
    // will overflow a 32-bit int
    // rescaling to 10kHz units allows us to use smaller numbers
    localparam int CLK_10K = (CLK_HZ + 9_999) / 10_000;
    function automatic int ns2cyc(input int ns);
        ns2cyc = (ns*CLK_10K + 99_999) / 100_000;
        if (ns2cyc < 1)
            ns2cyc = 1;
    endfunction

    localparam int CS_SETUP_CYC = ns2cyc(T_CS_SETUP_NS);
    localparam int CS_HOLD_CYC = ns2cyc(T_CS_HOLD_NS); 
    localparam int CS_IDLE_CYC = ns2cyc(T_CS_IDLE_NS);

    localparam int TOTAL_BITS = 8*(1+N_BYTES);
    localparam int N_EDGES = TOTAL_BITS;

    // counter needs to be wide enough 
    localparam int MAX_WAIT = (CS_IDLE_CYC > CS_SETUP_CYC) ?
                                ((CS_IDLE_CYC > CS_HOLD_CYC + CLK_DIV) ?
                                CS_IDLE_CYC : CS_HOLD_CYC + CLK_DIV) :
                                ((CS_SETUP_CYC > CS_HOLD_CYC + CLK_DIV) ? 
                                CS_SETUP_CYC : CS_HOLD_CYC + CLK_DIV);
    localparam int WAIT_W = $clog2(MAX_WAIT + 1); // number of bits needed to count to MAX_WAIT
    localparam int EDGE_W = $clog2(N_EDGES + 1);  // counts SCLK edges from 0 to N_EDGES

// For the FSM
    typedef enum logic [2:0] {IDLE, CS_SETUP, XFER, CS_HOLD, CS_IDLE} state_;
    state_ state;

// Internal Signals
    logic [WAIT_W-1:0] wait_cnt; // counts down in CS_SETUP, XFER, CS_HOLD, CS_IDLE
    logic [EDGE_2-1:0] edge_cnt; // SCLK toggles done in XFER
    logic [7:0] tx_sr;           // address byte
    logic [8*N_BYTES-1:0] rx_sr; // read bytes 
    logic miso_q;                // MISO resgister on same clk edge that pulls SCLK high 
    logic sample;                // shift miso_q into rx_sr on this cycle

// Busy 
    assign busy = (state != IDLE);

// FSM 
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin 
            state       <= IDLE;
            NCS         <= 1'b1;
            SCLK        <= CPOL;
            MOSI        <= 1'b0;
            wait_cnt    <= '0;
            edge_cnt    <= '0;
            tx_sr       <= '0;
            rx_sr       <= '0;
            rdata       <= '0;
            done        <= 1'b0;
            miso_q      <= 1'b0;
            sample      <= 1'b0;
        end else begin
            done        <= 1'b0;
            sampel      <= 1'b0;
            miso_q      <= MISO;

            // get bit at the rising edge 1 cycle ago 
            // bits from address byte fall off, so after last sample
            // rx_sr holds the N_BYTES read bytes
            if (sample) 
                rx_sr <= {rx_sr[8*N_BYGTES-2:0], miso_q};

            unique case (state)
                // IDLE State
                IDLE: begin
                    NCS     <= 1'b1;
                    SCLK    <= CPOL;
                    MOSI    <= 1'b0;
                    if (start) begin 
                        // MOSI gets first bit as NCS falls so 
                        // has the whole CS setup time before rising edge
                        tx_sr   <= {1'b1, addr};
                        MOSI    <= 1'b1;
                        NCS     <= 1'b0;
                        wait_cnt<= WAIT_W'(CS_SETUP_CYC - 1);
                        state   <= CS_SETUP;
                    end
                end

                // CS_SETUP state 
                CS_SETUP: begin 
                    if (wait_cnt == 0) begin
                        // first SCLK edge on the next cycle: 
                        // rising in mode 0 
                        // falling in mode 3 
                        edge_cnt <= '0;
                        state    <= XFER;
                    end else begin
                        wait_cnt <= wait_cnt - 1'b1;
                    end
                end

                // XFER state 
                XFER: begin
                    if (wait_cnt != 0) begin
                        wait_cnt <= wait_cnt - 1'b1;
                    end else if (edge_cnt == EDGE_W'(N_EDGES)) begin
                        // last toggle was half a period ago, and in mode 0
                        // that means it was falling
                        // for mode 3, it was rising
                        wait_cnt <= WAIT_W'(CS_HOLD_CYC - 1);
                        state <= CS_HOLD;
                    end else begin 
                        wait_cnt <= WAIT_W'(CLK_DIV - 1);
                        edge_cnt <= edge_cnt + 1'b1;
                        SCLK <= ~SCLK;
                        if (SCLK == 1'b0) begin
                            // rising edge: slave samples MOSI, we sample MISO
                            sample <= 1'b1;
                        end else if (!(CPOL==1'b1 && edge_cnt==0)) begin 
                            // falling edge: move MOSI to the next 
                            // after adddress byte tx_sr has shifted in zeros
                            tx_sr <= {tx_sr[6:0], 1'b0};
                            MOSI <= tx_sr[6];
                        end
                    end
                end

                // CS_HOLD state
                CS_HOLD: begin
                    if (wait_cnt == 0) begin
                        NCS     <= 1'b1;
                        MOSI    <= 1'b0;
                        rdata   <= rx_sr;
                        done    <= 1'b1;
                        wait_cnt<= WAIT_W'(CS_IDLE_CYC - 1);
                        state   <= CS_IDLE;
                    end else begin
                        wait_cnt <= wait_cnt - 1'b1;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule