#!/usr/bin/env python
#
# Generate testbench stimuli for coursework 2.
#
# WARNING:
#   Make sure that the clk_freq set here matches the clk_freq of your dcf and
#   msf VHDL components!

from itertools import cycle
from random import randint

clk_freq = 100 # Clock frequency (Hz)

def hex2int(hex):
	return int(hex, 16)

def hex2bin(hex):
	return "{0:b}".format(hex2int(hex)).zfill(8)

def process_file(input, output):
	file = open(input)
	out = open(output, "w")
	clk_period = 1000000000 / clk_freq # Clock period (ns)

	# Initialise starting state
	line = file.readline()
	components = line.split(' ')
	time_curr = hex2int(components[0])
	time_next = time_curr

	di_curr = hex2bin(components[2])
	di_next = di_curr

	clk_iter = cycle(range(2))

	line = file.readline()

	# Process all lines
	while line:
		components = line.split(' ')
		time_next = hex2int(components[0])
		di_next = hex2bin(components[2])

		while time_curr < time_next:
			clk = clk_iter.next()
			out.write(str(clk) + " " + str(di_curr) + "\n")
			time_curr += clk_period / 2

		di_curr = di_next
		time_curr = time_next

		line = file.readline()

	out.close()

def generate_ddr_stimuli(output):
	out = open(output, "w")

	clk_iter = cycle(range(2))
	clk2_iter = cycle(range(2))
	clk = 0

	for i in range(0, 1000):
		clk2 = clk2_iter.next()

		if clk2 % 2 == 0:
			clk = clk_iter.next()

			di = randint(0, 1)

		out.write(str(clk) + " " + str(clk2) + " " + str(di) + "\n")

	out.close()


if __name__ == "__main__":
	process_file("logs/dcf-signal.cap",
				 "dcf_sync_tb-stimulus.txt")
	process_file("logs/msf-signal.cap",
				 "msf_sync_tb-stimulus.txt")
	generate_ddr_stimuli("ddrserdes_tb-stimulus.txt")
