#!/bin/bash

# Function to convert an IP address to an integer
ip_to_int() {
  local ip=$1
  local a b c d
  IFS=. read -r a b c d <<<"$ip"
  echo $(((a << 24) + (b << 16) + (c << 8) + d))
}

# Function to convert an integer to an IP address
int_to_ip() {
  local int=$1
  echo "$(((int >> 24) & 255)).$(((int >> 16) & 255)).$(((int >> 8) & 255)).$((int & 255))"
}

# Function to calculate the next CIDR range based on the given CIDR and new subnet mask
next_cidr() {
  local cidr=$1
  local new_mask=$2
  local ip=${cidr%/*}
  local mask=${cidr#*/}

  local ip_int=$(ip_to_int "$ip")
  local increment=$((1 << (32 - new_mask)))
  local next_ip_int=$((ip_int + increment))

  # Check for overflow of the IP address range
  if (( next_ip_int > 4294967295 )); then
    echo "Error: IP address overflow"
    exit 1
  fi

  local next_ip=$(int_to_ip "$next_ip_int")

  echo "$next_ip/$new_mask"
}

# Main script execution starts here
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <CIDR> <new_mask>"
  exit 1
fi

cidr=$1
new_mask=$2

# Calculate the next CIDR range
new_cidr=$(next_cidr "$cidr" "$new_mask")

# Output the new CIDR range in JSON format
jq -n --arg new_cidr "$new_cidr" '{"new_cidr":$new_cidr}'
