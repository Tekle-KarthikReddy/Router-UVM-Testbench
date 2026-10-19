class driverbase extends uvm_driver#(seq_item);
	virtual router_io.tb rtr_io;      // interface signals
	bit [3:0]   sa, da;               // source (this port) and destination address
	logic [7:0] payload[$];           // payload of the packet being sent

	extern function new(string name, uvm_component parent);
	extern virtual function void build_phase(uvm_phase phase);
	extern virtual task send();
	extern virtual task send_addrs();
	extern virtual task send_pad();
	extern virtual task send_payload();
endclass

function driverbase::new(string name, uvm_component parent);
	super.new(name, parent);
endfunction

function void driverbase::build_phase(uvm_phase phase);
	super.build_phase(phase);
	if(!uvm_config_db#(virtual router_io.tb)::get(this, "", "vif", this.rtr_io))
		`uvm_fatal("DRV", "virtual interface 'vif' not set")
endfunction

task driverbase::send();
	this.send_addrs();
	this.send_pad();
	this.send_payload();
endtask

// frame_n low, destination address LSB first (4 cycles)
task driverbase::send_addrs();
	this.rtr_io.cb.frame_n[this.sa] <= 1'b0;
	for(int i=0; i<4; i++) begin
		this.rtr_io.cb.din[this.sa] <= this.da[i];
		@(this.rtr_io.cb);
	end
endtask

// 5 pad cycles with valid_n high
task driverbase::send_pad();
	this.rtr_io.cb.din[this.sa]     <= 1'b1;
	this.rtr_io.cb.valid_n[this.sa] <= 1'b1;
	repeat(5) @(this.rtr_io.cb);
endtask

// payload bytes LSB first, frame_n released together with the very last bit
task driverbase::send_payload();
	foreach(this.payload[index]) begin
		for(int i=0; i<8; i++) begin
			this.rtr_io.cb.din[this.sa]     <= this.payload[index][i];
			this.rtr_io.cb.valid_n[this.sa] <= 1'b0;
			this.rtr_io.cb.frame_n[this.sa] <= ((index == (this.payload.size() - 1)) && (i == 7));
			@(this.rtr_io.cb);
		end
	end
	this.rtr_io.cb.valid_n[this.sa] <= 1'b1;
endtask
