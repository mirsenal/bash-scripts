#!/bin/bash
# iptables_rules.sh - CST8246 NetUtils demo
# Grant port 49999 to the client network, deny it to the server network.
# Author: <your name>   Date: 2026-09-28

if [ "$EUID" -ne 0 ]; then
    echo "Run as root: sudo $0"
    exit 1
fi

# ---- Variables ----
CLIENT_NET="172.16.31.0/24"
SERVER_NET="172.16.30.0/24"
PORT=49999

# ---- Clean start ----
iptables -F
iptables -P INPUT ACCEPT

# ---- Rules ----
# Grant access to the service from the client network
iptables -A INPUT -s "$CLIENT_NET" -p tcp --dport "$PORT" -j ACCEPT
# Deny access to the service from the server network
iptables -A INPUT -s "$SERVER_NET" -p tcp --dport "$PORT" -j REJECT

# ---- Show result ----
iptables -vnL INPUT --line-numbers