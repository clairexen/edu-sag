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

// This file is based on an older PEXT reference implementation that I wrote
// almost a decade ago. TBD: Clean up this mess..

// ========================================================================

module pext (input [7:0] di, ci, output [7:0] do);
	wire [3:0] s1, s2, s4;

	pext_decoder decoder (ci, s1, s2, s4);
	pext_ibfly ibfly (di&ci, s1, s2, s4, do);
endmodule

// ========================================================================

module pext_ibfly (input [7:0] di, input [3:0] s1, s2, s4, output [7:0] do);
	wire [7:0] d1, d2;

	// bfly stage 1
	assign {d1[1], d1[0]} = s1[0] ? {di[1], di[0]} : {di[0], di[1]};
	assign {d1[3], d1[2]} = s1[1] ? {di[3], di[2]} : {di[2], di[3]};
	assign {d1[5], d1[4]} = s1[2] ? {di[5], di[4]} : {di[4], di[5]};
	assign {d1[7], d1[6]} = s1[3] ? {di[7], di[6]} : {di[6], di[7]};

	// bfly stage 2
	assign {d2[2], d2[0]} = s2[0] ? {d1[2], d1[0]} : {d1[0], d1[2]};
	assign {d2[3], d2[1]} = s2[1] ? {d1[3], d1[1]} : {d1[1], d1[3]};
	assign {d2[6], d2[4]} = s2[2] ? {d1[6], d1[4]} : {d1[4], d1[6]};
	assign {d2[7], d2[5]} = s2[3] ? {d1[7], d1[5]} : {d1[5], d1[7]};

	// bfly stage 3
	assign {do[4], do[0]} = s4[0] ? {d2[4], d2[0]} : {d2[0], d2[4]};
	assign {do[5], do[1]} = s4[1] ? {d2[5], d2[1]} : {d2[1], d2[5]};
	assign {do[6], do[2]} = s4[2] ? {d2[6], d2[2]} : {d2[2], d2[6]};
	assign {do[7], do[3]} = s4[3] ? {d2[7], d2[3]} : {d2[3], d2[7]};
endmodule

module pext_decoder (
	input [7:0] mask,
	output [3:0] s1, s2, s4
);
	wire [2:0] sum0 = mask[0];
	wire [2:0] sum1 = sum0 + mask[1];
	wire [2:0] sum2 = sum1 + mask[2];
	wire [2:0] sum3 = sum2 + mask[3];
	wire [2:0] sum4 = sum3 + mask[4];
	wire [2:0] sum5 = sum4 + mask[5];
	wire [2:0] sum6 = sum5 + mask[6];

	// decoder stage 1
	pext_lrotcz #(.N(1), .M(1)) lrotcz_0_0 (sum0, s1[0]);
	pext_lrotcz #(.N(1), .M(1)) lrotcz_0_1 (sum2, s1[1]);
	pext_lrotcz #(.N(1), .M(1)) lrotcz_0_2 (sum4, s1[2]);
	pext_lrotcz #(.N(1), .M(1)) lrotcz_0_3 (sum6, s1[3]);

	// decoder stage 2
	pext_lrotcz #(.N(2), .M(2)) lrotcz_1_0 (sum1, s2[2*0 +: 2]);
	pext_lrotcz #(.N(2), .M(2)) lrotcz_1_1 (sum5, s2[2*1 +: 2]);

	// decoder stage 3
	pext_lrotcz #(.N(3), .M(4)) lrotcz_2_0 (sum3, s4[4*0 +: 4]);
endmodule

module pext_lrotcz #(
	parameter integer N = 1,
	parameter integer M = 1
) (
	input [7:0] di,
	output [M-1:0] do
);
	wire [2*M-1:0] mask = {M{1'b1}};
	assign do = (mask << di[N-1:0]) >> M;
endmodule
