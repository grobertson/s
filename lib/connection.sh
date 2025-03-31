#!/bin/bash

# SSH connection management for the s tool

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Connect to a remote host
connect() {
    local host="$1"
    local user="$2"
    local key_file="$3"
    local port="${4:-22}"
    local timeout="${5:-5}"
    local max_retries="${6:-3}"
    local port_forward="$7"
    
    # Validate inputs
    validate_input "$port" "^[0-9]+$" "Invalid port number: $port"
    validate_input "$timeout" "^[0-9]+$" "Invalid timeout value: $timeout"
    validate_input "$max_retries" "^[0-9]+$" "Invalid retry count: $max_retries"
    
    # Build SSH command
    local ssh_cmd="ssh"
    ssh_cmd+=" -p $port"
    ssh_cmd+=" -o ConnectTimeout=$timeout"
    ssh_cmd+=" -o ServerAliveInterval=60"
    ssh_cmd+=" -o ServerAliveCountMax=3"
    
    if [ -n "$key_file" ]; then
        ssh_cmd+=" -i $key_file"
    fi
    
    # Add port forwarding if specified
    if [ -n "$port_forward" ]; then
        ssh_cmd+=" -L $port_forward"
    fi
    
    ssh_cmd+=" $user@$host"
    
    # Attempt connection with retries
    local retry_count=0
    while [ $retry_count -lt $max_retries ]; do
        log $LOG_LEVEL_INFO "Connecting to $user@$host (attempt $((retry_count + 1))/$max_retries)"
        
        if $ssh_cmd; then
            log $LOG_LEVEL_INFO "Connection successful"
            return $EXIT_SUCCESS
        fi
        
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            local wait_time=$((retry_count * 2))
            log $LOG_LEVEL_WARN "Connection failed, retrying in $wait_time seconds..."
            sleep $wait_time
        fi
    done
    
    error_exit "Failed to connect after $max_retries attempts" $EXIT_SSH_ERROR
}

# List active SSH connections
list_connections() {
    local user="$1"
    
    echo -e "${BOLD}Active SSH Connections:${NC}"
    if [ -n "$user" ]; then
        ps aux | grep "ssh.*$user@" | grep -v grep | while read -r line; do
            echo -e "${CYAN}$line${NC}"
        done
    else
        ps aux | grep "ssh" | grep -v grep | while read -r line; do
            echo -e "${CYAN}$line${NC}"
        done
    fi
}

# Kill SSH connection
kill_connection() {
    local pid="$1"
    
    # Validate input
    validate_input "$pid" "^[0-9]+$" "Invalid process ID: $pid"
    
    # Check if process exists
    if ! ps -p "$pid" > /dev/null; then
        error_exit "Process $pid not found"
    fi
    
    # Kill the process
    log $LOG_LEVEL_INFO "Killing SSH connection (PID: $pid)"
    if ! kill "$pid"; then
        error_exit "Failed to kill process $pid"
    fi
    
    log $LOG_LEVEL_INFO "SSH connection terminated"
}

# Setup port forwarding
setup_port_forward() {
    local local_port="$1"
    local remote_host="$2"
    local remote_port="$3"
    local user="$4"
    local key_file="$5"
    
    # Validate inputs
    validate_input "$local_port" "^[0-9]+$" "Invalid local port: $local_port"
    validate_input "$remote_port" "^[0-9]+$" "Invalid remote port: $remote_port"
    
    # Build port forwarding command
    local port_forward="$local_port:$remote_host:$remote_port"
    
    # Start port forwarding in background
    log $LOG_LEVEL_INFO "Setting up port forwarding: $port_forward"
    if ! ssh -N -L "$port_forward" -i "$key_file" "$user@$remote_host" & then
        error_exit "Failed to setup port forwarding"
    fi
    
    local pid=$!
    log $LOG_LEVEL_INFO "Port forwarding started (PID: $pid)"
    
    # Cache the PID for later use
    cache_set "port_forward_$local_port" "$pid"
    
    return $pid
}

# Stop port forwarding
stop_port_forward() {
    local local_port="$1"
    
    # Get cached PID
    local pid=$(cache_get "port_forward_$local_port")
    
    if [ -n "$pid" ]; then
        kill_connection "$pid"
        cache_set "port_forward_$local_port" ""
    else
        log $LOG_LEVEL_WARN "No port forwarding found for port $local_port"
    fi
}

# Test connection
test_connection() {
    local host="$1"
    local user="$2"
    local key_file="$3"
    local port="${4:-22}"
    local timeout="${5:-5}"
    
    # Validate inputs
    validate_input "$port" "^[0-9]+$" "Invalid port number: $port"
    validate_input "$timeout" "^[0-9]+$" "Invalid timeout value: $timeout"
    
    # Build SSH command
    local ssh_cmd="ssh"
    ssh_cmd+=" -p $port"
    ssh_cmd+=" -o ConnectTimeout=$timeout"
    ssh_cmd+=" -o BatchMode=yes"
    
    if [ -n "$key_file" ]; then
        ssh_cmd+=" -i $key_file"
    fi
    
    ssh_cmd+=" $user@$host"
    ssh_cmd+=" exit"
    
    # Test connection
    log $LOG_LEVEL_INFO "Testing connection to $user@$host"
    if ! $ssh_cmd; then
        error_exit "Connection test failed" $EXIT_SSH_ERROR
    fi
    
    log $LOG_LEVEL_INFO "Connection test successful"
}

# Get connection status
get_connection_status() {
    local host="$1"
    local user="$2"
    local key_file="$3"
    local port="${4:-22}"
    
    # Validate inputs
    validate_input "$port" "^[0-9]+$" "Invalid port number: $port"
    
    # Check if connection is active
    if ps aux | grep -q "ssh.*$user@$host"; then
        echo -e "${GREEN}Connected${NC}"
    else
        # Test connection
        if test_connection "$host" "$user" "$key_file" "$port"; then
            echo -e "${YELLOW}Available${NC}"
        else
            echo -e "${RED}Unavailable${NC}"
        fi
    fi
} 