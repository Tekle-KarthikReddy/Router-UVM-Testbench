class environment extends uvm_env;
	`uvm_component_utils(environment)

	agent      agt[16];      // one agent per router port
	scoreboard sb;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		foreach(agt[i]) begin
			agt[i] = agent::type_id::create($sformatf("agt%0d", i), this);
			agt[i].port_id = i;
		end
		sb = scoreboard::type_id::create("sb", this);
	endfunction

	function void connect_phase(uvm_phase phase);
		foreach(agt[i]) begin
			agt[i].drvr.out_ap.connect(sb.drv_imp);
			agt[i].rcvr.out_ap.connect(sb.rcv_imp);
		end
	endfunction
endclass
