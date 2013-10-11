#!/bin/bash
# Strip DCF readings from MSF trace file

cat dcf.cap | \
while read entry; do
	sed -i "/$entry/d" msf.cap
done
