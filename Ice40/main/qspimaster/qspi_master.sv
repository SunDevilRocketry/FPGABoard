// ======================================================================================= // 
// quad-SPI Master (SPI mode 0, x1/x2/x4)
// no vender primitives, can change later if needed
// use qspi_io.sv for tri-state
// 
// SCLK frequency : f_sclk = f_clk / (2 * (clk_div + 1))
// Mode 0 (CPOL=0, CPHA=0): data driven on falling edge, sampled on rising
// late_sample = 1 for falling edge so that you can have the full half-period 
//      of margin for board + flash clock-to-out delay at high SCLK rates
// Byte-Phase Approach: 
//    cmd_op    : OP_TX    - drive cmd_data on the lanes of cmd_width
//                OP_RX    - release lanes and receive one byte
//                OP_DUMMY - cmd_data SCLK cycles with data lanes released (0 means 256)
//    cmd_width : 0 = x1 (IO0=MOSI, IO1=MISO, full duplex)
//                1 = x2 (IO1:IO0)       
//                2 or 3 = x4 (IO3:IO0)
//    cmd_last  : CS goes high
// ======================================================================================= // 

module qspi_master #(
    parameter DIV_W = 8,
    parameter DRIVE_WP_HOLD = 1'b1
)(
    input logic clk, rst_n,

    input logic [DIV_W-1:0] clk_div,     // latched at start of each burst
    input logic late_sample,             // latched at start of each burst

    // command stream
    input logic cmd_valid, cmd_last,
    input logic [7:0] cmd_data,
    input logic [1:0] cmd_width, cmd_op,

    output logic cmd_ready,

    // receive stream 
    output logic rx_valid,
    output logic [7:0] rx_data,

    output logic busy,

    // pins
    output logic sclk, cs_n,

    input logic [3:0] io_i,
    output logic [3:0] io_o, io_oe
);

    localparam logic [1:0] OP_TX = 2'b00;
    localparam logic [1:0] OP_RX = 2'b01;

    localparam logic [1:0] OP_DUMMY = 2'b10;

    localparam logic [1:0] W_X1 = 2'b00;
    localparam logic [1:0] W_X2 = 2'b01;
    localparam logic [1:0] W_X4 = 2'b10;

    // idle pin state: IO0 driven low, IO1 released, IO2/IO3 high (optional)
    localparam logic [3:0] IDLE_O  = 4'b1100;
    localparam logic [3:0] IDLE_OE = {DRIVE_WP_HOLD, DRIVE_WP_HOLD, 1'b0, 1'b1};

    // state machine states
    typedef enum logic [2:0] {S_IDLE, S_LEAD, S_XFER, S_TRAIL, S_WAIT, S_GAP} state_t;
    state_t state;

    // slk timing 
    logic [DIV_W-1:0] div_q, cnt;
    logic late_q;

    // current command 
    logic last_q;
    logic [1:0] op_q, w_q;

    // data shift registers 
    logic [7:0] tx_sr, rx_sr;

    // edge counter for SCLK
    logic [8:0] edge_cnt, edge_end;

    // output registers for pins
    logic sclk_q, cs_n_q;
    logic [3:0] io_o_q;
    logic [3:0] io_oe_q; // output enable per IO line, 1=drive, 0=release

    // tick when counter reaches zero 
    logic tick;
    logic accept;
    logic shift_en;

    assign tick = (cnt == '0);
    assign accept = cmd_valid && cmd_ready;
    assign shift_en = (op_q == OP_TX) || ((op_q == OP_RX) && (w_q == W_X1));

    //
    // decode of a new command: initial lane values, shift register, edge count
    // 
    logic [1:0] w_n;
    logic [3:0] o_n, oe_n;
    logic [7:0] sr_n;
    logic [8:0] end_n;

    always_comb begin 
        // initialize
        w_n = (cmd_width == 2'b11) ? W_X4 : cmd_width; // treat width=3 as x4

        o_n = '0;
        oe_n = '0;
        sr_n = cmd_data;

        case ( w_n )
            // IO0 always driven in x1
            W_X1 : begin
                if (cmd_op == OP_TX) begin
                    oe_n[0] = 1'b1;
                    o_n[0] = cmd_data[7];
                    sr_n = {cmd_data[6:0], 1'b0};
                end
            end

            // IO1 and IO0 driven in x2
            W_X2 : if (cmd_op == OP_TX) begin

                oe_n[1:0] = 2'b11;
                o_n[1:0] = cmd_data[7:6];
                sr_n = {cmd_data[5:0], 2'b00};

            end

            // default
            default : if (cmd_op == OP_TX) begin

                oe_n = 4'b1111;
                o_n = cmd_data[7:4];
                sr_n = {cmd_data[3:0], 4'b0000};

            end
        endcase

        if (DRIVE_WP_HOLD && w_n != W_X4) begin
            oe_n[3:2] = 2'b11;
            o_n[3:2] = 2'b11;
        end

        if (cmd_op == OP_DUMMY) begin
            end_n = {cmd_data, 1'b0} - 9'd1; // 0 -> 256 clocks
        end else begin
            end_n = (9'd16 >> w_n) - 9'd1; // 8/4/2 clocks
        end
    end

// 
// state machine
//
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin               // reset active low
        state <= S_IDLE;
        div_q <= '0;
        cnt <= '0;
        late_q <= 1'b0;
        last_q <= 1'b0;
        op_q <= OP_TX;
        w_q <= W_X1;
        tx_sr <= '0;
        rx_sr <= '0;
        rx_valid <= 1'b0;
        rx_data <= '0;
        edge_cnt <= '0;
        edge_end <= '0;
        sclk_q <= 1'b0;
        cs_n_q <= 1'b1;
        io_o_q <= IDLE_O;
        io_oe_q <= IDLE_OE;
        end else begin
        // initialize 
        rx_valid <= 1'b0;

        if (state != S_IDLE & state != S_WAIT ) // count down the clock divider
            cnt <= tick ? div_q : cnt - 1'b1;

        case ( state )
            // S_IDLE: wait for a command, drive idle pin state
            S_IDLE : begin
            end

            // S_LEAD: start the SCLK clocking, initialize the edge counter
            S_LEAD : if (tick) begin
                edge_cnt <= '0;
                state <= S_XFER;
            end

            // S_XFER: shift data on the falling edge, sample data on the rising edge
            S_XFER : if (tick) begin
                sclk_q <= ~sclk_q;
                edge_cnt <= edge_cnt + 1'b1;

                // sample: rising edge (even), 
                if (edge_cnt[0] == late_q) begin
                    // gotta choose whether to sample 1, 2, or 4 bits from the IO lines
                    case (w_q)
                        W_X1 : rx_sr <= {rx_sr[6:0], io_i[1]};
                        W_X2 : rx_sr <= {rx_sr[5:0], io_i[1:0]};
                        default : rx_sr <= {rx_sr[3:0], io_i[3:0]};
                    endcase
                end

                // drive: falling edge (odd)
                if (edge_cnt[0] && shift_en) begin
                    case (w_q)
                        W_X1 : begin
                            io_o_q[0] <= tx_sr[7];
                            tx_sr <= {tx_sr[6:0], 1'b0};
                        end

                        W_X2 : begin
                            io_o_q[1:0] <= tx_sr[7:6];
                            tx_sr <= {tx_sr[5:0], 2'b00};
                        end

                        default : begin
                            io_o_q <= tx_sr[7:4];
                            tx_sr <= {tx_sr[3:0], 4'b0000};
                        end
                    endcase
                end

                if (edge_cnt == edge_end) begin
                    state <= S_TRAIL;
                    // we want to release the x2/x4 lines on the final falling edge
                    // the next OP_TX re-enables them 
                    if (op_q == OP_TX && w_q == W_X2) io_oe_q[1:0] <= 2'b00;
                    if (op_q == OP_TX && w_q == W_X4) io_oe_q[3:0] <= 4'b0000;
                end
            end

            // S_TRAIL: finish the transfer, release the CS line
            S_TRAIL : if (tick) begin
                if (op_q != OP_DUMMY) begin
                    rx_valid <= 1'b1;
                    rx_data <= rx_sr;
                end

                if (last_q) begin
                    cs_n_q <= 1'b1;
                    state <= S_GAP;
                end else begin
                    state <= S_WAIT;
                end
            end

            // S_GAP: wait for the slave to release the bus, then go to idle
            S_GAP : if (tick) begin
                io_o_q <= IDLE_O; // restore idle drive
                io_oe_q <= IDLE_OE;
                state <= S_IDLE;
            end

            // default: just go to idle
            default : state <= S_IDLE;
        endcase

        if (accept) begin
             if (state == S_IDLE) begin 
                div_q <= clk_div;
                cnt <= clk_div;
                late_q <= late_sample;
                cs_n_q <= 1'b0;
            end else begin
                cnt <= div_q;
            end

            op_q <= cmd_op;
            w_q <= w_n;
            last_q <= cmd_last;
            tx_sr <= sr_n;
            edge_end <= end_n;
            io_o_q <= o_n;
            io_oe_q <= oe_n;
            state <= S_LEAD;

        end
    end
end

// assign outputs
assign busy = (state != S_IDLE);
assign sclk = sclk_q;
assign cs_n = cs_n_q;
assign io_o = io_o_q;
assign io_oe = io_oe_q;

endmodule 