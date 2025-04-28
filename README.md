# Network-Scanner
The Local Network Scanner is a simple yet powerful Bash script that scans a given subnet (e.g., 192.168.1.0/24) and identifies all active hosts on the network.  This project was designed to:  Strengthen knowledge of IP addressing, ICMP protocol, and subnetting.  Build confidence in Bash scripting using loops, conditionals, and network utilities.


# Local Network Scanner (Bash Project)

## 📋 Description

The Local Network Scanner is a Bash script that scans a given subnet and identifies active (online) hosts by sending ICMP echo requests (pings). It is designed to help users understand basic networking concepts like IP addressing, subnetting, and automation with Bash scripting.

---

## 🚀 Features
- Accepts **dynamic subnet input** from the user.
- Scans all IPs in a **/24 subnet** (e.g., 192.168.1.1 to 192.168.1.254).
- Identifies online and offline hosts.
- Saves the scan results to a timestamped output file.
- Lightweight and simple, no external dependencies required.

---

## 🛠️ Requirements
- Linux environment (Ubuntu, Debian, WSL, Kali, etc.)
- Bash shell
- Basic network access (ICMP not blocked)

---

## 🧰 Installation

No installation required. Simply clone/download the script.

```bash
git clone https://github.com/yourusername/network-scanner-bash.git
cd network-scanner-bash
chmod +x scanner.sh
