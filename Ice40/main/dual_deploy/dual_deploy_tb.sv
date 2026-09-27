

// tb for dd
// current thresholds: ACC_TOL = 1024, P_THRESH = 24 'h440C00

module dual_deploy_tb;

logic clk, reset, enable;
logic signed [15:0] accel;
logic [23:0] pressure;
logic deploy;

dual_deploy uut (.clk(clk), .reset(reset), .enable(enable), .accel(accel), .pressure(pressure), .deploy(deploy)
);


initial begin 
    $dumpvars(0, dual_deploy_tb); // collects results for gtkwave

    //reset -> deploy=0
    clk = 1'b0; reset = 1'b1; enable = 1'b0; accel = 16'sd0; pressure = 24'd0; #5;
    clk = 1'b1; #5;
    clk = 1'b0; reset = 1'b0; enable = 1'b1; #5; // waits 5 s


    // on the pad : 1g, ~97kPa so deploy should = 0
    accel = 16'sd2029; pressure = 24'd6080000;

    // each repeat (2) for one full clock cycle 
    repeat (2) begin clk = ~clk; #5; end

  // boost: 10 g, ~86 kPa so deploy = 0
    accel = 16'sd20000; pressure = 24'd5500000;
    repeat (2) begin clk = ~clk; #5; end

    // near zero but low altitude so deploy = 0
    accel = 16'sd0; pressure = 24'd6080000;
    repeat (2) begin clk = ~clk; #5; end

    // apogee: ~0 g, 62.5 kPa so deploy = 1
    accel = 16'sd100; pressure = 24'd4000000;
    repeat (2) begin clk = ~clk; #5; end

    // apogee, negative accel so deploy = 1
    accel = -16'sd100;
    repeat (2) begin clk = ~clk; #5; end

    // enable low: inputs say no but deploy holds 1
    enable = 1'b0; accel = 16'sd20000; pressure = 24'd6080000;
    repeat (2) begin clk = ~clk; #5; end

    // async reset: deploy drops to 0 right away
    reset = 1'b1; #5;
    reset = 1'b0; enable = 1'b1;
    repeat (2) begin clk = ~clk; #5; end

end

endmodule