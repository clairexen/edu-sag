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

// parametric version of a core capable of SAG, NR-SAG, INV-SAG, and INV-NR-SAG
module paramNrInvSag #(
	parameter integer LOG2N = 3,
	parameter integer FORCE_NR = -1,
	parameter integer FORCE_INV = -1,
	parameter integer N = 1 << LOG2N
) (input [N-1:0] di, ci, input en_nr, input en_inv, input trace, output [N-1:0] do);
	wire ctrl_nr = FORCE_NR >= 0 ? FORCE_NR : en_nr;
	wire ctrl_inv = FORCE_INV >= 0 ? FORCE_INV : en_inv;

	function [N-1:0] shuffle;
		input [N-1:0] din;
		integer i;
		begin
			for (i = 0; i < (N>>1); i = i+1) begin
				shuffle[2*i + 1] = din[i + (N>>1)];
				shuffle[2*i] = din[i];
			end
		end
	endfunction

	function [N-1:0] unshuffle;
		input [N-1:0] din;
		integer i;
		begin
			for (i = 0; i < (N>>1); i = i+1) begin
				unshuffle[i + (N>>1)] = din[2*i + 1];
				unshuffle[i] = din[2*i];
			end
		end
	endfunction

	function [N-1:0] mask_by_stage;
		input [2:0] stage;
		reg [N-1:0] tmp;
		integer i;
		begin
			mask_by_stage = {N{2'b1}};
			for (i = 1; i < LOG2N-stage; i = i+1) begin
				mask_by_stage = shuffle({{N>>1{1'b0}}, mask_by_stage[(N>>1)-1:0]});
			end
		end
	endfunction

	function [(N>>1)-1:0] select_parity_by_stage;
		input [(N>>1)-1:0] x;
		input [2:0] stage;
		integer i, j;
		begin
			select_parity_by_stage = x;
			for (i = stage+1; i < LOG2N; i = i+1) begin
				for (j = (N>>(i+1)); j < (N>>1); j = j+2*(N>>(i+1)))
					select_parity_by_stage[j-1] = select_parity_by_stage[j+(N>>(i+1))-1];
			end
		end
	endfunction

	function [N-1:0] masked_prefix_xorsum;
		input [N-1:0] din, mask;
		integer i;
		reg carry;
		begin
			carry = 0;
			for (i = 0; i < N; i = i+1) begin
				carry = din[i] ^ (carry & !mask[i]);
				masked_prefix_xorsum[i] = carry;
			end
		end
	endfunction

	function [N-1:0] bfly;
		input [N-1:0] din;
		input [(N>>1)-1:0] cin;
		integer i;
		begin
			for (i = 0; i < (N>>1); i = i+1)
				bfly[2*i +: 2]  = cin[i] ? {din[2*i], din[2*i + 1]} : din[2*i +: 2];
		end
	endfunction

	integer i, k;
	reg [N-1:0] x, d, c, m;
	reg [(N>>1)-1:0] t, l;

	reg [LOG2N*N-1:0] p;
	reg [LOG2N*N-1:0] b;
	reg [LOG2N*N-1:0] b_inv;

	always @* begin
		// if (trace) $display("");
		// if (trace) $display("<%m>");
		// if (trace) $display("%3t di=%b, ci=%b", $time, di, ci);

		// Control Logic
		c = ci;
		for (k = 0; k < LOG2N; k = k+1) begin
			m = mask_by_stage(k);
			x = masked_prefix_xorsum(c, m);
			{l, t} = ~unshuffle(x);
			l = select_parity_by_stage(~l, k);
			p = {p, l};
			c = unshuffle(bfly(c, t));
			b = {b, t};
		end
		for (k = 0; k < LOG2N; k = k+1) begin
			{p, l} = p;
			t = ctrl_nr ? ~l & ~c : 0;
			c = shuffle(c);
		`ifdef MERGE_CENTER_BFLY_STAGES
			if (k == 0) begin
				b = {b ^ t, {N>>1{1'b0}}};
			end else begin
				b = {b, t};
			end
		`else
			b = {b, t};
		`endif
		end

		// Extra Logic for INV
		for (k = 0; k < 2*LOG2N; k = k+1) begin
			t = b >> k*(N>>1);
			b_inv = {b_inv, t};
		end
		b = ctrl_inv ? b_inv : b;

		// Data Path
		d = di;
		// if (trace) $display("");
		for (k = 0; k < LOG2N; k = k+1) begin
			// if (trace) $display("-- Data Path Stage %1d --", k);
			{t, b} = {b, {N>>1{1'b0}}};
			d = unshuffle(bfly(d, t));
			// if (trace) $display("    b=%x (t=%x) -> d=%b", b, t, d);
		end
		// if (trace) $display("");
		for (k = 0; k < LOG2N; k = k+1) begin
			// if (trace) $display("-- Data Path Stage %1d --", LOG2N+k);
			{t, b} = {b, {N>>1{1'b0}}};
			d = bfly(shuffle(d), t);
			// if (trace) $display("    b=%x (t=%x) -> d=%b", b, t, d);
		end
		// if (trace) $display("");
		// if (trace) $display("%3t di=%b, ci=%b -> do=%b", $time, di, ci, d);
		// if (trace) $display("</%m>");
		// if (trace) $display("");
	end

	assign do = d;
endmodule

`ifndef SYNTHESIS
module top;
	localparam LOG2N = 6;
	localparam integer N = 1 << LOG2N;

	// sim length
	localparam ROUNDS = 500;

	function [N-1:0] sagRef;
		input [N-1:0] di, ci;
		integer i, j, k;
		begin
			j = 0; k = N-1;
			for (i = 0; i < N; i = i+1) begin
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

	function [N-1:0] nsagRef;
		input [N-1:0] di, ci;
		begin
			nsagRef = sagRef(sagRef(di, ci), sagRef(ci, ci));
		end
	endfunction

	reg [N-1:0] di, ci, next_di, next_ci;
	wire [N-1:0] do_sag, do_isag, do_nsag, do_insag;
	paramNrInvSag #(LOG2N)
		uut_sag   (di,      ci, 1'b0, 1'b0, 1'b0, do_sag),
		uut_isag  (do_sag,  ci, 1'b0, 1'b1, 1'b0, do_isag),
		uut_nsag  (di,      ci, 1'b1, 1'b0, 1'b0, do_nsag),
		uut_insag (do_nsag, ci, 1'b1, 1'b1, 1'b0, do_insag);
	
	wire [N-1:0] ref_sag = sagRef(di, ci);
	wire [N-1:0] ref_nsag = nsagRef(di, ci);
	
	reg [63:0] rngState = 64'd 88172645463325252;
	task xorshift;
		begin
			rngState = rngState ^ (rngState << 13);
			rngState = rngState ^ (rngState >>  7);
			rngState = rngState ^ (rngState << 17);
		end
	endtask

	integer round = 0;
	integer errors = 0;
	
	initial repeat (ROUNDS) begin
		#5;
		repeat (7) xorshift;
		di = rngState;
		repeat (7) xorshift;
		ci = rngState;
		#5;

		$display("round %4d @ %5t: di=%b, ci=%b", round, $time, di, ci);
		if (do_sag !== ref_sag) begin
			$display("ERROR: do_sag (%x) != ref_sag (%x))", do_sag, ref_sag);
			errors = errors + 1;
		end
		if (do_isag !== di) begin
			$display("ERROR: do_isag (%x) != di (%x))", do_isag, di);
			errors = errors + 1;
		end
		if (do_nsag !== ref_nsag) begin
			$display("ERROR: do_nsag (%x) != ref_nsag (%x))", do_nsag, ref_nsag);
			errors = errors + 1;
		end
		if (do_insag !== di) begin
			$display("ERROR: do_insag (%x) != di (%x))", do_insag, di);
			errors = errors + 1;
		end

		if (errors) begin
			$display("%1d erros in round %1d", errors, round);
			$stop;
		end

		round = round + 1;
	end
endmodule
`endif
