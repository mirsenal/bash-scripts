# Linux Lab Scripts, Autumn 2026

Bash scripts I write for my Linux lab assignments this semester at **Algonquin College** (CST8246, Network Services).

Each lab has its own folder containing the scripts built for that lab. Most scripts are menu-driven and walk you through each step.

## Structure

### Lab 1: Network Client, building the lab environment

Scripts that set up and verify the two lab VMs (server and client), which are connected by two networks:

- **BLUE** network: DHCP, internet access
- **RED** network: isolated, static IPs. Server `172.16.30.MN`, client `172.16.31.MN`

| Script | Purpose |
|---|---|
| `confinet.sh` | Interactive menu that configures a fresh VM as the **server** or the **client**. It asks for the magic number, role, student ID, and which interfaces are BLUE and RED, then: disables firewalld and sets SELinux mode; creates the `cst8246` user in the `wheel` group; writes the ifcfg files (BLUE = DHCP, RED = static `/16`) and restarts NetworkManager; sets the hostname (`<id>-SRV/CLT.example<MN>.lab`) and adds both machines to `/etc/hosts`. |
| `testnet.sh` | Interactive menu that verifies the setup: service status (NetworkManager, firewalld, iptables policies, SELinux), network configuration (IPs, DNS servers, `nsswitch.conf` lookup order, `/etc/hosts`, default gateway), and connectivity tests (pings the server, the client, and the BLUE gateway). |

### Lab 2: Network Tools & Automated Firewall Configuration

| Script | Purpose |
|---|---|
| `iptables_rules.sh` | Configures iptables to **grant** access to TCP port 49999 from the client network (`172.16.31.0/24`) and **deny** it from the server network (`172.16.30.0/24`). Flushes existing rules first and lists the result. |

## Usage

Scripts are written for RHEL-based systems and most need root privileges.

```bash
chmod +x script_name.sh
sudo ./script_name.sh
```

> ⚠️ Some scripts (like the iptables ones) change system configuration such as firewall rules. They are meant for the lab VMs, so read a script before running it anywhere else.

## Notes

- Scripts use LF line endings (enforced with `.gitattributes`) so they run correctly on Linux.
- Firewall rules applied by scripts are in memory only unless saved with `iptables-save`.

## Author

Arslane Mir, Algonquin College, Autumn 2026
