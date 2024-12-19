#!/bin/bash

###########################################################
# Packet Sniffer Script
# Author: Greg Lawler
# Date: 12/09/2004
# Description: This script sets up a transparent bridge
#               between the primary network interface (connected
#               to the internet/network) and the secondary
#               network interface (connected to the target
#               client). It prompts the user to select the
#               primary and secondary network interfaces for
#               packet capture. It then sets up a bridge
#               interface, adds the primary and secondary
#               interfaces to the bridge, and starts tcpdump to
#               capture packets. The captured packets are saved
#               to a file with a timestamp. After the specified
#               duration, the script stops the packet capture and
#               removes the bridge setup.
# Instructions:
# - Run this script with sudo privileges.
# - This script requires the bridge-utils and tcpdump
#   packages to be installed. If not found, it will prompt
#   the user to install them.
# - The packet capture file will be saved in the current
#   working directory with a timestamp.
# - Run this script in a screen session to avoid losing
#   connectivity during packet capture.
# - Extract the data you're interested in into a directory
#     tshark -r capture_file.pcap --export-objects http,./http_objects
#
###########################################################

# Function to check if a string is a valid IP address
is_valid_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to print colored messages
print_in_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}\033[0m"
}

# Check if bridge-utils and tcpdump are installed
if ! command -v brctl &> /dev/null || ! command -v tcpdump &> /dev/null; then
    echo "Required dependencies are missing."
    read -p "Do you want to install them? (y/n): " choice
    if [ "$choice" == "y" ]; then
        echo "Installing required dependencies..."
        sudo apt update
        sudo apt install -y bridge-utils tcpdump
    else
        echo "Dependencies not installed. Exiting."
        exit 1
    fi
fi

# Get a list of available network interfaces
interfaces=$(ip link show | awk -F ': ' '{print $2}' | grep -v '^lo' | grep -v '^ipvs' | grep -v '@' | grep -v '^6')

# Check if there are any available interfaces
if [ -z "$interfaces" ]; then
    echo "No available physical Ethernet interfaces found."
    exit 1
fi

# Prompt the user to select a primary network interface
echo "Available physical Ethernet interfaces (primary - connected to internet/network):"
select primary_interface in $interfaces; do
    if [ -n "$primary_interface" ]; then
        break
    else
        echo "Invalid selection. Please try again."
    fi
done

# Prompt the user to select a secondary network interface
echo "Available physical Ethernet interfaces (secondary - connected to target client):"
select secondary_interface in $interfaces; do
    if [ -n "$secondary_interface" ]; then
        break
    else
        echo "Invalid selection. Please try again."
    fi
done

# Print alert message in color
print_in_color "\033[1;33m" "NOTE: Any remote SSH or other sessions to this device will be dropped for the duration of packet capture."
print_in_color " "
print_in_color "\033[0;31m" "WARNING: Run this in a screen session to avoid locking yourself out."
print_in_color " "

# Prompt the user for the duration of packet capture
read -p "Please enter the duration (in minutes) to run the packet capture (max 10 minutes): " duration
if [ "$duration" -gt 10 ]; then
    echo "Maximum duration exceeded. Setting duration to 10 minutes."
    duration=10
fi

# Generate timestamp for filename
timestamp=$(date "+%Y%m%d_%H%M%S")

# Remove any existing bridge setup
existing_bridge=$(brctl show | awk '/^br/ {print $1}')
if [ -n "$existing_bridge" ]; then
    echo "Removing existing bridge: $existing_bridge"
    sudo brctl delbr $existing_bridge
fi

# Create a bridge interface
bridge_name="br_sniffer"
sudo brctl addbr $bridge_name

# Add both primary interface and the selected secondary interface to the bridge
sudo brctl addif $bridge_name $primary_interface
sudo brctl addif $bridge_name $secondary_interface

# Turn up the bridge and the interfaces
sudo ip link set $bridge_name up
sudo ip link set $primary_interface up
sudo ip link set $secondary_interface up

# Get the primary interface IP address
primary_ip=$(ip -4 addr show $primary_interface | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

echo "Starting packet capture for $duration minutes..."

# Start tcpdump to capture packets on the bridge interface, excluding primary interface traffic and mDNS traffic
#sudo tcpdump -U -i $secondary_interface "not host $primary_ip and not udp port 5353 and not host 224.0.0.251 and not port 22" -s 0 -A > "pcap_$timestamp.log" &
sudo tcpdump -U -i $bridge_name -w "pcap_$timestamp.pcap" "not host $primary_ip and not udp port 5353 and not host 224.0.0.251" &

# Sleep for the specified duration
duration=$((duration * 60))
sleep $duration

# Terminate tcpdump after the specified duration
sudo pkill tcpdump

# Remove the bridge setup
sudo brctl delif $bridge_name $primary_interface
sudo brctl delif $bridge_name $secondary_interface
sudo ip link set $bridge_name down
sudo brctl delbr $bridge_name

echo "Packet capture completed."
