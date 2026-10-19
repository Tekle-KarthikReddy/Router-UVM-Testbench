# 16-Port Router - UVM Testbench

UVM testbench for a 16-port packet router (1-bit serial inputs `din[15:0]`, `frame_n`, `valid_n`; serial outputs `dout[15:0]`, `frameo_n`, `valido_n`). The testbench uses base/derived driver and receiver classes, one agent per port, and a scoreboard with `sa` x `da` functional coverage.

## Layout

- `design.sv` - `router` module (RTL, 16 `rtslice` instances with round-robin arbitration)
- `testbench.sv` - single-file UVM testbench containing:
  - `router_io` - interface with clocking block `cb` and modport `tb`
  - `router_pkg` - package with all UVM classes
  - `router_test_top` - top module: clock, DUT instance, config DB, `run_test`, VCD dump for EPWave

### Class overview (inside `router_pkg`)

| Class | Extends | Role |
|---|---|---|
| `seq_item` | `uvm_sequence_item` | Packet: `sa`, `da`, payload (2-4 bytes) |
| `my_sequence` | `uvm_sequence` | Sends random packets from one source port |
| `my_sequencer` | `uvm_sequencer` | Sequencer |
| `driverbase` | `uvm_driver` | Pin-level `send()`, `send_addrs()`, `send_pad()`, `send_payload()` |
| `driver` | `driverbase` | `run_phase`, analysis port, per-destination semaphore |
| `receiverbase` | `uvm_monitor` | Pin-level `recv()`, `get_payload()` |
| `receiver` | `receiverbase` | `run_phase`, analysis port to scoreboard |
| `agent` | `uvm_agent` | Sequencer + driver + receiver for one port |
| `scoreboard` | `uvm_scoreboard` | Per-destination in-order compare, coverage, PASS/FAIL report |
| `environment` | `uvm_env` | 16 agents + scoreboard |
| `test` | `uvm_test` | Reset, runs 1500-2500 random packets (or `+NUM_PKTS=n`) |

## Run on EDA Playground

**Link:** https://edaplayground.com/x/9LWW

**Settings:** Testbench + Design = SystemVerilog/Verilog, **UVM / OVM = UVM 1.2**, simulator = Synopsys VCS / Cadence Xcelium / Aldec Riviera-PRO (a simulator with UVM support), top module = `router_test_top`. Tick **Open EPWave after run** to view waveforms.

- Paste `design.sv` in the left pane and `testbench.sv` in the right pane.
- Optional Run Options: `+NUM_PKTS=100` for a shorter run and a smaller waveform.
- If the simulator complains about a missing timescale, add `-timescale=1ns/1ps` to the compile options.

## Results
<img width="1657" height="922" alt="image" src="https://github.com/user-attachments/assets/c67b8e27-b492-4c22-996c-23e7d9e44283" />
<img width="1803" height="778" alt="image" src="https://github.com/user-attachments/assets/eaa07bbe-7a77-4ed1-a494-971f9725c7f2" />


