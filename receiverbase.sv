class receiverbase extends uvm_monitor;
	virtual router_io.tb rtr_io;      // interface signals
	bit [3:0]   da;                   // output port to monitor
	logic [7:0] pkt2cmp_payload[$];   // actual payload
	seq_item    pkt2cmp;              // actual packet

	localparam int unsigned PKT_TIMEOUT_CYCLES = 1000;

	extern function new(string name, uvm_component parent);
	extern virtual function void build_phase(uvm_phase phase);
	extern virtual task recv();
	extern virtual task get_payload();
endclass

function receiverbase::new(string name, uvm_component parent);
	super.new(name, parent);
endfunction

function void receiverbase::build_phase(uvm_phase phase);
	super.build_phase(phase);
	if(!uvm_config_db#(virtual router_io.tb)::get(this, "", "vif", this.rtr_io))
		`uvm_fatal("RCV", "virtual interface 'vif' not set")
	this.pkt2cmp = seq_item::type_id::create("pkt2cmp");
endfunction

task receiverbase::recv();
	this.get_payload();
	this.pkt2cmp.da      = this.da;
	this.pkt2cmp.payload = this.pkt2cmp_payload;
endtask

task receiverbase::get_payload();
	logic [7:0]  datum;
	int unsigned cycles = 0;

	this.pkt2cmp_payload.delete();

	// wait for the start of an output frame
	while(this.rtr_io.cb.frameo_n[this.da] !== 1'b0) @(this.rtr_io.cb);

	forever begin
		datum = '0;
		for(int i=0; i<8; ) begin
			if(this.rtr_io.cb.valido_n[this.da] === 1'b0)
				datum[i++] = this.rtr_io.cb.dout[this.da];
			if(this.rtr_io.cb.frameo_n[this.da] === 1'b1) begin
				if(i == 8) begin
					this.pkt2cmp_payload.push_back(datum);
					return;
				end
				else begin
					`uvm_fatal("RCV", $sformatf("Port %0d: packet payload not byte aligned", this.da))
				end
			end
			@(this.rtr_io.cb);
			if(++cycles > PKT_TIMEOUT_CYCLES) begin
				`uvm_fatal("RCV", $sformatf("Port %0d: frame signal timed out", this.da))
			end
		end
		this.pkt2cmp_payload.push_back(datum);
	end
endtask
