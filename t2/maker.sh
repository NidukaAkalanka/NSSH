#!/bin/bash

pid=$1
username=$2
port=$3

if [ -z "$pid" ]; then
  echo "No active connection found for user $username on port $port"
  exit 1
fi

# Copy counter.sh to $pid_counter.sh
cp /root/t2/counter.sh /root/t2/"$pid"_counter.sh

# Set the path of the newly created script
counter_script=/root/t2/"$pid"_counter.sh

# Pass the variables to the newly created $pid_counter.sh and execute it
"$counter_script" "$pid" "$username" "$port"
