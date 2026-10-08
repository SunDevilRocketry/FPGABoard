/*
Receiver (RX)

The mirror image of TX — it watches the incoming serial line, detects when a byte
starts arriving, samples each bit at the right moment, and reassembles the
original byte.

- Parameter: `samples` (number of samples per period)
- Inputs: `clk`, `rst`, `tick` (from baud gen), `rx_serial` (the incoming bit stream)
- Outputs: `rx_data[8:0]` (the reassembled byte), `rx_valid` (a single-cycle pulse
  meaning "a new byte just landed, go read it")

The receiver sits idle watching `rx_serial` for a falling edge, which signals the
start of a byte. Once that edge is seen, it waits 8 ticks (half a bit period) and
samples again to confirm it's a real start bit rather than line noise — this
confirmation step is the whole reason for oversampling, since it lets the sample
point land in the center of each bit. From there, it samples every 16 ticks (one
full bit period) to read out the 8 data bits, LSB first, matching how TX sent
them. Finally, it samples where the stop bit should be to close out the frame.
*/ 
module RX #(samples=16) (input rst, tick, rx_serial, output logic [7:0] rx_data, output logic rx_valid
//for testing
//, output logic [1:0] state, output logic [4:0] cSamples, output logic [3:0] count8
);

localparam idle = 2'b00, startbit = 2'b01, databits = 2'b10, stopbit = 2'b11;
logic [1:0] state;
logic [4:0] count8;
logic [$clog2(samples):0] cSamples; 
logic [1:0] nstate;

//rest counter 16 @ enter startbit, 8 ticks into startbit, and enter stopbit
Counter #($clog2(samples)) counterSamples ((samples-1), tick, (state==idle && ~rx_serial) || rst , cSamples);
Counter #(4) counter8 (4'd8, cSamples == '0, (state !=databits) || rst, count8);

Dreg #(2) statereg (nstate, tick, rst, 1'b1, state);

always_comb begin
	case(state)
	idle: 		nstate = (rx_serial)? idle: startbit;
	//if serial low as midsample => false startbit, return to idle.
	startbit:	nstate = (rx_serial && (cSamples == (((samples+1)/2)-2)))? idle : (~rx_serial && (cSamples == (((samples+1)/2)-2)))? databits: startbit;
	//remember we entered databit state halfway thru start bit, thus we must exit when count16 ==8 and we've taken 8 samples. 
	//if there is a framing error throw out the line and go back to idle. 
	databits: 	nstate =  (count8 == 4'd8 && (cSamples == samples-1) && rx_serial)? stopbit : databits;
	stopbit: 	nstate =  (cSamples == samples-1) ? idle : stopbit;
	default: 	nstate = idle;
	endcase
end

ShiftRightReg #(8) ByteReg (rx_serial, (cSamples == ((samples+1)/2)), rst, state == databits, rx_data);
assign rx_valid = (state == stopbit && (cSamples == ((samples+1)/2)) && rx_serial) ? 1'b1:1'b0;
endmodule