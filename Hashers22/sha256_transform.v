/*
* MJ 06-Jan-2013 ... hashers22
* Homegrown version with 22 hashers. Removed shifter code (for the moment) for clarity as
* these were not used at LOG_LOOP2=3 (which is now ignored as its manually configured)
* We hardcode parameters LOOP=3 and NUM_HASHERS=22 giving 66 which is 2 in excess of
* the 64 required, so need to take tx_hash output from the 20th stage.
*
* Based loosely on Open-Source-FPGA-Bitcoin-Miner-refs_heads_de0-nano-hax-afpgabm\src
*
* Copyright (c) 2011 fpgaminer@bitcoin-mining.com
* Copyright (c) 2011 Aidan Thornton <makosoft@gmail.com>
*
*
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
* 
*/

`timescale 1ns/1ps

// A quick define to help index 32-bit words inside a larger register.
`define IDX(x) (((x)+1)*(32)-1):((x)*(32))


// Perform a SHA-256 transformation on the given 512-bit data, and 256-bit initial state

module sha256_transform #(
	parameter LOOP = 3,
	parameter NUM_HASHERS = 22
) (
	input clk,
	input feedback,
	input [1:0] cnt,
	input [255:0] rx_state,
	input [511:0] rx_input,
	output reg [255:0] tx_hash
);

	// Constants defined by the SHA-2 standard.
	localparam Ks = {
		32'h428a2f98, 32'h71374491, 32'hb5c0fbcf, 32'he9b5dba5,
		32'h3956c25b, 32'h59f111f1, 32'h923f82a4, 32'hab1c5ed5,
		32'hd807aa98, 32'h12835b01, 32'h243185be, 32'h550c7dc3,
		32'h72be5d74, 32'h80deb1fe, 32'h9bdc06a7, 32'hc19bf174,
		32'he49b69c1, 32'hefbe4786, 32'h0fc19dc6, 32'h240ca1cc,
		32'h2de92c6f, 32'h4a7484aa, 32'h5cb0a9dc, 32'h76f988da,
		32'h983e5152, 32'ha831c66d, 32'hb00327c8, 32'hbf597fc7,
		32'hc6e00bf3, 32'hd5a79147, 32'h06ca6351, 32'h14292967,
		32'h27b70a85, 32'h2e1b2138, 32'h4d2c6dfc, 32'h53380d13,
		32'h650a7354, 32'h766a0abb, 32'h81c2c92e, 32'h92722c85,
		32'ha2bfe8a1, 32'ha81a664b, 32'hc24b8b70, 32'hc76c51a3,
		32'hd192e819, 32'hd6990624, 32'hf40e3585, 32'h106aa070,
		32'h19a4c116, 32'h1e376c08, 32'h2748774c, 32'h34b0bcb5,
		32'h391c0cb3, 32'h4ed8aa4a, 32'h5b9cca4f, 32'h682e6ff3,
		32'h748f82ee, 32'h78a5636f, 32'h84c87814, 32'h8cc70208,
		32'h90befffa, 32'ha4506ceb, 32'hbef9a3f7, 32'hc67178f2};

	genvar i, j;
	
	wire [255:0] state_fb;
	wire [511:0] w_fb;
	wire [31:0] t1_part_fb;
	wire [1:0] cnt_fb;			// Added for hashers22

	reg [255:0] state_first;
	// reg [511:0] rx_input_d;	// Not used here
	reg [31:0] t1_part_first;

	reg [1:0] cnt_fb_d;
	
	wire [31:0] K_0;
	assign K_0 = Ks[32*63 +: 32];
		
	generate
		always @ (posedge clk)
		begin
			state_first <= feedback ? state_fb : rx_state;
			// rx_input_d <= rx_input;	// Not used here
			t1_part_first <= feedback ? t1_part_fb : (rx_state[`IDX(7)] + rx_input[31:0] + K_0);
			cnt_fb_d <= cnt_fb;
		end

		for (i = 0; i < NUM_HASHERS; i = i + 1) begin : HASHERS
			wire [31:0] new_w15;
			wire [255:0] state;
			wire [31:0] K_next;
			wire [31:0] t1_part_next;
			
			reg [1:0] cur_cnt;
							
			if(i == 0)
				always @ (posedge clk)
				// Hashers22 ... fudge to get correct cnt on feedback ... cnt is 0 on first loop,
				// then 1 for first feedback and 2 on second (final) feedback, but we need the input
				// value of the hasher, so delay by 1.
				cur_cnt <= feedback ? cnt_fb_d + 2'd1 : cnt;
			else
				always @ (posedge clk)
					cur_cnt <= HASHERS[i-1].cur_cnt;

			wire [31:0] K_next_tbl[0:LOOP-1];
			for (j = 0; j < LOOP; j = j + 1) begin : K_NEXT_TBL_INIT
				localparam k_next_idx = ((NUM_HASHERS)*j + i + 1)&63;
				assign K_next_tbl[j] = Ks[32*(63-k_next_idx) +: 32];
			end
			assign K_next = K_next_tbl[cur_cnt];

			wire [31:0] cur_w0, cur_w1, cur_w9, cur_w14;
			reg [479:0] new_w14to0;

			begin
				wire[511:0] cur_w;
				if(i == 0)
				begin
					reg [511:0] w_reg;
					always @ (posedge clk)
						w_reg <= feedback ? w_fb : rx_input;
					assign cur_w = w_reg;
				end
				else
					assign cur_w = {HASHERS[i-1].new_w15, HASHERS[i-1].new_w14to0 };
					
				assign cur_w0 = cur_w[31:0];
				assign cur_w1 = cur_w[63:32];
				assign cur_w9 = cur_w[319:288];
				assign cur_w14 = cur_w[479:448];
				
				always @ (posedge clk)
					new_w14to0 <= cur_w[511:32];
			end

			if(i == 0)
				sha256_digester U (
					.clk(clk),
					.k_next(K_next),
					.rx_state(state_first),
					.rx_t1_part(t1_part_first),
					.rx_w1(cur_w1),
					.tx_state(state),
					.tx_t1_part(t1_part_next)
				);
			else
				sha256_digester U (
					.clk(clk),
					.k_next(K_next),
					.rx_state(HASHERS[i-1].state),
					.rx_t1_part(HASHERS[i-1].t1_part_next),
					.rx_w1(cur_w1),
					.tx_state(state),
					.tx_t1_part(t1_part_next)
				);
			sha256_update_w upd_w (
				.clk(clk),
				.rx_w0(cur_w0),
				.rx_w1(cur_w1),
				.rx_w9(cur_w9),
				.rx_w14(cur_w14),
				.tx_w15(new_w15)
			);
		end

		begin
			assign state_fb = HASHERS[NUM_HASHERS-6'd1].state;
			assign w_fb = {HASHERS[NUM_HASHERS-6'd1].new_w15, HASHERS[NUM_HASHERS-6'd1].new_w14to0};
			assign t1_part_fb = HASHERS[NUM_HASHERS-6'd1].t1_part_next;
			assign cnt_fb = HASHERS[NUM_HASHERS-6'd1].cur_cnt;
		end
	endgenerate
		
	always @ (posedge clk)
	begin
		// We hardcode parameters LOOP=3 and NUM_HASHERS=22 giving 66 which is 2 in excess of
		// the 64 required, so need to take tx_hash output from the 20th stage.
		tx_hash[`IDX(0)] <= rx_state[`IDX(0)] + HASHERS[NUM_HASHERS-6'd3].state[`IDX(0)];
		tx_hash[`IDX(1)] <= rx_state[`IDX(1)] + HASHERS[NUM_HASHERS-6'd3].state[`IDX(1)];
		tx_hash[`IDX(2)] <= rx_state[`IDX(2)] + HASHERS[NUM_HASHERS-6'd3].state[`IDX(2)];
		tx_hash[`IDX(3)] <= rx_state[`IDX(3)] + HASHERS[NUM_HASHERS-6'd3].state[`IDX(3)];
		tx_hash[`IDX(4)] <= rx_state[`IDX(4)] + HASHERS[NUM_HASHERS-6'd3].state[`IDX(4)];
		tx_hash[`IDX(5)] <= rx_state[`IDX(5)] + HASHERS[NUM_HASHERS-6'd3].state[`IDX(5)];
		tx_hash[`IDX(6)] <= rx_state[`IDX(6)] + HASHERS[NUM_HASHERS-6'd3].state[`IDX(6)];
		tx_hash[`IDX(7)] <= rx_state[`IDX(7)] + HASHERS[NUM_HASHERS-6'd3].state[`IDX(7)];
	end

endmodule

module sha256_update_w (clk, rx_w0, rx_w1, rx_w9, rx_w14, tx_w15);
	input clk;
	input [31:0] rx_w0, rx_w1, rx_w9, rx_w14;
	output reg[31:0] tx_w15;
	
	wire [31:0] s0_w, s1_w;
	s0	s0_blk	(rx_w1, s0_w);
	s1	s1_blk	(rx_w14, s1_w);

	wire [31:0] new_w = s1_w + rx_w9 + s0_w + rx_w0;
	always @ (posedge clk)
		tx_w15 <= new_w;
	
endmodule

module sha256_digester (clk, k_next, rx_state, rx_t1_part, rx_w1, 
								tx_state, tx_t1_part);

	input clk;
	input [31:0] k_next;
	input [255:0] rx_state;
	input [31:0] rx_t1_part;
	input [31:0] rx_w1;

	output reg [255:0] tx_state;
	output reg [31:0] tx_t1_part;

	wire [31:0] e0_w, e1_w, ch_w, maj_w;
	
	
	e0	e0_blk	(rx_state[`IDX(0)], e0_w);
	e1	e1_blk	(rx_state[`IDX(4)], e1_w);
	ch	ch_blk	(rx_state[`IDX(4)], rx_state[`IDX(5)], rx_state[`IDX(6)], ch_w);
	maj	maj_blk	(rx_state[`IDX(0)], rx_state[`IDX(1)], rx_state[`IDX(2)], maj_w);

	wire [31:0] t1 = rx_t1_part + e1_w + ch_w ;
	wire [31:0] t2 = e0_w + maj_w;
	

	always @ (posedge clk)
	begin
		tx_t1_part <= (rx_state[`IDX(6)] + rx_w1 + k_next);
	
		tx_state[`IDX(7)] <= rx_state[`IDX(6)];
		tx_state[`IDX(6)] <= rx_state[`IDX(5)];
		tx_state[`IDX(5)] <= rx_state[`IDX(4)];
		tx_state[`IDX(4)] <= rx_state[`IDX(3)] + t1;
		tx_state[`IDX(3)] <= rx_state[`IDX(2)];
		tx_state[`IDX(2)] <= rx_state[`IDX(1)];
		tx_state[`IDX(1)] <= rx_state[`IDX(0)];
		tx_state[`IDX(0)] <= t1 + t2;
	end

endmodule
