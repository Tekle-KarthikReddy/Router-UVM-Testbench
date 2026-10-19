`include "driverbase.sv"

// one semaphore per destination port, shared by all 16 drivers so that two
// sources never talk to the same output at the same time
class router_sem_pool;
	static semaphore sem[16];
	static function void init();
		foreach(sem[i]) if(sem[i] == null) sem[i] = new(1);
	endfunction
endclass

class driver extends driverbase;
	`uvm_component_utils(driver)

	seq_item trans;
	uvm_analysis_port#(seq_item) out_ap;     // sent packets -> scoreboard

	extern function new(string name, uvm_component parent);
	extern virtual function void build_phase(uvm_phase phase);
	extern virtual task run_phase(uvm_phase phase);
endclass

function driver::new(string name, uvm_component parent);
	super.new(name, parent);
endfunction

function void driver::build_phase(uvm_phase phase);
	super.build_phase(phase);
	out_ap = new("out_ap", this);
	router_sem_pool::init();
endfunction

task driver::run_phase(uvm_phase phase);
	forever begin
		seq_item ref_pkt;
		seq_item_port.get_next_item(this.trans);
		if(this.trans.sa != this.sa)
			`uvm_error("DRV", $sformatf("pkt.sa=%0d but driver is port %0d", this.trans.sa, this.sa))
		this.da      = this.trans.da;
		this.payload = this.trans.payload;
		router_sem_pool::sem[this.da].get(1);
		$cast(ref_pkt, this.trans.clone());
		this.out_ap.write(ref_pkt);          // expected packet, written under the semaphore
		this.send();
		router_sem_pool::sem[this.da].put(1);
		seq_item_port.item_done();
	end
endtask
