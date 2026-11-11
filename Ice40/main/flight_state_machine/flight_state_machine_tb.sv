`timescale 1ns/1ps

// simulates one normal flight: IDLE -> LAUNCH -> COAST -> APOGEE -> DESCENT -> LANDED
// and some safeguard checks like a bump after landing)

module flight_state_machine_tb;

  logic clk, reset;
  logic signed [15:0] accel_x, accel_y, accel_z;
  logic [23:0] pressure;
  logic deploy_confirmed;
  logic passthrough_en, record_en, dd_en, deploy;


  localparam logic [2:0] S_IDLE = 3'd0;
  localparam logic [2:0] S_LAUNCH = 3'd1;
  localparam logic [2:0] S_COAST = 3'd2;
  localparam logic [2:0] S_APOGEE = 3'd3;
  localparam logic [2:0] S_DESCENT = 3'd4;
  localparam logic [2:0] S_LANDED = 3'd5;

  // sensor values
  localparam int G1  = 2048;    // 1 G
  localparam int PAD_P = 96_000 * 64; // ~96 kPa on the pad 
  localparam int RISE_DP = -20;   // pressure change per clock while going up
  localparam int FALL_DP =  20;  // pressure change per clock while  down

  // DUT
  // CLK_HZ = 1000 
  flight_state_machine #(.CLK_HZ(1000)) uut (
    .clk(clk), .reset(reset),
    .accel_x(accel_x), .accel_y(accel_y), .accel_z(accel_z),
    .pressure(pressure),
    .deploy_confirmed(deploy_confirmed),
    .passthrough_en(passthrough_en), .record_en(record_en),
    .dd_en(dd_en), .deploy(deploy)
  );

  
  initial clk = 1'b0;
  always #5 clk = ~clk;

  int errors = 0;

  // run n clock cycles andchanging pressure by dp for every cycle
  task automatic run(input int n, input int dp);
    repeat (n) begin
      @(posedge clk);
      pressure <= pressure + dp;
    end
  endtask

  // compare state outputs to what we expect
  task automatic check(input string label,input logic [2:0] exp_state,
input logic exp_pt, input logic exp_rec,input logic exp_dd, input logic exp_dep);
    if (uut.state   !== exp_state || passthrough_en !== exp_pt ||
    record_en   !== exp_rec   || dd_en !== exp_dd ||deploy !== exp_dep) begin
      $display("FAIL %s: state=%0d pt=%b rec=%b dd=%b deploy=%b",
               label, uut.state, passthrough_en, record_en, dd_en, deploy);
      errors++;
    end else begin
      $display("PASS %s", label);
    end
  endtask

  
  initial begin
   
// 1 G up, steady pressure
    accel_x = 0; accel_y = 0; accel_z = G1;
    pressure = PAD_P;
    deploy_confirmed = 1'b0;

    reset = 1'b1;
    repeat (3) @(posedge clk);
    reset = 1'b0;

    run(300, 0);
    
    check("IDLE on pad",S_IDLE, 1, 0, 0, 0);

    // short accel spike so must'nt  launch
    accel_z = 10 * G1;
    run(50, 0);
    accel_z = G1;
    run(300, 0);
    check("short spike ignored",S_IDLE, 1, 0, 0, 0);

    // boost 10 G and climbing
    accel_z = 10 * G1;
    run(1000, RISE_DP);
    check("LAUNCH",S_LAUNCH,  0, 1, 0, 0);

    // burnout slightly negative accel
    accel_z = -G1 / 2;
    run(400, RISE_DP);
    check("COAST", S_COAST,   0, 1, 1, 0);

    //  pressure starts rising (coming down)
    accel_z = 0;
    run(400, FALL_DP);
    check("APOGEE (deploy fires)", S_APOGEE,  0, 1, 1, 1);

    // placeholder for continuity 
    deploy_confirmed = 1'b1;
    run(10, FALL_DP);
    check("DESCENT (deploy latched)", S_DESCENT, 0, 1, 0, 1);

    // keep falling -> then land and sit still for > 5 s
    run(500, FALL_DP);
    accel_z = G1;
    run(6000, 0);
    check("LANDED", S_LANDED,  0, 0, 0, 1);

    // a bump after landing must'nt  relaunch
    accel_z = 10 * G1;
    run(1000, 0);
    accel_z = G1;
    run(100, 0);
    check("bump after landing", S_LANDED,  0, 0, 0, 1);

    // summed up
    if (errors == 0) 
        $display("ALL TESTS PASSED");
    else 
        $display("%0d TEST(S) FAILED", errors);

    $finish;
  end

endmodule
