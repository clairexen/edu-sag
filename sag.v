//  Educational 8-Bit Sheep-And-Goats (SAG) Verilog reference implementation
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

module sag(input [7:0] di, ci, output [7:0] do);
	wire [7:0] d1, d2, c1, c2, co;
	wire [3:0] t1, t2, t3;

	sagCtrlUnit ctrl_1 (ci, c1, t1, 2'b 00);
	sagCtrlUnit ctrl_2 (c1, c2, t2, 2'b 01);
	sagCtrlUnit ctrl_3 (c2, co, t3, 2'b 11);

	sagDataUnit data_1 (di, d1, t1);
	sagDataUnit data_2 (d1, d2, t2);
	sagDataUnit data_3 (d2, do, t3);
endmodule

module sagCtrlUnit(input [7:0] ci, output [7:0] co, output [3:0] t, input [1:0] sel);
	wire x[7:0]; // prefix xor-sum over ci, partially broken depending on sel
	assign x[0] = ci[0];
	assign x[1] = ci[1] ^ x[0];
	assign x[2] = ci[2] ^ (sel[1] ? 1'b 0 : x[1]);
	assign x[3] = ci[3] ^ x[2];
	assign x[4] = ci[4] ^ (sel[0] ? 1'b 0 : x[3]);
	assign x[5] = ci[5] ^ x[4];
	assign x[6] = ci[6] ^ (sel[1] ? 1'b 0 : x[5]);
	assign x[7] = ci[7] ^ x[6]; // unused ;)

	// butterfly control signals
	assign t[0] = !x[0];
	assign t[1] = !x[2];
	assign t[2] = !x[4];
	assign t[3] = !x[6];

	sagDataUnit unshuffle (ci, co, t);
endmodule

module sagDataUnit(input [7:0] di, output [7:0] do, input [3:0] t);
	wire [7:0] do_shuffled;
	assign do_shuffled[1:0] = t[0] ? {di[0], di[1]} : di[1:0];
	assign do_shuffled[3:2] = t[1] ? {di[2], di[3]} : di[3:2];
	assign do_shuffled[5:4] = t[2] ? {di[4], di[5]} : di[5:4];
	assign do_shuffled[7:6] = t[3] ? {di[6], di[7]} : di[7:6];

	sagUnshuffle unshuffle (do_shuffled, do);
endmodule

module sagUnshuffle(input [7:0] di, output [7:0] do);
	wire [3:0] odds = {di[6], di[4], di[2], di[0]};
	wire [3:0] even = {di[7], di[5], di[3], di[1]};
	assign do = {even, odds};
endmodule
