`uvm_analysis_imp_decl(_drv)
`uvm_analysis_imp_decl(_rcv)

class scoreboard extends uvm_scoreboard;
	`uvm_component_utils(scoreboard)

	uvm_analysis_imp_drv#(seq_item, scoreboard) drv_imp;
	uvm_analysis_imp_rcv#(seq_item, scoreboard) rcv_imp;
	event DONE;
	seq_item  refpkt[$];
	seq_item  pkt2cmp;
	bit [3:0] sa, da;
	int pkts_checked = 0;
	int pass_count   = 0;
	int fail_count   = 0;
	real coverage_result;

	covergroup cg;
		cp_sa : coverpoint sa { option.weight = 0; }
		cp_da : coverpoint da { option.weight = 0; }
		sa_x_da : cross cp_sa, cp_da;
	endgroup

	extern function new(string name, uvm_component parent);
	extern virtual function void build_phase(uvm_phase phase);
	extern virtual function void write_drv(seq_item pkt);
	extern virtual function void write_rcv(seq_item pkt);
	extern virtual function void check_packet();
	extern virtual function void report_phase(uvm_phase phase);
endclass

function scoreboard::new(string name, uvm_component parent);
	super.new(name, parent);
	cg = new();
endfunction

function void scoreboard::build_phase(uvm_phase phase);
	super.build_phase(phase);
	drv_imp = new("drv_imp", this);
	rcv_imp = new("rcv_imp", this);
endfunction

function void scoreboard::write_drv(seq_item pkt);
	refpkt.push_back(pkt);
endfunction

function void scoreboard::write_rcv(seq_item pkt);
	this.pkt2cmp = pkt;
	check_packet();
endfunction

function void scoreboard::check_packet();
	string message = "";
	int idx = -1;
	bit passed = 0;

	// oldest expected packet for this destination
	foreach(refpkt[i]) begin
		if(refpkt[i].da == pkt2cmp.da) begin
			idx = i;
			break;
		end
	end

	if(idx == -1) begin
		`uvm_error("SB", $sformatf("no matching reference packet for da=%0d : %s", pkt2cmp.da, pkt2cmp.convert2string()))
		fail_count++;
	end
	else begin
		if(!refpkt[idx].compare_data(pkt2cmp, message)) begin
			`uvm_error("SB", $sformatf("Packet #%0d da=%0d: %s", pkts_checked, pkt2cmp.da, message))
			fail_count++;
		end
		else begin
			pass_count++;
			passed = 1;
		end
		this.sa = refpkt[idx].sa;
		this.da = refpkt[idx].da;
		cg.sample();
		refpkt.delete(idx);
	end

	coverage_result = cg.get_coverage();

	// per-packet log line, same format as the original router testbench
	if(passed)
		$display("[NOTE]%0t Packet #%0d %s coverage = %3.2f", $time, pkts_checked, message, coverage_result);

	pkts_checked++;
	if(pkts_checked >= run_for_n_times)
		->DONE;
endfunction

function void scoreboard::report_phase(uvm_phase phase);
	super.report_phase(phase);
	if(refpkt.size() != 0)
		`uvm_error("SB", $sformatf("%0d expected packet(s) never arrived", refpkt.size()))
	`uvm_info("SB", $sformatf("test completed: PASS=%0d FAIL=%0d coverage=%3.2f", pass_count, fail_count, coverage_result), UVM_LOW)
	if(fail_count == 0 && pass_count > 0 && refpkt.size() == 0)
		`uvm_info("SB", "*** TEST PASSED ***", UVM_LOW)
	else
		`uvm_error("SB", "TEST FAILED")
endfunction
