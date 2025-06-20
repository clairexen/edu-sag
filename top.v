//  Educational 8-Bit Sheep-And-Goats (SAG) Verilog Reference IP
//
//  Copyright (C) 2025  Claire Xenia Wolf <claire@clairexen.net>
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

	function [7:0] nrsagRef;
		input [7:0] di, ci;
		begin
			nrsagRef = sagRef(sagRef(di, ci), sagRef(ci, ci));
		end
	endfunction

	reg [7:0] di = 0, ci = 0;
	wire [7:0] doSag, doNrsag, doNrsag2;

	sag sag_uut (di, ci, doSag);
	nrsag nrsag_uut (di, ci, doNrsag);
	nrsag2 nrsag2_uut (di, ci, doNrsag2);

	wire [7:0] doSagRef = sagRef(di, ci);
	wire [7:0] doNrsagRef = nrsagRef(di, ci);

	wire ok = doSag === doSagRef && doNrsag === doNrsagRef && doNrsag2 === doNrsagRef;
	integer errcnt = 0;

	always begin
		#1;
		if (!di) begin
			$display("   di       ci    |    co    |   sag     sagref  |  nrsag    nrsag2  nrsagref |");
			$display("------------------+----------+-------------------+----------------------------+");
		end
		$display("%b %b | %b | %b %b | %b %b %b | %s", di, ci, nrsag_uut.co,
				doSag, doSagRef, doNrsag, doNrsag2, doNrsagRef, ok ? "OK" : "ERROR");
		errcnt = errcnt + !ok;
		{ci,di} = {ci,di} + 1;
		if (!di) begin
			$display({79{"-"}});
			if (errcnt) begin
				$display("Number of failed tests for ci=%b: %3d", ci - 8'b1, errcnt);
				$stop;
			end
			if (!ci) begin
				$display("ALL TESTS PASSED");
				$finish;
			end
		end
	end
endmodule
