#!/bin/bash

auth_log="/var/log/auth.log"
last_position=$(stat -c %s "$auth_log")

# Function to extract PID from Dropbear log entry
extract_pid() {
    log_entry=$1
    pid=$(echo "$log_entry" | awk -F'[][]' '{print $2}')
    echo "PID: $pid"
    # Create the stop signal file
    touch "/root/t2/${pid}_stop.txt"
    sleep 10
    rm -f "/root/t2/${pid}_stop.txt"
}

# Infinite loop to continuously monitor the log file
while true; do
    new_position=$(stat -c %s "$auth_log")

    if [[ $new_position -gt $last_position ]]; then
        new_data=$(tail -c +$last_position "$auth_log")

        while IFS= read -r line; do
            if [[ $line == *"dropbear"* && $line == *"Exit"* ]]; then
                extract_pid "$line"
            fi
        done <<< "$new_data"

        last_position=$new_position
    fi

    sleep 1
done
