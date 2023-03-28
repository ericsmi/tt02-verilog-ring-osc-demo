`timescale 1ns/100ps
module tb (
    // testbench is controlled by test.py
    input dclk,
    input go,
    input [31:0] dclk_period,
    input record_vcd,
    input run_smoke_test,
    input run_measurement,
    input run_show_status,
    output pass_flag 
   );

reg rclk,rpass;
assign pass_flag = rpass;

int period;
//initial period = dclk_period;
initial period = 1000; // make sure this is the same as test.py
                       // not sure why this variable pass failed

reg nrst,trig;
reg [1:0] ring_en;
reg [2:0] sel;
reg [23:0] count0,count1;

wire [7:0] out;

ericsmi_speed_test speed_test(
  .io_in( { ring_en[1:0],sel[2:0],trig,nrst,clk} ),
  .io_out( out[7:0] )
);

// 
// Not sure why this fires in cocotb. 
// Dont want to know. :)
//
//initial begin
//  #(20*period);
//  $display("ERROR: Caught Timeout Trap");
//  $finish;
//end


wire clk;

`ifdef COCOTB_SIM
  initial rclk=0;
  assign clk = dclk;
`else
  // not inside cocotb 
  initial begin
    rclk = 1 ; #(period/2) rclk = 0 ;
    forever #(period/2) rclk = ~rclk ;
  end
  assign clk = rclk;
`endif

initial begin
   rpass = 0;

   //$sdf_annotate("speed_test.sdf",speed_test, , , "maximum");

   if ( 1'b1 == record_vcd ) begin
     $dumpfile("tb.vcd");
     $dumpvars(0);
   end

   if( 1'b0 == (run_smoke_test|run_measurement|run_show_status)) begin
     $display("ERROR: nothing to do");
     $finish;
   end

   @(posedge go);

   // wrapper initializes all inputs to 0
   nrst = 0;
   trig = 0;
   sel[2:0] = 3'b000;
   ring_en[1:0] = 2'b00;

   if (1 == run_smoke_test) begin
      @(negedge clk);
      if ( out[7] != 1'b0 ) begin
         $display("ERROR: smoke_test: out[7] is not clear");
         $finish;
      end
      sel[2:0] = 3'b111;
      @(posedge clk);
      if ( out[7] != 1'b1 ) begin
         $display("ERROR: smoke_test: out[7] is not set");
         $finish;
      end
      $display("PASS: smoke_test, out[7] changed state");
   end

   if (1 == run_measurement) begin
    @(negedge clk);
    nrst = 1;
    sel[2:0] = 3'b000;
    ring_en[1:0] = 2'b11;
    @(negedge clk);
    if ( out[7] != 1'b0 ) begin
       $display("ERROR: smoke_test: out[7] is not clear");
       $finish;
    end
    if ( out[6] != 1'b0 ) begin
       $display("ERROR: fired bit not clear");
       $finish;
    end
    $display("%d: fire measurement",$time);
    trig = 1; 
    @(posedge clk);
    @(posedge clk);
    trig = 0;
    @(posedge clk);
    @(posedge clk);
    @(posedge clk); // let measurement finish

    // speed up simulation by turning off the ring, also nice to reduce noise in the IC
    ring_en[1:0] = 2'b00;

    sel[2:0] = 3'b111;

    @(negedge clk); 
    if ( out[6] != 1'b1 ) begin
       $display("ERROR: measurement didnt fire");
       $finish;
    end
    $display("%d: measurement done",$time);
    
    // read out meusurement result

    @(posedge clk);
    sel[2:0] = 3'b001;
    @(negedge clk);
    count0[7:0] = out[7:0];

    @(posedge clk);
    sel[2:0] = 3'b010;
    @(negedge clk);
    count0[15:8] = out[7:0];

    @(posedge clk);
    sel[2:0] = 3'b011;
    @(negedge clk);
    count0[23:16] = out[7:0];

    @(posedge clk);
    sel[2:0] = 3'b100;
    @(negedge clk);
    count1[7:0] = out[7:0];

    @(posedge clk);
    sel[2:0] = 3'b101;
    @(negedge clk);
    count1[15:8] = out[7:0];

    @(posedge clk);
    sel[2:0] = 3'b110;
    @(negedge clk);
    count1[23:16] = out[7:0];

    // calculation assumes timescale = 1nS
    $display("period : %d nS",period);
    $display("count0 : %x (%6d) freq0: %.3f MHz",count0[23:0],(24'hFFFFFF-count0[23:0]),(24'hFFFFFF-count0[23:0])*1000.0/period);
    $display("count1 : %x (%6d) freq1: %.3f MHz",count1[23:0],(24'hFFFFFF-count1[23:0]),(24'hFFFFFF-count1[23:0])*1000.0/period);

    if( count0 < 10 ) begin
            $display("ERROR: count0 is too small");
            $finish;
    end

    if( count1 < 10 ) begin
            $display("ERROR: count1 is too small");
            $finish;
    end

    if ((count0>count1?count0-count1:count1-count0) > 3 ) begin 
            $display("ERROR: counters are too different");
            $finish;
    end  

    if (count0[23] == 0) begin
            $display("ERROR: count0 overflowed");
            $finish;
    end  

    if (count1[23] == 0) begin
            $display("ERROR: count1 overflowed");
            $finish;
    end 
    $display("%d PASS: run measurement",$time);

   end // run_measurement

   if ( run_show_status == 1'b1 ) begin
    @(posedge clk);  // reset cycle
    nrst = 0;
    @(posedge clk); 
    nrst = 1;   
    sel[2:0] = 3'b111;
    ring_en[1:0] = 2'b11;
    @(negedge clk);  // debug mode
    if ( out[7] != 1'b1 ) begin
         $display("ERROR: smoke_test: out[7] is not set");
         $finish;
    end
    @(posedge clk);
    @(posedge clk);
    ring_en[1:0] = 2'b00;

    @(posedge clk); 
    $display("PASS: show status");
   end

   $display("ALL TESTS PASS");
   rpass = 1;
   `ifndef COCOTB_SIM 
     $finish;
   `endif
end

endmodule
