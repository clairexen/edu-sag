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
	wire din_mode = 0;
	wire [3:0] decoder_s1, decoder_s2, decoder_s4;
	wire [3:0] decoder_s8, decoder_s16, decoder_s32;
	wire [7:0] decoder_sum;

	pext_decoder decoder (
		.mask  (ci   ),
		.s1    (decoder_s1 ),
		.s2    (decoder_s2 ),
		.s4    (decoder_s4 ),
		.s8    (decoder_s8 ),
		.s16   (decoder_s16),
		.s32   (decoder_s32),
		.sum   (decoder_sum)
	);

	wire [7:0] result_fwd;
	wire [7:0] result_bwd;

	pext_butterfly_fwd butterfly_fwd (
		.din  (di   ),
		.s1   (~decoder_s1 ),
		.s2   (~decoder_s2 ),
		.s4   (~decoder_s4 ),
		.s8   (~decoder_s8 ),
		.s16  (~decoder_s16),
		.s32  (~decoder_s32),
		.dout (result_fwd  )
	);

	pext_butterfly_bwd butterfly_bwd (
		.din  (di & ci),
		.s1   (~decoder_s1 ),
		.s2   (~decoder_s2 ),
		.s4   (~decoder_s4 ),
		.s8   (~decoder_s8 ),
		.s16  (~decoder_s16),
		.s32  (~decoder_s32),
		.dout (result_bwd  )
	);

	assign do = din_mode ? (result_fwd & ci) : result_bwd;
endmodule

// ========================================================================

module pext_lrotcz #(
	parameter integer N = 1,
	parameter integer M = 1
) (
	input [7:0] din,
	output [M-1:0] dout
);
	wire [2*M-1:0] mask = {M{1'b1}};
	assign dout = (mask << din[N-1:0]) >> M;
endmodule

module pext_decoder (
	input clock,
	input enable,
	input [7:0] mask,
	output [3:0] s1, s2, s4, s8, s16, s32,
	output [7:0] sum
);
	wire [63:0] ppsdata;

	assign sum = ppsdata[8*7 +: 8];

	pext_pps8 pps_core (
		.din  (mask),
		.dout (ppsdata)
	);

	genvar i;
	generate
		for (i = 0; i < 8/2; i = i+1) begin:stage1
			pext_lrotcz #(.N(1), .M(1)) lrotc_zero (
				.din(ppsdata[8*(2*i + 1 - 1) +: 8]),
				.dout(s1[i])
			);
		end

		for (i = 0; i < 8/4; i = i+1) begin:stage2
			pext_lrotcz #(.N(2), .M(2)) lrotc_zero (
				.din(ppsdata[8*(4*i + 2 - 1) +: 8]),
				.dout(s2[2*i +: 2])
			);
		end

		for (i = 0; i < 8/8; i = i+1) begin:stage4
			pext_lrotcz #(.N(3), .M(4)) lrotc_zero (
				.din(ppsdata[8*(8*i + 4 - 1) +: 8]),
				.dout(s4[4*i +: 4])
			);
		end
	endgenerate
endmodule

`define pext_butterfly_idx_a(k, i) ((2 << (k))*((i)/(1 << (k))) + (i)%(1 << (k)))
`define pext_butterfly_idx_b(k, i) (`pext_butterfly_idx_a(k, i) + (1<<(k)))

module pext_butterfly_fwd (
	input [7:0] din,
	input [3:0] s1, s2, s4, s8, s16, s32,
	output [7:0] dout
);
	reg [7:0] butterfly;
	assign dout = butterfly;

	integer k, i;
	always @* begin
		butterfly = din;

		for (i = 0; i < 4; i = i+1)
			if (s4[i]) {butterfly[`pext_butterfly_idx_a(2, i)], butterfly[`pext_butterfly_idx_b(2, i)]} =
						{butterfly[`pext_butterfly_idx_b(2, i)], butterfly[`pext_butterfly_idx_a(2, i)]};

		for (i = 0; i < 4; i = i+1)
			if (s2[i]) {butterfly[`pext_butterfly_idx_a(1, i)], butterfly[`pext_butterfly_idx_b(1, i)]} =
						{butterfly[`pext_butterfly_idx_b(1, i)], butterfly[`pext_butterfly_idx_a(1, i)]};

		for (i = 0; i < 4; i = i+1)
			if (s1[i]) {butterfly[`pext_butterfly_idx_a(0, i)], butterfly[`pext_butterfly_idx_b(0, i)]} =
						{butterfly[`pext_butterfly_idx_b(0, i)], butterfly[`pext_butterfly_idx_a(0, i)]};
	end
endmodule

module pext_butterfly_bwd (
	input [7:0] din,
	input [3:0] s1, s2, s4, s8, s16, s32,
	output [7:0] dout
);
	reg [7:0] butterfly;
	assign dout = butterfly;

	integer k, i;
	always @* begin
		butterfly = din;

		for (i = 0; i < 4; i = i+1)
			if (s1[i]) {butterfly[`pext_butterfly_idx_a(0, i)], butterfly[`pext_butterfly_idx_b(0, i)]} =
						{butterfly[`pext_butterfly_idx_b(0, i)], butterfly[`pext_butterfly_idx_a(0, i)]};

		for (i = 0; i < 4; i = i+1)
			if (s2[i]) {butterfly[`pext_butterfly_idx_a(1, i)], butterfly[`pext_butterfly_idx_b(1, i)]} =
						{butterfly[`pext_butterfly_idx_b(1, i)], butterfly[`pext_butterfly_idx_a(1, i)]};

		for (i = 0; i < 4; i = i+1)
			if (s4[i]) {butterfly[`pext_butterfly_idx_a(2, i)], butterfly[`pext_butterfly_idx_b(2, i)]} =
						{butterfly[`pext_butterfly_idx_b(2, i)], butterfly[`pext_butterfly_idx_a(2, i)]};
	end
endmodule

module pext_pps8 (
  input [7:0] din,
  output [63:0] dout
);
  assign dout[0 +: 8] = {15'b0, din[0 +: 1]};
  assign dout[8 +: 8] = {15'b0, din[1 +: 1]} + dout[0 +: 8];
  assign dout[16 +: 8] = {15'b0, din[2 +: 1]} + dout[8 +: 8];
  assign dout[24 +: 8] = {15'b0, din[3 +: 1]} + dout[16 +: 8];
  assign dout[32 +: 8] = {15'b0, din[4 +: 1]} + dout[24 +: 8];
  assign dout[40 +: 8] = {15'b0, din[5 +: 1]} + dout[32 +: 8];
  assign dout[48 +: 8] = {15'b0, din[6 +: 1]} + dout[40 +: 8];
  assign dout[56 +: 8] = {15'b0, din[7 +: 1]} + dout[48 +: 8];
endmodule
