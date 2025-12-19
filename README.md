# DV Mini Project — FIFO Verification (Verilog / Icarus)

This repo demonstrates **Design Verification fundamentals** by verifying a parameterized FIFO RTL block using:
- Directed tests
- A reference model (golden circular buffer)
- Scoreboard/checker comparisons (data + empty/full)
- Waveform dumping (VCD)

## Project Structure
- `rtl/` — FIFO RTL (DUT)
- `tb/` — testbench + scoreboard
- `docs/` — verification plan
- `.github/workflows/` — CI that runs simulation on every push

## How it Works
- Testbench drives `push/pop/din`
- Reference model mirrors FIFO behavior
- On each accepted pop, compares `dout` against expected
- Checks `empty/full` against the reference count

## Run (Windows PowerShell)
```powershell
iverilog -g2012 -Wall -o sim.vvp rtl/fifo.sv tb/tb_fifo.sv
vvp .\sim.vvp
