SIM=iverilog
VVP=vvp

RTL=rtl/fifo.sv
TB=tb/tb_fifo.sv

all: test

build:
	$(SIM) -g2012 -o sim.out $(RTL) $(TB)

test: build
	$(VVP) sim.out

wave: test
	@echo "Open GTKWave: gtkwave wave.vcd"

clean:
	rm -f sim.out wave.vcd
