#!/bin/bash

read -p "Enter the port number: " port

# Check if tcpdump command is available
if ! [ -x "$(command -v tcpdump)" ]; then
  echo "tcpdump command is not available. Please install tcpdump."
  exit 1
fi

# Check if ss command is available
if ! [ -x "$(command -v ss)" ]; then
  echo "ss command is not available. Please install iproute2 package."
  exit 1
fi

# Get the process ID using ss
pid=$(ss -t -nlp 'sport = :'$port' or dport = :'$port' and dst 127.0.0.1' | awk 'NR>1 {print $NF}' | cut -d= -f2)

# Check if the process is running
if [ -z "$pid" ]; then
  echo "No active connection found on 127.0.0.1:$port"
  exit 1
fi

echo "Capturing network usage on 127.0.0.1:$port..."
echo "Press Enter to stop capturing"

# Start tcpdump in the background to capture network traffic
tcpdump -i lo -s 0 -n port $port -w capture.pcap > /dev/null &
tcpdump_pid=$!

# Wait for the user to press Enter
read -s

# Stop tcpdump
kill -SIGINT $tcpdump_pid

echo "Network capturing stopped"

# Calculate the total amount of data sent
sent_data=$(tcpdump -nnr capture.pcap | awk 'BEGIN {sum=0} {sum+=$NF} END {printf "%.2f", sum/1024/1024}')

echo "Total MBs sent: $sent_data"

# Clean up the capture file
rm -f capture.pcap
