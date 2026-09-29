// dd apogee check
// outputs 1 when accel near 0 AND rocket is high up!!
// unconverted sensor values (binary)

// for BMP581, datasheet says unsigned but in valid range

// delcaration!
module dual_deploy #(
    
    // near zero (placeholders) ~0.5 g at +-16 g range 
    parameter logic signed [15:0] ACC_TOL =  16'sd1024,
    
    // High up threshold (placeholders) : (69,680 Pa -> 24'h440C00) 
    parameter logic [23:0 ] P_THRESH = 24'h440C00 
)(

    input logic clk,
    input logic reset,
    input logic enable,

     // LSM6DSV320X raw accel (twos comp)
    input logic signed [15:0] accel_x,
    input logic signed [15:0] accel_y,
    input logic signed [15:0] accel_z,
    
    // BMP581 raw pressure (Pa × 64)
    input logic [23:0] pressure, 

    // 1=deploy, 0 = dont
    output logic deploy 
);


// logic!

    logic x_near_zero, y_near_zero, z_near_zero;
    logic accel_near_zero;
    logic high_up;

    assign x_near_zero = (accel_x > -ACC_TOL) && (accel_x < ACC_TOL);
    assign y_near_zero = (accel_y > -ACC_TOL) && (accel_y < ACC_TOL);
    assign z_near_zero = (accel_z > -ACC_TOL) && (accel_z < ACC_TOL);

   
    assign accel_near_zero = x_near_zero && y_near_zero && z_near_zero;
    assign high_up = (pressure < P_THRESH); // lower press =  higher alt

    always_ff @(posedge clk or posedge reset) begin 
        // if reset = 1 deploy = 0 
        if (reset)
            deploy <= 1'b0;
        else if (enable)
            deploy <= accel_near_zero && high_up; // update deploy
      
    end

endmodule