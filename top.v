//  Educational 8-Bit Sheep-And-Goats (SAG) Verilog Reference IP
//
//  Copyright (C) 2012  Claire Xenia Wolf <claire@clairexen.net>
//
//  Permission to use, copy, modify, and/or distribute this software for any
//  purpose with or without fee is hereby granted, provided that the above
//  copyright notice and this permission notice appear in all copies.
//
//  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
//  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
//  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
//  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
//  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
//  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

module top;
	function [7:0] sagRef;
		input [7:0] di, ci;
		integer i, j, k;
		begin
			j = 0; k = 7;
			for (i = 0; i < 8; i = i+1) begin
				if (i == 7) begin
					// fun fact: the SAG MSB control bit doesn't really do anything
					if (j != k) begin $display("ASSERT FAILED"); $stop; end
				end
				if (ci[i]) begin
					sagRef[j] = di[i];
					j = j+1;
				end else begin
					sagRef[k] = di[i];
					k = k-1;
				end
			end
		end
	endfunction

	integer errcnt = 0;
	reg [7:0] di = 0, ci = 0;
	wire [7:0] doRef = sagRef(di, ci);
	wire [7:0] do;

	sag uut (di, ci, do);

	always begin
		#1;
		$display("%b %b | %b | %b %b %s", di, ci,
				uut.co, do, doRef, do == doRef ? "OK" : "ERROR");
		errcnt = errcnt + (do != doRef);
		{ci,di} = {ci,di} + 1;
		if (!di) $display({60{"-"}});
		if (!di && !ci) begin
			if (errcnt) begin
				$display("Number of failed tests: %d", errcnt);
				$stop;
			end else begin
				$display("ALL TESTS PASSED");
				$finish;
			end
		end
	end
endmodule
