class my_sequence extends uvm_sequence#(seq_item);
	`uvm_object_utils(my_sequence)

	int unsigned port;          // source port this sequence drives
	int unsigned num_trans = 10;

	function new(string name = "my_sequence");
		super.new(name);
	endfunction

	task body();
		repeat(num_trans) begin
			req = seq_item::type_id::create("req");
			start_item(req);
			if(!req.randomize() with { sa == local::port; }) begin
				`uvm_error("body", "Randomization failed")
			end
			finish_item(req);
		end
	endtask
endclass
