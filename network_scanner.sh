#!/bin/bash
#
# Enhanced Network Scanner Script
# This script scans a subnet for online hosts with improved features:
# - Parallel processing for faster scanning
# - OS compatibility across Linux, macOS, and other UNIX-like systems
# - Hostname resolution
# - Optional port scanning 
# - Progress indicators
# - Detailed summary
# - Colorized output
# - Parameter customization
#
# Usage: ./network_scanner.sh <subnet-prefix> [options]
# Example: ./network_scanner.sh 192.168.1 --ports --timeout 2

# Define colors for terminal output if supported
if [[ -t 1 ]]; then
    GREEN="\033[0;32m"
    RED="\033[0;31m"
    YELLOW="\033[0;33m"
    BLUE="\033[0;34m"
    RESET="\033[0m"
else
    GREEN=""
    RED=""
    YELLOW=""
    BLUE=""
    RESET=""
fi

# Default parameters
PING_COUNT=1
PING_TIMEOUT=1
SCAN_PORTS=false
MAX_PARALLEL=10
HOSTS_PER_PROGRESS=10

# Function to display usage information
usage() {
    echo "Usage: $0 <subnet-prefix> [options]"
    echo "Example: $0 192.168.1 --ports --timeout 2"
    echo ""
    echo "Options:"
    echo "  --ports           Scan common ports on discovered hosts"
    echo "  --timeout <sec>   Set ping timeout in seconds (default: 1)"
    echo "  --count <num>     Set ping count (default: 1)"
    echo "  --parallel <num>  Set maximum parallel processes (default: 10)"
    echo ""
    exit 1
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to get hostname - works on different OS
get_hostname() {
    local ip=$1
    local hostname=""
    
    # Try different hostname resolution methods based on OS
    if command_exists nslookup; then
        hostname=$(nslookup "$ip" 2>/dev/null | grep -E "name =|Address:" | tail -1 | awk '{print $NF}' | sed 's/\.$//')
    elif command_exists host; then
        hostname=$(host "$ip" 2>/dev/null | awk '/domain name pointer/ {print $NF}' | sed 's/\.$//')
    fi
    
    # If hostname resolution failed, return "Unknown"
    if [ -z "$hostname" ] || [[ "$hostname" == *"NXDOMAIN"* ]]; then
        hostname="Unknown"
    fi
    
    echo "$hostname"
}

# Function to scan ports - uses nc if available, otherwise falls back
scan_ports() {
    local ip=$1
    local output=""
    
    if command_exists nmap; then
        output=$(nmap -F --open "$ip" 2>/dev/null | grep -E "^[0-9]+/tcp" | awk '{print $1 " " $3}')
    elif command_exists nc; then
        output=""
        for port in 21 22 23 25 53 80 110 143 443 445 3306 3389 8080; do
            if nc -z -w 1 "$ip" "$port" >/dev/null 2>&1; then
                service="unknown"
                case $port in
                    21) service="FTP" ;;
                    22) service="SSH" ;;
                    23) service="Telnet" ;;
                    25) service="SMTP" ;;
                    53) service="DNS" ;;
                    80) service="HTTP" ;;
                    110) service="POP3" ;;
                    143) service="IMAP" ;;
                    443) service="HTTPS" ;;
                    445) service="SMB" ;;
                    3306) service="MySQL" ;;
                    3389) service="RDP" ;;
                    8080) service="HTTP-ALT" ;;
                esac
                output="${output}${port}/tcp ${service}\n"
            fi
        done
    else
        output="Port scanning not available (requires nmap or nc)"
    fi
    
    # Return port scan results
    echo -e "$output"
}

# Function to check if a host is online
check_host() {
    local ip=$1
    local result_file=$2
    local timestamp=$(date +"%T")
    
    # Use ping with parameters that work across different OS
    if ping -c $PING_COUNT -W $PING_TIMEOUT "$ip" >/dev/null 2>&1 || 
       ping -c $PING_COUNT -t $PING_TIMEOUT "$ip" >/dev/null 2>&1; then
        # Host is online
        local hostname=$(get_hostname "$ip")
        echo -e "${GREEN}${timestamp} - ${ip} (${hostname}) is ONLINE${RESET}" | tee -a "$result_file"
        
        # Perform port scan if requested
        if [[ "$SCAN_PORTS" == true ]]; then
            echo "  ${BLUE}Scanning ports on $ip...${RESET}" | tee -a "$result_file"
            local port_scan=$(scan_ports "$ip")
            if [[ -n "$port_scan" ]]; then
                echo -e "  ${BLUE}Open ports:${RESET}" | tee -a "$result_file"
                echo -e "$port_scan" | while read line; do
                    echo "    $line" | tee -a "$result_file"
                done
            else
                echo "  ${BLUE}No open ports found${RESET}" | tee -a "$result_file"
            fi
        fi
        
        # Track online hosts
        echo "$ip" >> "$TEMP_DIR/online_hosts.txt"
    else
        # Host is offline
        echo -e "${RED}${timestamp} - ${ip} is OFFLINE${RESET}" >> "$result_file"
    fi
    
    # Update progress counter
    echo "." >> "$TEMP_DIR/progress.txt"
}

