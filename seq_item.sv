class seq_item extends uvm_sequence_item;
	rand bit [3:0]   sa;
	rand bit [3:0]   da;
	rand logic [7:0] payload[$];

	`uvm_object_utils(seq_item)

	constraint limit { payload.size() inside {[2:4]}; }

	extern function new(string name = "seq_item");
	extern virtual function void do_copy(uvm_object rhs);
	extern virtual function string convert2string();
	extern function bit compare_data(seq_item pkt2cmp, ref string message);
endclass

function seq_item::new(string name = "seq_item");
	super.new(name);
endfunction

function void seq_item::do_copy(uvm_object rhs);
	seq_item r;
	super.do_copy(rhs);
	if(!$cast(r, rhs)) `uvm_fatal("COPY", "do_copy cast failed")
	this.sa      = r.sa;
	this.da      = r.da;
	this.payload = r.payload;
endfunction

function string seq_item::convert2string();
	return $sformatf("sa=%0d da=%0d payload=%p", sa, da, payload);
endfunction

// only the payload is compared (the output side does not know the source address)
function bit seq_item::compare_data(seq_item pkt2cmp, ref string message);
	if(payload.size() != pkt2cmp.payload.size()) begin
		message = $sformatf("payload size mismatch: exp=%0d rcv=%0d", payload.size(), pkt2cmp.payload.size());
		return(0);
	end
	foreach(payload[i]) begin
		if(payload[i] !== pkt2cmp.payload[i]) begin
			message = $sformatf("payload content mismatch: exp=%p rcv=%p", payload, pkt2cmp.payload);
			return(0);
		end
	end
	message = "Successfully compared";
	return(1);
endfunction
