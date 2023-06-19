#!/bin/bash

pid=$1
username=$2
port=$3

if [ -z "$pid" ]; then
  echo "No active connection found for user $username on port $port"
  exit 1
fi

echo "Capturing network usage for user $username on port $port..."

tcpdump -i lo -s 0 -n port $port -w "/root/t2/${pid}_capture.pcap" > /dev/null &
tcpdump_pid=$!

# Wait for the signal to stop capturing
while true; do
  if [ -e "/root/t2/${pid}_stop.txt" ]; then
    break
  fi
  sleep 1
done

kill -SIGINT $tcpdump_pid

echo "Network capturing stopped"

sent_data=$(tcpdump -nnr "/root/t2/${pid}_capture.pcap" | awk 'BEGIN {sum=0} {sum+=$NF} END {printf "%.2f", sum/1024/1024}')

data_file="/root/t2/data_usage.txt"

# Check if the data file exists
if [[ -f "$data_file" ]]; then
  # Check if the user's record already exists
  if grep -q "^${username} :" "$data_file"; then
    # Extract the existing value for the user
    existing_value=$(grep "^${username} :" "$data_file" | awk -F' : ' '{print $2}')
    
    # Calculate the new total
    new_total=$(awk "BEGIN { printf \"%.2f\", $existing_value + $sent_data }")
    
    # Delete the user's record
    sed -i "/^${username} :/d" "$data_file"
    
    # Write the new record to the data file
    echo "${username} : ${new_total}" >> "$data_file"
  else
    # Append a new record for the user to the data file
    echo "${username} : ${sent_data}" >> "$data_file"
  fi
else
  # Create the data file and write the user's record
  echo "${username} : ${sent_data}" > "$data_file"
fi



# Delete the $pid_counter.sh and $pid_capture.pcap files
rm "/root/t2/${pid}_capture.pcap"
rm "/root/t2/${pid}_counter.sh"
