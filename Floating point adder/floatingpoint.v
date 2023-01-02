`timescale 1ns/1ns
module fpadd (
clk, reset, start,
    a, b,
    sum, 
    done
);
    input clk, reset, start;
    input [31:0] a, b;
    output [31:0] sum;
    output done;
    reg done;
    reg [31:0] sum;
    reg [2: 0] state, next_state;
    reg status;
    parameter S0 = 3'b000, S1 = 3'b001, S2 = 3'b010, S3 = 3'b011 ,S4 = 3'b100 ,S5 = 3'b101, S6 = 3'b110, S7 = 3'b111;  //states used in fsm
  

reg sign_a_q ,sign_b_q;
reg [7:0] exp_a_q;
reg [7:0] exp_b_q ;
reg signed [25:0] mant_a_q;
reg signed [25:0] mant_b_q;   
integer ediff;  

reg sign_r_q;
reg [7:0] exp_r_q;
reg [25:0] mant_r_q;

reg sign_a_d ,sign_b_d;
reg [7:0] exp_a_d;
reg [7:0] exp_b_d;
reg signed [25:0] mant_a_d;
reg signed [25:0] mant_b_d;  
reg [31:0] sum_d;
reg [31:0] sum_q; 
reg done_q,done_d;

reg sign_r_d;
reg [7:0] exp_r_d;
reg [25:0] mant_r_d;
 
  
// initial 
//     begin
//       state[2:0] = S0;      // first state should be zero
//     end
 assign sum = sum_q;
 assign done = done_q;
  
  always @(posedge clk) begin
      if(reset)
	  begin
		state <= S0;
		mant_a_q <= 'd0;
		mant_b_q <= 'd0;
		mant_r_q <= 'd0;
		sign_a_q <= 'd0;
		sign_b_q <= 'd0;
		sign_r_q <= 'd0;
		exp_a_q <= 'd0;
		exp_b_q <= 'd0;
		exp_r_q <= 'd0;
		sum_q <= 'd0;
        done_q  <= 'd0;

	  end
	  else
	  begin
		state <= next_state;
		mant_a_q <= mant_a_d;
		mant_b_q <= mant_b_d;
		mant_r_q <= mant_r_d;
		sign_a_q <= sign_a_d;
		sign_b_q <= sign_b_d;
		sign_r_q <= sign_r_d;
		exp_a_q <= exp_a_d;
		exp_b_q <= exp_b_d;
		exp_r_q <= exp_r_d;
		sum_q <= sum_d;
        done_q <= done_d;
	  end
  end

  always @(*) begin
       next_state = state;
	   mant_a_d = mant_a_q;
	   mant_b_d = mant_b_q;
	   mant_r_d = mant_r_q;
	   sign_a_d = sign_a_q;
	   sign_b_d = sign_b_q;
	   sign_r_d = sign_r_q;
	   exp_a_d = exp_a_q;
	   exp_b_d = exp_b_q;
	   exp_r_d = exp_r_q;
	   sum_d = sum_q;
       done_d = 0;

	   case(state)
	   S0 : 
	   begin
		//done = 0;
		sign_a_d = a[31];

		sign_b_d = b[31] ;

										// Parcing inputs into mantissa , exponent and sign bit
		exp_a_d[7:0] = a[30:23];

		exp_b_d[7:0] = b[30:23];

		mant_a_d[25:0] = {2'b0,1'b1,a[22:0]};  // adding 1 to 24th bit to make 0.23 -> 1.23
		mant_b_d[25:0] ={2'b0,1'b1,b[22:0]};

		sign_r_d = 'd0;
		mant_r_d = 'd0;
		exp_r_d = 'd0;
        
         
         if(start) begin
           next_state = S1;
         end

	   end
	   
	   S1 : begin
		if ((exp_a_q == 0) && (mant_a_q[22:0] == 0)) begin
        sum_d =  b;
        next_state = S7;
        done_d =1;
        end
      else if ((exp_b_q == 0) && (mant_b_q[22:0] == 0)) begin
        sum_d =  a;
        next_state = S7;
        done_d =1;
        end

      else if (exp_a_q[7:0] == 8'b11111111) begin
          sum_d = a; // NaN or inf same behaviour
          next_state = S7;
          done_d =1;
        end
        else if (exp_b_q[7:0] == 8'b11111111) begin
        sum_d = b;
        next_state = S7;
       done_d =1;
        end
      

        else begin
        next_state = S2;
        end
         if (sign_a_q) begin 
            mant_a_d = -mant_a_q; 
            end
         if (sign_b_q) begin
                mant_b_d = -mant_b_q;
            end
         
    end

	 S2: begin
       
        $display("manta = %b",mant_a_q);
       $display("mantb = %b",mant_b_q);
//        if (a[31]) begin 
//             mant_a_d = -mant_a_q; 
//             end
//        if (b[31]) begin
//                 mant_b_d = -mant_b_q;
//             end

            
            if (exp_a_q > exp_b_q) begin
            ediff = exp_a_q - exp_b_q;
            exp_r_d = exp_a_q;
              mant_b_d = mant_b_q >>> ediff;
            end 
            else if (exp_a_q < exp_b_q) begin
            ediff = exp_b_q - exp_a_q;
            exp_r_d = exp_b_q;
              mant_a_d = mant_a_q >>> ediff;
            end 
            else begin
            exp_r_d = exp_a_q; 
            end

			next_state = S3;
	 end

		S3 : begin

			mant_r_d = mant_a_q + mant_b_q; //mantissa addition
          $display("manta = %b",mant_a_q);
          $display("mantb = %b",mant_b_q);
          $display("        %b",mant_r_d);
          next_state = S4;
        end
         
         S4: begin

          if (mant_r_q[25]==1) begin
                sign_r_d = 1; 
            mant_r_d = -mant_r_q;

            end 
            else begin
                sign_r_d = 0;
              
                end

          next_state = S5;
			          $display("        %b",mant_r_d);

                 $display("reached s3");

        end	 


		S5 : begin
          
          
          if (mant_r_q[22:0] == 0) begin
                    // if they both cancel out
                    exp_r_d = 0;
                    next_state = S6;
            $display("zero");

                end
          else if ((mant_r_q[24] == 0) && (mant_r_q[23] == 1) ) begin
                    
                    next_state = S6;
                    $display("no normalisation needed");
                 end
          else if (mant_r_q[24] == 1) begin
                    // Overflow condition
            mant_r_d = mant_r_q >> 1;
                    exp_r_d = exp_r_q +1;
                    next_state = S6;
            $display("no normalisation needed overflow");

                  end

          
           else begin
             if (mant_r_q[23] == 1) begin

                    next_state = S6;
                end
                else begin
                    mant_r_d = mant_r_q << 1;
                    exp_r_d = exp_r_q - 1;  //shifiting mantissa till mant_r[23] ==1
                  
                    //next_state = S4;

                end
           end
        end

		S6 : begin
			done_d =1; //testbench loop ends
            sum_d = {sign_r_q,exp_r_q[7:0],mant_r_q[22:0]};


          $display("reached s6");
               next_state = S7;
        end

		S7 :begin   // wait till start enabled
          if(start == 0) begin
            next_state = S0;
          done_d = 1;
          end
        end
          default:
                      next_state = S0;
    endcase
  end


endmodule // seqmult9