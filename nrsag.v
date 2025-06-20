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

// This is a copy of sag.v with the neccessary changes applied to
// perform a non-reflecting Sheep-And-Goats operation. this is the "best"
// method of doing that in a single cycle, that I am aware of, and it still
// has almost the same area as just instantiating the sag() core twice,
// as demonstrated in nrsag2.v, at least for an 8-bit unit.
//
// However, everything in the SAG unit scales with about N*log(N) wrt the number
// of data bits, except the (upper) control unit, which is worse. So for cores
// with a larger bit width this approach, which avoids paying for two times the
// area of the (upper) control units, is an interesting alternative to explore.
// Especially if your design already contains the 2nd mirrored butterfly stage
// for implementing inverse-sag.
module nrsag(input [7:0] di, ci, output [7:0] do); // 12 NOT, 12 NOR, 22 XOR, 64 MUX
	wire [7:0] d1, d2, d3, d4, d5, c1, c2, c3, c4, c5, co;
	wire [3:0] b1, b2, b3, b4, b5, b6, p1, p2, p3;

	nrsagUpperCtrlUnit ctrl_1 (ci, c1, b1, p1, 2'b 00); // 4 NOT, 8 XOR, 8 MUX
	nrsagUpperCtrlUnit ctrl_2 (c1, c2, b2, p2, 2'b 10); // 4 NOT, 6 XOR, 8 MUX
	nrsagUpperCtrlUnit ctrl_3 (c2, c3, b3, p3, 2'b 11); // 4 NOT, 4 XOR, 8 MUX

	nrsagLowerCtrlUnit ctrl_4 (c3, c4, b4, p3); // 3 x 4 = 12 NOR
	nrsagLowerCtrlUnit ctrl_5 (c4, c5, b5, p2);
	nrsagLowerCtrlUnit ctrl_6 (c5, co, b6, p1);

	nrsagUpperDataUnit data_bfly_1 (di, d1, b1); // 3 x 8 = 24 MUX
	nrsagUpperDataUnit data_bfly_2 (d1, d2, b2);
	//nrsagUpperDataUnit data_bfly_3 (d2, d3, b3);
	nrsagUpperDataUnit data_bfly_3 (d2, d3, b3 ^ b4); // + 4 XOR

	// nrsagLowerDataUnit data_bfly_4 (d3, d4, b4);
	nrsagShuffle shuffle (d3, d4);

	nrsagLowerDataUnit data_bfly_5 (d4, d5, b5); // 2 x 8 = 16 MUX
	nrsagLowerDataUnit data_bfly_6 (d5, do, b6);
endmodule

module nrsagUpperCtrlUnit(input [7:0] ci, output [7:0] co, output [3:0] b, output [3:0] p, input [1:0] sel);
	wire x[7:0]; // prefix xor-sum over ci, partially broken depending on sel
	assign x[0] = ci[0];
	assign x[1] = ci[1] ^ x[0];
	assign x[2] = ci[2] ^ (sel[0] ? 1'b 0 : x[1]);
	assign x[3] = ci[3] ^ x[2];
	assign x[4] = ci[4] ^ (sel[1] ? 1'b 0 : x[3]);
	assign x[5] = ci[5] ^ x[4];
	assign x[6] = ci[6] ^ (sel[0] ? 1'b 0 : x[5]);
	assign x[7] = ci[7] ^ x[6];

	// butterfly control signals
	assign b[0] = !x[0];
	assign b[1] = !x[2];
	assign b[2] = !x[4];
	assign b[3] = !x[6];

	// parity output for lower bfly control circuit
	assign p[0] = sel[0] ? x[1] : p[1];
	assign p[1] = sel[1] ? x[3] : p[3];
	assign p[2] = sel[0] ? x[5] : p[3];
	assign p[3] = x[7];

	nrsagUpperDataUnit ctrl_bfly (ci, co, b);
endmodule

module nrsagUpperDataUnit(input [7:0] di, output [7:0] do, input [3:0] b);
	wire [7:0] do_shuffled;
	assign do_shuffled[1:0] = b[0] ? {di[0], di[1]} : di[1:0];
	assign do_shuffled[3:2] = b[1] ? {di[2], di[3]} : di[3:2];
	assign do_shuffled[5:4] = b[2] ? {di[4], di[5]} : di[5:4];
	assign do_shuffled[7:6] = b[3] ? {di[6], di[7]} : di[7:6];

	nrsagUnshuffle unshuffle (do_shuffled, do);
endmodule

module nrsagUnshuffle(input [7:0] di, output [7:0] do);
	wire [3:0] even = {di[6], di[4], di[2], di[0]};
	wire [3:0] odds = {di[7], di[5], di[3], di[1]};
	assign do = {odds, even};
endmodule

module nrsagLowerCtrlUnit(input [7:0] ci, output [7:0] co, output [3:0] b, input [3:0] p);
	assign b[0] = !p[0] & !ci[0];
	assign b[1] = !p[1] & !ci[1];
	assign b[2] = !p[2] & !ci[2];
	assign b[3] = !p[3] & !ci[3];

	nrsagShuffle shuffle (ci, co);
endmodule

module nrsagLowerDataUnit(input [7:0] di, output [7:0] do, input [3:0] b);
	wire [7:0] di_shuffled;
	nrsagShuffle shuffle (di, di_shuffled);
	assign do[1:0] = b[0] ? {di_shuffled[0], di_shuffled[1]} : di_shuffled[1:0];
	assign do[3:2] = b[1] ? {di_shuffled[2], di_shuffled[3]} : di_shuffled[3:2];
	assign do[5:4] = b[2] ? {di_shuffled[4], di_shuffled[5]} : di_shuffled[5:4];
	assign do[7:6] = b[3] ? {di_shuffled[6], di_shuffled[7]} : di_shuffled[7:6];
endmodule

module nrsagShuffle(input [7:0] di, output [7:0] do);
	assign do = {di[7], di[3], di[6], di[2], di[5], di[1], di[4], di[0]};
endmodule
