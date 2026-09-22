#!/bin/bash -u

#============================================
# Script Name: confignet.sh
# Purpose : Automate network configuration tasks
# Date : 21/09/2026
# Author : Arslane Mir
# Version : 1.0
#============================================

#============================================
# Prompt for magic number and system type
# These values drive the IP and hostname setup
#============================================
get_info() {
    echo ""
    read -p "  Enter your magic number: " MAGIC
    echo ""
    echo "  Is this machine the server or the client?"
    echo "  1) Server"
    echo "  2) Client"
    echo ""
    read -p "  Enter your choice [1-2]: " SYS_TYPE

    case $SYS_TYPE in
        1)
            ROLE="SRV"
            RED_IP="172.16.30.${MAGIC}"
            ;;
        2)
            ROLE="CLT"
            RED_IP="172.16.31.${MAGIC}"
            ;;
        *)
            echo -e "\n  Invalid choice. Defaulting to Server."
            ROLE="SRV"
            RED_IP="172.16.30.${MAGIC}"
            ;;
    esac

    # Build the hostname from the student ID and magic number
    read -p "  Enter your student ID prefix (e.g. mir00015): " STUDENT_ID
    HOSTNAME="${STUDENT_ID}-${ROLE}.example${MAGIC}.lab"

    # Detect available network interfaces (exclude loopback)
    echo ""
    echo "  Detected network interfaces:"
    echo "  ----------------------------"
    # List all interfaces except lo, with their current state
    ip -br link | grep -v "^lo" | awk '{print "    " NR ") " $1 " - " $2}'
    echo ""

    # Store interface names in an array for selection
    mapfile -t IFACES < <(ip -br link | grep -v "^lo" | awk '{print $1}')

    # Let the user pick which interface is blue (DHCP / internet)
    read -p "  Which interface is the BLUE network (internet)? Enter the number: " BLUE_CHOICE
    BLUE_IF="${IFACES[$((BLUE_CHOICE - 1))]}"

    # Let the user pick which interface is red (static / isolated)
    read -p "  Which interface is the RED network (isolated)?  Enter the number: " RED_CHOICE
    RED_IF="${IFACES[$((RED_CHOICE - 1))]}"

    echo ""
    echo "  ========================================="
    echo "  Summary before applying:"
    echo "  Role       : $ROLE"
    echo "  Red IP     : $RED_IP"
    echo "  Blue iface : $BLUE_IF"
    echo "  Red iface  : $RED_IF"
    echo "  Hostname   : $HOSTNAME"
    echo "  ========================================="
    echo ""
    read -p "  Proceed? (y/n): " CONFIRM
    if [[ "$CONFIRM" != [yY] ]]; then
        echo "  Cancelled."
        return 1
    fi
    return 0
}

#============================================
# Section A: Security Configuration
# - Disable firewalld
# - Configure SELinux (enforcing, permissive, or disabled)
#============================================
configure_security() {
    echo -e "\n  [*] Configuring security settings..."

    # Stop and disable firewalld to avoid blocking lab traffic
    echo "  [*] Disabling firewalld..."
    sudo systemctl stop firewalld
    sudo systemctl disable firewalld

    # SELinux — let the user choose the desired state
    echo ""
    echo "  [*] SELinux is currently set to: $(getenforce)"
    echo ""
    echo "  How would you like to configure SELinux?"
    echo "  1) Enforcing  (most secure, default)"
    echo "  2) Permissive (logs violations but allows them)"
    echo "  3) Disabled   (requires a system reboot)"
    echo ""
    read -p "  Enter your choice [1-3]: " SELINUX_CHOICE

    case $SELINUX_CHOICE in
        1)
            sudo setenforce 1
            echo "  [+] SELinux set to enforcing"
            ;;
        2)
            sudo setenforce 0
            echo "  [+] SELinux set to permissive (runtime only)"
            ;;
        3)
            # Disabling SELinux requires editing the config file and rebooting
            sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
            echo ""
            echo "  [!] SELinux has been set to disabled in /etc/selinux/config."
            echo "  [!] You MUST reboot the system for this change to take effect."
            echo ""
            read -p "  Would you like to reboot now? (y/n): " REBOOT_CHOICE
            if [[ "$REBOOT_CHOICE" == [yY] ]]; then
                echo "  [*] Rebooting now..."
                sudo reboot
            else
                echo "  [*] Remember to reboot before continuing the lab."
            fi
            ;;
        *)
            echo "  [*] Invalid choice. SELinux left as-is."
            ;;
    esac

    echo -e "\n  [+] Security configuration complete."
}

