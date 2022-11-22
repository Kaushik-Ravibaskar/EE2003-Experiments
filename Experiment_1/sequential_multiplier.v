// Description     : Sequential Multiplier
// Author          : Kaushik Ravibaskar

`define width 8
`define ctrwidth 4

module seq_mult (
		// Outputs
		p, done, 
		// Inputs
		clk, start, a, b
		) ;
	input 		 clk, start;
	input [`width-1:0] 	 a, b;
	output [2*`width-1:0] p;
	output 		 done;
   
	reg [2*`width-1:0] p;
	reg 			 done;
	reg [2*`width-1:0] multiplicand;
	reg [`width-1:0] multiplier;
	reg [`ctrwidth-1:0] 	 ctr;

	always @(posedge clk)
		if (start) begin
			done 			<= 0;
			p 				<= 0;
			ctr 			<= 0;
			multiplicand <= {{`width{a[`width-1]}}, a};
			multiplier <= b;
			
			if(b[`width-1]) begin
			    multiplicand <= ~({{`width{a[`width-1]}}, a}) + 1;
			    multiplier <= ~b + 1;
			end
			else begin
			    multiplicand <= {{`width{a[`width-1]}}, a};
			    multiplier <= b;
			end
			
     	end else begin 
			if (ctr < `width) 
	  		begin
	     		if(multiplier[ctr]) begin
	     		    p <= p + (multiplicand << ctr);
	     		    ctr <= ctr + 1;
	     		end
	     		else begin
	     		    p <= p;
	     		    ctr <= ctr + 1;
	     		end
	  		end else begin
	     		done <= 1;
	  		end
     	end
   
endmodule // seqmult
