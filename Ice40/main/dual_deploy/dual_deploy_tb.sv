

// tb for dd
// current thresholds: ACC_TOL = 1024, P_THRESH = 24 'h440C00

module dual_deploy_tb;

logic clk, reset, enable;
logic signed [15:0] accel_x, accel_y, accel_z;
logic [23:0] pressure;
logic deploy;


dual_deploy uut (.clk(clk), .reset(reset), .enable(enable),
.accel_x(accel_x), .accel_y(accel_y), .accel_z(accel_z),
.pressure(pressure), .deploy(deploy));




initial begin 
    $dumpvars(0, dual_deploy_tb); // collects results for gtkwave

    //reset  : deploy=0
    clk = 1'b0; reset = 1'b1; enable = 1'b0; accel_x = 16'sd0; accel_y = 16'sd0; accel_z = 16'sd0; pressure = 24'd0; #5;
    clk = 1'b1; #5;
    clk = 1'b0; reset = 1'b0; enable = 1'b1; #5; // waits 5 s

// NEED TB FOR HIGH UP && HIGH ACC (SHOULDNT DEPLOY)

    // on the pad  1g so deploy  = 0
    accel_x = 16'sd0; accel_y = 16'sd0; accel_z = 16'sd2049; pressure = 24'd6080000;
    repeat (2) begin clk = ~clk; #5; end

  // boost: 10 g,  so deploy = 0
    accel_x = 16'sd0; accel_y = 16'sd0; accel_z = 16'sd20000; pressure = 24'd5500000;
    repeat (2) begin clk = ~clk; #5; end

    // near zero  low altitude so deploy = 0
    accel_x = 16'sd0; accel_y = 16'sd0; accel_z = 16'sd0; pressure = 24'd6080000;
    repeat (2) begin clk = ~clk; #5; end

      // high up, z ~0 but one axis not near zero(x) so deploy = 0
    accel_x = 16'sd2049; accel_y = 16'sd0; accel_z = 16'sd100; pressure = 24'd4000000;
    repeat (2) begin clk = ~clk; #5; end

    // apogee: all axes ~0 g, deploy = 1
    accel_x = 16'sd50; accel_y = -16'sd30; accel_z = 16'sd100; pressure = 24'd4000000;
    repeat (2) begin clk = ~clk; #5; end

    // apogee neg accel so deploy = 1
    accel_z = -16'sd100;
    repeat (2) begin clk = ~clk; #5; end

    // enable low deploy was 1 so should stay 1
    enable = 1'b0; accel_z = 16'sd20000; pressure = 24'd6080000;
    repeat (2) begin clk = ~clk; #5; end

    // reset: deploy  =0
    reset = 1'b1; #5;
    reset = 1'b0; enable = 1'b1;
    repeat (2) begin clk = ~clk; #5; end

    

end

endmodule