# Parse command line arguments
if [ $# -lt 1 ]; then
    usage
fi

SUBNET="$1"
shift

# Validate subnet format
if ! [[ "$SUBNET" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo "${RED}Error: Invalid subnet format. Example: 192.168.1${RESET}"
    usage
fi

# Process options
while [[ $# -gt 0 ]]; do
    case "$1" in
        --ports)
            SCAN_PORTS=true
            shift
            ;;
        --timeout)
            if [[ "$2" =~ ^[0-9]+$ ]]; then
                PING_TIMEOUT="$2"
                shift 2
            else
                echo "${RED}Error: Timeout must be a number${RESET}"
                usage
            fi
            ;;
        --count)
            if [[ "$2" =~ ^[0-9]+$ ]]; then
                PING_COUNT="$2"
                shift 2
            else
                echo "${RED}Error: Count must be a number${RESET}"
                usage
            fi
            ;;
        --parallel)
            if [[ "$2" =~ ^[0-9]+$ ]]; then
                MAX_PARALLEL="$2"
                shift 2
            else
                echo "${RED}Error: Parallel processes must be a number${RESET}"
                usage
            fi
            ;;
        *)
            echo "${RED}Error: Unknown option: $1${RESET}"
            usage
            ;;
    esac
done

# Verify required tools
if ! command_exists ping; then
    echo "${RED}Error: ping command not found${RESET}"
    exit 1
fi

# Create temporary directory for tracking progress
TEMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'netscan')
trap 'rm -rf "$TEMP_DIR"' EXIT

# Create output file
OUTPUT_FILE="scan_results_${SUBNET}.txt"
START_TIME=$(date +%s)

# Write header to output file
echo "Network Scan Report - $(date)" > "$OUTPUT_FILE"
echo "Scanning subnet: ${SUBNET}.0/24" >> "$OUTPUT_FILE"
echo "Ping count: $PING_COUNT, Timeout: $PING_TIMEOUT seconds" >> "$OUTPUT_FILE"
if [[ "$SCAN_PORTS" == true ]]; then
    echo "Port scanning: Enabled" >> "$OUTPUT_FILE"
else
    echo "Port scanning: Disabled" >> "$OUTPUT_FILE"
fi
echo "--------------------------------------" >> "$OUTPUT_FILE"

# Display scan start message
echo -e "${YELLOW}Starting network scan of ${SUBNET}.0/24${RESET}"
echo -e "${YELLOW}This may take some time. Please wait...${RESET}"

# Create progress tracking files
touch "$TEMP_DIR/progress.txt"
touch "$TEMP_DIR/online_hosts.txt"

# Run the scan using background processes with control for maximum parallel jobs
for host in $(seq 1 254); do
    # Limit number of parallel processes
    while [[ $(jobs -r | wc -l) -ge $MAX_PARALLEL ]]; do
        sleep 0.1
    done
    
    # Run host check in background
    ip="${SUBNET}.${host}"
    check_host "$ip" "$OUTPUT_FILE" &
    
    # Show progress indicator
    progress=$(wc -l < "$TEMP_DIR/progress.txt")
    if [[ $((progress % HOSTS_PER_PROGRESS)) -eq 0 ]]; then
        percent=$((progress * 100 / 254))
        echo -ne "${YELLOW}Progress: ${percent}% (${progress}/254)${RESET}\r"
    fi
done

# Wait for all background processes to complete
wait

# Calculate scan statistics
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
ONLINE_COUNT=$(wc -l < "$TEMP_DIR/online_hosts.txt" 2>/dev/null || echo 0)
OFFLINE_COUNT=$((254 - ONLINE_COUNT))

# Write summary to output file
echo "" >> "$OUTPUT_FILE"
echo "--------------------------------------" >> "$OUTPUT_FILE"
echo "Scan Summary:" >> "$OUTPUT_FILE"
echo "  Total hosts scanned: 254" >> "$OUTPUT_FILE"
echo "  Online hosts: $ONLINE_COUNT" >> "$OUTPUT_FILE"
echo "  Offline hosts: $OFFLINE_COUNT" >> "$OUTPUT_FILE"
echo "  Duration: ${DURATION} seconds" >> "$OUTPUT_FILE"
echo "  Scan completed: $(date)" >> "$OUTPUT_FILE"

# Display summary in terminal
echo -e "${YELLOW}Scan complete! Results saved in ${OUTPUT_FILE}${RESET}"
echo -e "${GREEN}Summary:${RESET}"
echo -e "  ${GREEN}Total hosts scanned: 254${RESET}"
echo -e "  ${GREEN}Online hosts: ${ONLINE_COUNT}${RESET}"
echo -e "  ${RED}Offline hosts: ${OFFLINE_COUNT}${RESET}"
echo -e "  ${BLUE}Duration: ${DURATION} seconds${RESET}"

# List online hosts if any
if [[ $ONLINE_COUNT -gt 0 ]]; then
    echo -e "${GREEN}Online hosts:${RESET}"
    cat "$TEMP_DIR/online_hosts.txt" | sort -t. -k1,1n -k2,2n -k3,3n -k4,4n | while read ip; do
        hostname=$(get_hostname "$ip")
        echo -e "  ${GREEN}${ip} (${hostname})${RESET}"
    done
fi

# Clean up temporary files
rm -rf "$TEMP_DIR"
