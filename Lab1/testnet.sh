#!/bin/bash -u

#============================================
# Script Name: testnet.sh
# Purpose : summarize network settings and display results
# Date : 21/09/2026
# Author : Arslane Mir
# Version : 1.1
#============================================

#============================================
# Section 1: Service Status Check
# Check that key network services are in the expected state:
# - NetworkManager should be running
# - Firewalld should be disabled/stopped
# - Iptables should have open policies (ACCEPT)
# - SELinux status
#============================================

echo -e "\n Section 1: Service Status Check \n"

# Check if NetworkManager is loaded and actively running
echo -e "\n Network Manager Status"
echo "-----------------------------"
systemctl status NetworkManager | grep -E "Loaded|Active"

# Verify firewalld is disabled so it doesn't block lab traffic
echo -e "\n Firewalld Status"
echo "----------------------"
systemctl status firewalld | grep -E "Loaded|Active"

# Show iptables chain policies — all should be ACCEPT
echo -e "\n Iptables Status"
echo "-------------------"
sudo iptables -L -n | grep "Chain \(INPUT\|FORWARD\|OUTPUT\)"

# Show whether SELinux is enforcing, permissive, or disabled
echo -e "\n SELinux Status"
echo "-----------------"
getenforce

#============================================
# Section 2: Network Configuration Display
# Display current network settings including:
# - IP addresses on both interfaces (red and blue networks)
# - DNS servers, hostname resolution order
# - Static host entries and default gateway
#============================================

echo -e "\n Section 2: Network Configuration Display \n"

# Show IP addresses for the blue (ens160) and red (ens224) interfaces
echo -e "\n IP Addresses"
echo "-------------------"
ip -br a | grep -E "ens160|ens224"

# Display configured DNS nameservers from resolv.conf
echo -e "\n List Of DNS Servers "
echo "-------------------------"
grep nameserver /etc/resolv.conf

# Show the order the system uses to resolve hostnames (files, dns, etc.)
echo -e "\n Hostname Resolution Order "
echo "---------------------------"
grep "^hosts" /etc/nsswitch.conf

# Display all static hostname-to-IP mappings
echo -e "\n Display /etc/hosts Content"
echo "---------------------------"
cat /etc/hosts

# Show the default gateway used for outbound traffic
echo -e "\n Show Default Gateway "
echo "------------------------"
ip r | grep "default"

#============================================
# Section 3: Connectivity Tests
# Ping tests to verify network connectivity:
# - Ping the server on the red network (172.16.30.13)
# - Ping the client on the red network (172.16.31.13)
# - Ping the default gateway on the blue network
#============================================

echo -e "\n Section 3: Connectivity Tests"
echo "---------------------------------"

# Ping test 1: Reach the server on the red network
echo -e "\n PINGING mir00015-SRV.example13.lab"
if ping -c 4 172.16.30.13 ; then
    echo -e "\n Successfully pinged mir00015-SRV.example13.lab "
else
    echo -e "\n THE PING FAILED YOU CANT REACH mir00015-SRV.example13.lab "
fi

# Ping test 2: Reach the client on the red network
echo -e "\n PINGING mir00015-CLT.example13.lab"
if ping -c 4 172.16.31.13 ; then
    echo -e "\n Successfully pinged mir00015-CLT.example13.lab "
else
    echo -e "\n THE PING FAILED YOU CANT REACH mir00015-CLT.example13.lab "
fi

# Ping test 3: Reach the default gateway on the blue network
# Extract the gateway IP dynamically from the routing table
echo -e "\n PINGING the default gateway on the blue network "
default_gateway=$(ip r | awk '/default via/ {print $3}')

if ping -c 4 $default_gateway; then
    echo -e "\n Successfully pinged the default gateway"
else
    echo -e "\n You failed to ping the default gateway "
fi
