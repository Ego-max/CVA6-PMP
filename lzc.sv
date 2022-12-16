module lzc (
  input  logic [33:0]   in_i,
  output logic [5:0] 	cnt_o,
  output logic          empty_o // asserted if all bits in in_i are zero
);


  logic [33:0][5:0]  index_lut;
  logic [63:0]       sel_nodes;
  logic [63:0][5:0]  index_nodes;

  logic [33:0] 		 in_tmp;

  assign in_tmp = in_i;

  for (genvar j = 0; unsigned'(j) < 34; j++) begin : g_index_lut
    assign index_lut[j] = 6'(unsigned'(j));
  end

  for (genvar level = 0; unsigned'(level) < 6; level++) begin : g_levels
    if (unsigned'(level) == 5) begin : g_last_level
      for (genvar k = 0; k < 2**level; k++) begin : g_level
        // if two successive indices are still in the vector...
        if (unsigned'(k) * 2 < 33) begin
          assign sel_nodes[2**level-1+k]   = in_tmp[k*2] | in_tmp[k*2+1];
          assign index_nodes[2**level-1+k] = (in_tmp[k*2] == 1'b1) ? index_lut[k*2] : index_lut[k*2+1];
        end
        // if only the first index is still in the vector...
        if (unsigned'(k) * 2 == 33) begin
          assign sel_nodes[2**level-1+k]   = in_tmp[k*2];
          assign index_nodes[2**level-1+k] = index_lut[k*2];
        end
        // if index is out of range
        if (unsigned'(k) * 2 > 33) begin
          assign sel_nodes[2**level-1+k]   = 1'b0;
          assign index_nodes[2**level-1+k] = '0;
        end
      end
    end else begin
      for (genvar l = 0; l < 2**level; l++) begin : g_level
		assign sel_nodes[2**level-1+l]   = sel_nodes[2**(level+1)-1+l*2] | sel_nodes[2**(level+1)-1+l*2+1];
        assign index_nodes[2**level-1+l] = (sel_nodes[2**(level+1)-1+l*2] == 1'b1) ? index_nodes[2**(level+1)-1+l*2] : index_nodes[2**(level+1)-1+l*2+1];
      end
    end
  end

  assign cnt_o   = 6 > unsigned'(0) ? index_nodes[0] : $clog2(34)'(0);
  assign empty_o = 6 > unsigned'(0) ? ~sel_nodes[0]  : ~(|in_i);

endmodule : lzc