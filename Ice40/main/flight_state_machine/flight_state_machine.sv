module flight_state_machine(
  input logic clk,
  input logic reset,


  // sensors:
  input logic signed [15:0] accel_x, accel_y, accel_z,
  input logic [23:0] pressure;

  //enables:
  output logic passthrough_en,
  output logic record_en,
  output logic dd_en,
  output logic deploy

);



//TODO: HOW TO MEASURE CONTINUITY
input logic deploy_confirmed;

localparam int APOGEE_WAIT = 24_000_000 ;

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
      if (deploy_confirmed) nextstate = DESCENT;

    DESCENT:
      if (landed_detected) next_state = LANDED;\
      

    LANDED: 
      next_state = IDLE;

  endcase
 end

 //output:

 always_comb begin 
    passthrough_en = (state == IDLE);

    record_en = (state == LAUNCH) || (state == COAST) 
    || (state == APOGEE) || (state == DESCENT);

    dd_en = (state == COAST) || (state == APOGEE);

 end;

 // deploy: latched high once apogee is reached

 always_ff @(posedge clk or posedge reset) begin
  if (reset) deploy <= 1'b0;
  else if (state == APOGEE) deploy <= 1'b1;

 end 
endmodule

    



    // IDLE:
   // passthrough_en: 1
    //record_en = 0
    // dd_en = 0
    // deploy = 0;

    //LAUNCH: 
    //passthrough_en: 0
    //record_en = 0
    // dd_en = 0
    // deploy = 0;

    //COAST:
    //passthrough_en: 0
    //record_en = 1
    // dd_en = 1
    // deploy = 0;


  //APOGE:
    //passthrough_en: 0
    //record_en = 1
    // dd_en = 1
    // deploy = 1

  //Decent:
    // passthrough_en: 0
    //record_en = 1
    // dd_en = 0
    // deploy = latched 1;
    
  //LANDED:




  // PASSTHROUGH, n QSPI, 

)