#============================================
# Section B: User Account Creation
# - Create cst8246 user with wheel group
#============================================
configure_user() {
    echo -e "\n  [*] Configuring user account..."

    # Check if the user already exists
    if id "cst8246" &>/dev/null; then
        echo "  [*] User cst8246 already exists."
    else
        # Create user and set password
        sudo useradd cst8246
        echo "cst8246:cst8246" | sudo chpasswd
        echo "  [+] User cst8246 created with password cst8246"
    fi

    # Add to wheel group for sudo access
    sudo usermod -aG wheel cst8246
    echo "  [+] User cst8246 added to wheel group."
}

#============================================
# Section C-E: Network Interface Configuration
# - Blue network: DHCP (interface detected at startup)
# - Red network: Static IP (interface detected at startup)
#============================================
configure_network() {
    echo -e "\n  [*] Configuring network interfaces..."

    # Blue network — DHCP for internet access
    BLUE_CFG="/etc/sysconfig/network-scripts/ifcfg-${BLUE_IF}"
    echo "  [*] Writing blue network config ($BLUE_IF - DHCP)..."
    sudo bash -c "cat > $BLUE_CFG" <<EOF
######### BLUE NETWORK - DHCP
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=dhcp
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=no
NAME=${BLUE_IF}
DEVICE=${BLUE_IF}
ONBOOT=yes
EOF
    echo "  [+] $BLUE_CFG written."

    # Red network — static IP for the isolated internal network
    RED_CFG="/etc/sysconfig/network-scripts/ifcfg-${RED_IF}"
    echo "  [*] Writing red network config ($RED_IF - Static: $RED_IP)..."
    sudo bash -c "cat > $RED_CFG" <<EOF
######### RED NETWORK - STATIC
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=none
IPADDR=$RED_IP
NETMASK=255.255.0.0
NETWORK=172.16.0.0
BROADCAST=172.16.255.255
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=no
NAME=${RED_IF}
DEVICE=${RED_IF}
ONBOOT=yes
EOF
    echo "  [+] $RED_CFG written."

    # Restart NetworkManager to apply changes
    echo "  [*] Restarting NetworkManager..."
    sudo systemctl restart NetworkManager
    echo "  [+] NetworkManager restarted."
}

#============================================
# Section G: Hostname & /etc/hosts
# - Set the hostname using hostnamectl
# - Add entries to /etc/hosts for both machines
#============================================
configure_hostname() {
    echo -e "\n  [*] Setting hostname to $HOSTNAME..."
    sudo hostnamectl set-hostname "$HOSTNAME"
    echo "  [+] Hostname set to: $(hostname)"

    # Add static entries to /etc/hosts for name resolution on the red network
    echo -e "\n  [*] Updating /etc/hosts..."

    SERVER_IP="172.16.30.${MAGIC}"
    CLIENT_IP="172.16.31.${MAGIC}"
    SRV_HOST="${STUDENT_ID}-SRV.example${MAGIC}.lab"
    CLT_HOST="${STUDENT_ID}-CLT.example${MAGIC}.lab"

    # Only add entries if they don't already exist
    if ! grep -q "$SRV_HOST" /etc/hosts; then
        echo "$SERVER_IP    $SRV_HOST" | sudo tee -a /etc/hosts > /dev/null
        echo "  [+] Added $SERVER_IP    $SRV_HOST"
    else
        echo "  [*] $SRV_HOST already in /etc/hosts"
    fi

    if ! grep -q "$CLT_HOST" /etc/hosts; then
        echo "$CLIENT_IP    $CLT_HOST" | sudo tee -a /etc/hosts > /dev/null
        echo "  [+] Added $CLIENT_IP    $CLT_HOST"
    else
        echo "  [*] $CLT_HOST already in /etc/hosts"
    fi
}

#============================================
# Function: show_menu
#============================================
show_menu() {
    echo ""
    echo "========================================"
    echo "   confignet.sh - Network Setup"
    echo "   Author: Arslane Mir | v1.0"
    echo "========================================"
    echo ""
    echo "  1) Security Config (firewalld, SELinux)"
    echo "  2) Create Lab User (cst8246)"
    echo "  3) Configure Network Interfaces"
    echo "  4) Set Hostname & /etc/hosts"
    echo "  5) Run Full Setup (all of the above)"
    echo "  6) Exit"
    echo ""
    echo -n "  Enter your choice [1-6]: "
}

#============================================
# Main: Interactive loop with case statement
#============================================

# Gather info once at startup
get_info || exit 0

while true; do
    clear
    show_menu
    read choice

    case $choice in
        1)
            configure_security
            ;;
        2)
            configure_user
            ;;
        3)
            configure_network
            ;;
        4)
            configure_hostname
            ;;
        5)
            configure_security
            configure_user
            configure_network
            configure_hostname
            echo -e "\n  [+] Full setup complete!"
            ;;
        6)
            echo -e "\n  Exiting confignet.sh. Goodbye!\n"
            exit 0
            ;;
        *)
            echo -e "\n  Invalid option. Please enter a number between 1 and 6."
            ;;
    esac

    echo ""
    read -p "  Press Enter to return to the menu..."
done