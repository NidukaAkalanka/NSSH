#!/bin/bash

auth_log="/var/log/auth.log"
last_position=$(stat -c %s "$auth_log")

# Function to extract PID, username, and port from Dropbear log entry
extract_info() {
    log_entry=$1
    pid=$(echo "$log_entry" | awk -F'[][]' '{print $2}')
    username=$(echo "$log_entry" | awk -F"'" '{print $2}')
    port=$(echo "$log_entry" | awk -F'[: ]' '{print $NF}')
    echo "PID: $pid, Username: $username, Port: $port"
    # Call maker.sh here, passing the extracted variables as arguments
    /root/t2/maker.sh "$pid" "$username" "$port"
}

# Infinite loop to continuously monitor the log file
while true; do
    new_position=$(stat -c %s "$auth_log")

    if [[ $new_position -gt $last_position ]]; then
        new_data=$(tail -c +$last_position "$auth_log")

        while IFS= read -r line; do
            if [[ $line == *"dropbear"* && $line == *"Password auth succeeded"* ]]; then
                extract_info "$line"
            fi
        done <<< "$new_data"

        last_position=$new_position
    fi

    sleep 1
done
