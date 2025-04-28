# Network Scanner

A cross-platform network scanning utility for discovering and analyzing devices on any IPv4 subnet.

## Overview

This tool allows system administrators, network engineers, and security professionals to quickly scan subnets, discover active hosts, resolve hostnames, and optionally scan for open ports - all with a single command. The utility is designed to work across Linux, macOS, and other UNIX-like operating systems without modification.

## Features

- Fast parallel scanning of entire IPv4 subnets
- Cross-platform compatibility (Linux, macOS, BSD, etc.)
- Optional port scanning for discovered hosts
- Hostname resolution
- Colorized terminal output with progress indicators
- Detailed scan reports
- Customizable scan parameters

## Installation

1. Clone this repository or download the project files:
   ```
   git clone https://github.com/username/network-scanner.git
   cd network-scanner
   ```

2. Make the script executable:
   ```
   chmod +x network_scanner.sh
   ```

## Usage

Basic usage:
```
./network_scanner.sh <subnet-prefix>
```

Example:
```
./network_scanner.sh 192.168.1
```

With options:
```
./network_scanner.sh 10.0.1 --ports --timeout 2 --parallel 15
```

Available options:
- `--ports`: Enable port scanning for discovered hosts
- `--timeout <seconds>`: Set ping timeout (default: 1)
- `--count <number>`: Set ping count (default: 1)
- `--parallel <number>`: Set maximum parallel processes (default: 10)

## Examples

### Class A Network
```bash
./network_scanner.sh 10.1.5 --ports
```

### Class B Network
```bash
./network_scanner.sh 172.16.24 --timeout 2
```

### Class C Network
```bash
./network_scanner.sh 192.168.0 --count 2
```

## Sample Output

Terminal output:
```
Starting network scan of 192.168.1.0/24
This may take some time. Please wait...
09:43:21 - 192.168.1.1 (router.home) is ONLINE
  Scanning ports on 192.168.1.1...
  Open ports:
    80/tcp HTTP
    443/tcp HTTPS

09:43:23 - 192.168.1.5 (desktop-PC.local) is ONLINE
  Scanning ports on 192.168.1.5...
  Open ports:
    22/tcp SSH

Scan complete! Results saved in scan_results_192.168.1.txt
Summary:
  Total hosts scanned: 254
  Online hosts: 2
  Offline hosts: 252
  Duration: 45 seconds
```

## Requirements

- Bash shell
- Basic networking utilities: `ping`
- Optional: `nmap` or `nc` for port scanning

## License

This project is licensed under the MIT License - see the LICENSE file for details.
