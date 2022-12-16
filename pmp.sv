module pmp (
    // Input
    input logic [33:0] addr_i,
    input riscv::pmp_access_t access_type_i,
    input riscv::priv_lvl_t priv_lvl_i,
    // Configuration
    input logic [3:0][31:0] conf_addr_i,
    input riscv::pmpcfg_t [3:0] conf_i,
    // Output
    output logic allow_o
);
	logic [3:0] match;

	for (genvar i = 0; i < 4; i++) begin
		logic [31:0] conf_addr_prev;

		assign conf_addr_prev = (i == 0) ? '0 : conf_addr_i[i-1];

		pmp_entry i_pmp_entry(
			.addr_i           ( addr_i              ),
			.conf_addr_i      ( conf_addr_i[i]      ),
			.conf_addr_prev_i ( conf_addr_prev      ),
			.conf_addr_mode_i ( conf_i[i].addr_mode ),
			.match_o          ( match[i]            )
		);
	end

	always_comb begin
		int i;

		allow_o = 1'b0;
		for (i = 0; i < 4; i++) begin
			// either we are in S or U mode or the config is locked in which
			// case it also applies in M mode
			if (priv_lvl_i != riscv::PRIV_LVL_M || conf_i[i].locked) begin
				if (match[i]) begin
					if ((access_type_i & conf_i[i].access_type) != access_type_i) allow_o = 1'b0;
					else allow_o = 1'b1;
					break;
				end
			end
		end
		if (i == 4) begin // no PMP entry matched the address
			// allow all accesses from M-mode for no pmp match
			if (priv_lvl_i == riscv::PRIV_LVL_M) allow_o = 1'b1;
			// disallow accesses for all other modes
			else allow_o = 1'b0;
		end
	end


    `ifdef FORMAL
    always @(*) begin
        if(priv_lvl_i == riscv::PRIV_LVL_M) begin
            static logic no_locked = 1'b1;
            for (int i = 0; i < 4; i++) begin
                if (conf_i[i].locked && conf_i[i].addr_mode != riscv::OFF) begin
                    no_locked &= 1'b0;
                end else no_locked &= 1'b1;
            end

            if (no_locked == 1'b1) assert(allow_o == 1'b1);
        end
    end
    `endif
endmodule
