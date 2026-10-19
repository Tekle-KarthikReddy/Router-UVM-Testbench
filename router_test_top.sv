`include "router_io.sv"
`include "router_pkg.sv"

module router_test_top;
	import uvm_pkg::*;
	import router_pkg::*;
	`include "uvm_macros.svh"
	parameter simulation_cycle = 100;
	bit SystemClock;

	router_io top_io(SystemClock);
	virtual router_io.tb tb_vif;

	router dut(
		.reset_n  (top_io.reset_n),
		.clock    (top_io.clock),
		.din      (top_io.din),
		.frame_n  (top_io.frame_n),
		.valid_n  (top_io.valid_n),
		.dout     (top_io.dout),
		.valido_n (top_io.valido_n),
		.busy_n   (top_io.busy_n),
		.frameo_n (top_io.frameo_n)
	);

	initial begin
		SystemClock = 0;
		forever begin
			#(simulation_cycle/2)
			SystemClock = ~SystemClock;
		end
	end

	initial begin
		tb_vif = top_io.tb;
		uvm_config_db#(virtual router_io.tb)::set(null, "*", "vif", tb_vif);
		run_test("test");
	end
endmodule
