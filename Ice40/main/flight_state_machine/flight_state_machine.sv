

//TODO: HOW TO MEASURE CONTINUITY
  // need to confirm board clock
module flight_state_machine #(parameter int CLK_HZ = 12_000_000 )(
  input logic clk,
  input logic reset,

  // sensors:
  input logic signed [15:0] accel_x, accel_y, accel_z,
  input logic [23:0] pressure,
  input logic deploy_confirmed,

  //enables:
  output logic passthrough_en,
  output logic record_en,
  output logic dd_en,
  output logic deploy

);



typedef enum logic [2:0]  {
  IDLE, LAUNCH, COAST, APOGEE, DESCENT, LANDED

} state_type;

state_type state, next_state;


//detector signals
logic launch_detected, burnout_detected, apogee_detected, landed_detected;

// state reggg

always_ff @(posedge clk or posedge reset) begin
  if (reset) state <= IDLE;
  else state <= next_state;

end

//timing

localparam int SAMPLE_CYCLES = CLK_HZ / 20;  // velocity sample every 50 ms

// thresholds
localparam int ONE_G = 2048;  //  (±16 g range)
localparam int LAUNCH_ACC= 2 * ONE_G;  // > 2 G   
localparam int BURNOUT_ACC = 0;   // < 0< G
localparam int PA_PER_FT  = 3;   
localparam int LAUNCH_ALT_P = 50 * PA_PER_FT * 64;  // > 50 ft above pad 
localparam int VEL_TOL = 1 * PA_PER_FT * 64;   

localparam int HOLD_CYCLES  = CLK_HZ / 5; // 0.2 s
localparam int LAND_CYCLES  = CLK_HZ * 5;    

// sample_tick pulses for 1 clock every 50 ms
logic [19:0] sample_count;
logic sample_tick;

always_ff @(posedge clk or posedge reset) begin
  if (reset)
    sample_count <= '0;
  else if (sample_count == SAMPLE_CYCLES-1) 
    sample_count <= '0;
  else     
    sample_count <= sample_count + 1'b1;
end


assign sample_tick = (sample_count == SAMPLE_CYCLES-1);

// pad pressure tracks while in idle and freezes once launched
logic [23:0] pad_pressure;

always_ff @(posedge clk or posedge reset) begin
  if (reset)             
    pad_pressure <= '0;
 else if (state == IDLE && accel_z <= LAUNCH_ACC) 
    pad_pressure <= pressure;
end

// altitude above pad (positive = higher)
logic signed [24:0] alt_p;
assign alt_p = $signed({1'b0, pad_pressure}) - $signed({1'b0, pressure});


//(positive = going up)
logic [23:0] prev_pressure;
logic signed [24:0] vel_p;

always_ff @(posedge clk or posedge reset) begin
  if (reset) begin
    prev_pressure <= '0;
    vel_p         <= '0;
  end else if (sample_tick) begin
    vel_p         <= $signed({1'b0, prev_pressure}) - $signed({1'b0, pressure});
    prev_pressure <= pressure;
  end
end

      

// conditions
logic launch_cond, burnout_cond, apogee_cond, landed_cond;

assign launch_cond  = (accel_z > LAUNCH_ACC) && (alt_p > LAUNCH_ALT_P);
assign burnout_cond = (accel_z < BURNOUT_ACC) && (vel_p > VEL_TOL);   // decelerating but still rising
assign apogee_cond  = (vel_p < -VEL_TOL);   // coming down
assign landed_cond  = (vel_p > -VEL_TOL) && (vel_p < VEL_TOL);  // not moving


// each counts only in  own state and resets whent condition fails
logic [26:0] launch_cnt, burnout_cnt, apogee_cnt, landed_cnt;

always_ff @(posedge clk or posedge reset) begin
  if (reset) begin
    launch_cnt  <= '0;
    burnout_cnt <= '0;
    apogee_cnt  <= '0;
    landed_cnt  <= '0;
  end else begin
    launch_cnt  <= (state == IDLE    && launch_cond)  ? launch_cnt  + 1'b1 : '0;
    burnout_cnt <= (state == LAUNCH  && burnout_cond) ? burnout_cnt + 1'b1 : '0;
    apogee_cnt  <= (state == COAST   && apogee_cond)  ? apogee_cnt  + 1'b1 : '0;
    landed_cnt  <= (state == DESCENT && landed_cond)  ? landed_cnt  + 1'b1 : '0;
  end
end

assign launch_detected  = (launch_cnt  >= HOLD_CYCLES);
assign burnout_detected = (burnout_cnt >= HOLD_CYCLES);
assign apogee_detected  = (apogee_cnt  >= HOLD_CYCLES);
assign landed_detected  = (landed_cnt  >= LAND_CYCLES);

//transitions
 always_comb begin
  next_state = state; // defaults to stay in current state
  case(state) // go to current state

    IDLE: 
      if (launch_detected) next_state = LAUNCH;
    
    LAUNCH: 
      if (burnout_detected) next_state = COAST;

    COAST:
      if (apogee_detected) next_state = APOGEE;

    APOGEE:
      if (deploy_confirmed) next_state = DESCENT;

    DESCENT:
      if (landed_detected) next_state = LANDED;
      
    LANDED: 
      next_state = LANDED;

    default: next_state = IDLE;

  endcase
 end

 //output:

 always_comb begin 
    passthrough_en = (state == IDLE);

    record_en = (state == LAUNCH) || (state == COAST) 
    || (state == APOGEE) || (state == DESCENT);

    dd_en = (state == COAST) || (state == APOGEE);

 end

 // deploy: latched high once apogee is reached

 always_ff @(posedge clk or posedge reset) begin
  if (reset) deploy <= 1'b0;
  else if (state == APOGEE) deploy <= 1'b1;

 end 
endmodule

    
