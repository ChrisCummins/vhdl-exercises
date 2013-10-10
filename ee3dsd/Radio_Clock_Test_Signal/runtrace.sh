#!/bin/bash

usage () {
	echo "Usage: $0 <tracefile>"
}

if [ -z $1 ]; then
	usage
	exit 1
fi

if [ ! -f $1 ]; then
	echo "Trace file '$1' not found"
	exit 2
fi

if [ -f trace.cap ]; then
	# Backup existing trace file so as not to overwrite
	mv -v trace.cap .trace.cap~
fi

# Copy user trace file to test bench input
cp $1 trace.cap

# Run the simulation and open the trace
make clean sim view
