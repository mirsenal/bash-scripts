#!/bin/bash -u

#============================================
# Script Name: testnet.sh
# Purpose : summarize network settings and display results
# Date : 21/09/2026
# Author : Arslane Mir
# Version : 2.0 - Interactive menu using case
#============================================

#============================================
# Function: service_check
# Check that key network services are in the expected state
#============================================
service_check() {
    echo -e "\n========================================"
    echo "   Section 1: Service Status Check"
    echo -e "========================================\n"

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
}

#============================================
# Function: network_config
# Display current network settings
#============================================
network_config() {
    echo -e "\n========================================"
    echo "   Section 2: Network Configuration"
    echo -e "========================================\n"

    # Show IP addresses for the blue (ens160) and red (ens224) interfaces
    echo -e "\n IP Addresses"
    echo "-------------------"
    ip -br a | grep -E "ens160|ens224"

    # Display configured DNS nameservers from resolv.conf
    echo -e "\n List Of DNS Servers"
    echo "-------------------------"
    grep nameserver /etc/resolv.conf

    # Show the order the system uses to resolve hostnames
    echo -e "\n Hostname Resolution Order"
    echo "---------------------------"
    grep "^hosts" /etc/nsswitch.conf

    # Display all static hostname-to-IP mappings
    echo -e "\n Display /etc/hosts Content"
    echo "---------------------------"
    cat /etc/hosts

    # Show the default gateway used for outbound traffic
    echo -e "\n Show Default Gateway"
    echo "------------------------"
    ip r | grep "default"
}

#============================================
# Function: connectivity_tests
# Ping tests to verify network connectivity
#============================================
connectivity_tests() {
    echo -e "\n========================================"
    echo "   Section 3: Connectivity Tests"
    echo -e "========================================\n"

    # Ping test 1: Reach the server on the red network
    echo -e "\n PINGING mir00015-SRV.example13.lab"
    if ping -c 4 172.16.30.13 ; then
        echo -e "\n Successfully pinged mir00015-SRV.example13.lab"
    else
        echo -e "\n THE PING FAILED YOU CANT REACH mir00015-SRV.example13.lab"
    fi

    # Ping test 2: Reach the client on the red network
    echo -e "\n PINGING mir00015-CLT.example13.lab"
    if ping -c 4 172.16.31.13 ; then
        echo -e "\n Successfully pinged mir00015-CLT.example13.lab"
    else
        echo -e "\n THE PING FAILED YOU CANT REACH mir00015-CLT.example13.lab"
    fi

    # Ping test 3: Reach the default gateway on the blue network
    echo -e "\n PINGING the default gateway on the blue network"
    default_gateway=$(ip r | awk '/default via/ {print $3}')

    if ping -c 4 $default_gateway; then
        echo -e "\n Successfully pinged the default gateway"
    else
        echo -e "\n You failed to ping the default gateway"
    fi
}

#============================================
# Function: show_menu
# Display the interactive menu
#============================================
show_menu() {
    echo ""
    echo "========================================"
    echo "   testnet.sh - Network Verification"
    echo "   Author: Arslane Mir | v2.0"
    echo "========================================"
    echo ""
    echo "  1) Service Status Check"
    echo "  2) Network Configuration Display"
    echo "  3) Connectivity Tests"
    echo "  4) Run All Sections"
    echo "  5) Exit"
    echo ""
    echo -n "  Enter your choice [1-5]: "
}

#============================================
# Main: Interactive loop with case statement
#============================================
while true; do
    clear
    show_menu
    read choice

    case $choice in
        1)
            service_check
            ;;
        2)
            network_config
            ;;
        3)
            connectivity_tests
            ;;
        4)
            service_check
            network_config
            connectivity_tests
            ;;
        5)
            echo -e "\n Exiting testnet.sh. Goodbye!\n"
            exit 0
            ;;
        *)
            echo -e "\n Invalid option. Please enter a number between 1 and 5."
            ;;
    esac

    # Pause before showing the menu again
    echo ""
    read -p "  Press Enter to return to the menu..."
done