class test extends uvm_test;
	`uvm_component_utils(test)

	environment env;
	virtual router_io.tb rtr_io;
	rand int unsigned num_pkts;
	constraint c_num { num_pkts inside {[1500:2500]}; }

	function new(string name = "test", uvm_component parent = null);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		env = environment::type_id::create("env", this);
		if(!uvm_config_db#(virtual router_io.tb)::get(this, "", "vif", rtr_io))
			`uvm_fatal("TEST", "virtual interface 'vif' not set")
	endfunction

	task reset();
		this.rtr_io.cb.reset_n <= 1'b0;
		this.rtr_io.cb.frame_n <= '1;
		this.rtr_io.cb.valid_n <= '1;
		repeat(3) @(this.rtr_io.cb);
		this.rtr_io.cb.reset_n <= 1'b1;
		repeat(15) @(this.rtr_io.cb);
	endtask

	task run_phase(uvm_phase phase);
		my_sequence seq[16];
		int unsigned n;

		phase.raise_objection(this);

		if(!this.randomize()) begin
			$display("test randomize failed");
			num_pkts = 2000;
		end
		if($value$plusargs("NUM_PKTS=%d", n)) num_pkts = n;
		run_for_n_times = num_pkts;
		$display("running %0d packets", run_for_n_times);

		this.reset();

		foreach(seq[i]) begin
			seq[i] = my_sequence::type_id::create($sformatf("seq%0d", i));
			seq[i].port      = i;
			seq[i].num_trans = num_pkts/16 + ((i < num_pkts%16) ? 1 : 0);
		end

		fork
			begin
				foreach(seq[i]) begin
					automatic int k = i;
					fork
						seq[k].start(env.agt[k].sqr);
					join_none
				end
				wait(env.sb.DONE.triggered);
			end
			begin
				repeat(run_for_n_times * 100) @(rtr_io.cb);
				`uvm_error("TEST", $sformatf("timeout: only %0d of %0d packets checked", env.sb.pkts_checked, run_for_n_times))
			end
		join_any
		disable fork;

		repeat(20) @(rtr_io.cb);
		phase.drop_objection(this);
	endtask
endclass
