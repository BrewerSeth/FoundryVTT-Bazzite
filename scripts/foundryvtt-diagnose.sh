#!/usr/bin/env bash
#
# foundryvtt-diagnose.sh - System Diagnostics & Status Report for FoundryVTT on Bazzite
#
# This script generates comprehensive diagnostic reports for FoundryVTT installations
# on Bazzite Linux. It checks host system, Distrobox containers, FoundryVTT instances,
# network status, and resource usage. Reports are formatted for both human readability
# and AI assistant parsing.
#
# Usage:
#   ./foundryvtt-diagnose.sh [OPTIONS]
#
# Options:
#   --quick, -q          Quick health check (fast summary)
#   --json, -j          Output in JSON format
#   --redact, -r        Redact sensitive information
#   --output FILE, -o   Save output to file
#   --help, -h          Show help
#   --version, -v       Show version
#
# Exit Codes:
#   0  - Healthy
#   1  - Script error
#   2  - Degraded (warnings)
#   3  - Critical (errors)
#   4  - FoundryVTT not installed
#
# Project: FoundryVTT-Bazzite
# License: MIT
# Repository: https://github.com/BrewerSeth/FoundryVTT-Bazzite
#

# Script version
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME="foundryvtt-diagnose"

# Default configuration
readonly CONFIG_DIR="${HOME}/.config/foundryvtt-bazzite"
readonly CONFIG_FILE="${CONFIG_DIR}/config"
readonly LOCK_FILE="/tmp/foundryvtt-diagnose.lock"

# Exit codes
readonly EXIT_HEALTHY=0
readonly EXIT_ERROR=1
readonly EXIT_DEGRADED=2
readonly EXIT_CRITICAL=3
readonly EXIT_NOT_INSTALLED=4

# Performance thresholds
readonly CPU_WARNING=80
readonly CPU_CRITICAL=95
readonly MEM_WARNING=85
readonly MEM_CRITICAL=95
readonly DISK_WARNING=90
readonly DISK_CRITICAL=95

# Timeout settings
readonly TIMEOUT_SHORT=5
readonly TIMEOUT_MEDIUM=10
readonly TIMEOUT_LONG=30

# Global state
SCRIPT_START_TIME=""
OUTPUT_FILE=""
QUICK_MODE=false
JSON_MODE=false
REDACT_MODE=false
OVERALL_STATUS="HEALTHY"
declare -a SECTIONS=()

# =============================================================================
# T003: Error Handling & Strict Mode
# =============================================================================

set -euo pipefail

trap cleanup_on_exit EXIT
trap handle_interrupt INT TERM

cleanup_on_exit() {
    local exit_code=$?
    
    # Remove lock file
    if [[ -f "${LOCK_FILE}" ]]; then
        rm -f "${LOCK_FILE}"
    fi
    
    # Return the original exit code
    exit "${exit_code}"
}

handle_interrupt() {
    echo ""
    echo "[WARN] Diagnostic interrupted by user"
    exit ${EXIT_ERROR}
}

# =============================================================================
# T004: Colored Output Helpers
# =============================================================================

# Detect if stdout is a TTY
if [[ -t 1 ]]; then
    readonly IS_TTY=true
    readonly COLOR_RED='\033[0;31m'
    readonly COLOR_GREEN='\033[0;32m'
    readonly COLOR_YELLOW='\033[0;33m'
    readonly COLOR_BLUE='\033[0;34m'
    readonly COLOR_CYAN='\033[0;36m'
    readonly COLOR_BOLD='\033[1m'
    readonly COLOR_RESET='\033[0m'
else
    readonly IS_TTY=false
    readonly COLOR_RED=''
    readonly COLOR_GREEN=''
    readonly COLOR_YELLOW=''
    readonly COLOR_BLUE=''
    readonly COLOR_CYAN=''
    readonly COLOR_BOLD=''
    readonly COLOR_RESET=''
fi

info() {
    if [[ "${JSON_MODE}" == false ]]; then
        echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $1"
    fi
}

warn() {
    if [[ "${JSON_MODE}" == false ]]; then
        echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $1" >&2
    fi
}

error() {
    if [[ "${JSON_MODE}" == false ]]; then
        echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $1" >&2
    fi
}

success() {
    if [[ "${JSON_MODE}" == false ]]; then
        echo -e "${COLOR_GREEN}[OK]${COLOR_RESET} $1"
    fi
}

status_healthy() {
    if [[ "${JSON_MODE}" == false ]]; then
        echo -e "${COLOR_GREEN}🟢 HEALTHY${COLOR_RESET}"
    fi
}

status_warning() {
    if [[ "${JSON_MODE}" == false ]]; then
        echo -e "${COLOR_YELLOW}🟡 WARNING${COLOR_RESET}"
    fi
}

status_critical() {
    if [[ "${JSON_MODE}" == false ]]; then
        echo -e "${COLOR_RED}🔴 CRITICAL${COLOR_RESET}"
    fi
}

# =============================================================================
# T005: Bazzite Detection
# =============================================================================

check_bazzite() {
    if [[ ! -f /etc/os-release ]]; then
        return 1
    fi
    
    if grep -q "^ID=bazzite" /etc/os-release 2>/dev/null; then
        return 0
    fi
    
    return 1
}

require_bazzite() {
    if ! check_bazzite; then
        error "This script requires Bazzite Linux."
        local detected_os
        detected_os=$(grep "^ID=" /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')
        error "Detected OS: ${detected_os:-unknown}"
        error "Get Bazzite at: https://bazzite.gg"
        exit ${EXIT_ERROR}
    fi
}

# =============================================================================
# T006: Config File Reader
# =============================================================================

read_config() {
    if [[ ! -f "${CONFIG_FILE}" ]]; then
        return 1
    fi
    
    # Source the config file safely
    # shellcheck source=/dev/null
    set -a
    source "${CONFIG_FILE}" 2>/dev/null || true
    set +a
    
    return 0
}

get_config_value() {
    local key="$1"
    local default_value="${2:-}"
    
    if [[ -f "${CONFIG_FILE}" ]]; then
        grep "^${key}=" "${CONFIG_FILE}" 2>/dev/null | cut -d'=' -f2- | tr -d '"' || echo "${default_value}"
    else
        echo "${default_value}"
    fi
}

# =============================================================================
# T007: TTY Detection
# =============================================================================

auto_detect_format() {
    if [[ "${JSON_MODE}" == true ]]; then
        return
    fi
    
    # Auto-detect: JSON if piped, text if TTY
    if [[ "${IS_TTY}" == false ]]; then
        JSON_MODE=true
    fi
}

# =============================================================================
# T008: Exit Code Handler
# =============================================================================

set_overall_status() {
    local status="$1"
    
    case "${status}" in
        CRITICAL)
            OVERALL_STATUS="CRITICAL"
            ;;
        DEGRADED)
            if [[ "${OVERALL_STATUS}" != "CRITICAL" ]]; then
                OVERALL_STATUS="DEGRADED"
            fi
            ;;
        HEALTHY)
            # Only set to healthy if not already set to warning/critical
            ;;
    esac
}

get_exit_code() {
    case "${OVERALL_STATUS}" in
        HEALTHY)
            echo ${EXIT_HEALTHY}
            ;;
        DEGRADED)
            echo ${EXIT_DEGRADED}
            ;;
        CRITICAL)
            echo ${EXIT_CRITICAL}
            ;;
        *)
            echo ${EXIT_ERROR}
            ;;
    esac
}

# =============================================================================
# T009: File Locking for Concurrent Runs
# =============================================================================

acquire_lock() {
    local lock_pid=""
    
    if [[ -f "${LOCK_FILE}" ]]; then
        lock_pid=$(cat "${LOCK_FILE}" 2>/dev/null)
        if kill -0 "${lock_pid}" 2>/dev/null; then
            error "Another instance of the diagnostic script is already running (PID: ${lock_pid})"
            error "Wait for it to complete, or remove ${LOCK_FILE} if it crashed"
            exit ${EXIT_ERROR}
        else
            # Stale lock file
            rm -f "${LOCK_FILE}"
        fi
    fi
    
    echo $$ > "${LOCK_FILE}"
}

# =============================================================================
# Argument Parsing
# =============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --quick|-q)
                QUICK_MODE=true
                shift
                ;;
            --json|-j)
                JSON_MODE=true
                shift
                ;;
            --redact|-r)
                REDACT_MODE=true
                shift
                ;;
            --output|-o)
                if [[ -n "${2:-}" ]]; then
                    OUTPUT_FILE="$2"
                    shift 2
                else
                    error "--output requires a filename"
                    exit "${EXIT_ERROR}"
                fi
                ;;
            --help|-h)
                show_help
                exit ${EXIT_HEALTHY}
                ;;
            --version|-v)
                show_version
                exit ${EXIT_HEALTHY}
                ;;
            *)
                error "Unknown option: $1"
                show_help
                exit ${EXIT_ERROR}
                ;;
        esac
    done
}

show_help() {
    cat << 'EOF'
FoundryVTT System Diagnostics & Status Report

Usage: ./foundryvtt-diagnose.sh [OPTIONS]

Options:
  --quick, -q          Quick health check (fast summary)
  --json, -j          Output in JSON format
  --redact, -r        Redact sensitive information
  --output FILE, -o   Save output to file
  --help, -h          Show this help message
  --version, -v       Show version

Examples:
  ./foundryvtt-diagnose.sh                    # Full diagnostic report
  ./foundryvtt-diagnose.sh --quick            # Quick health check
  ./foundryvtt-diagnose.sh --json --output report.json
  ./foundryvtt-diagnose.sh --redact --output report.txt

Exit Codes:
  0  - Healthy
  1  - Script error
  2  - Degraded (warnings present)
  3  - Critical (errors present)
  4  - FoundryVTT not installed

For more information: https://github.com/BrewerSeth/FoundryVTT-Bazzite
EOF
}

show_version() {
    echo "${SCRIPT_NAME} version ${SCRIPT_VERSION}"
    echo "Feature 007: System Diagnostics & Status Report"
    echo "Part of FoundryVTT-Bazzite project"
}

# =============================================================================
# Report Generation Functions
# =============================================================================

start_report() {
    SCRIPT_START_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    if [[ "${JSON_MODE}" == true ]]; then
        echo "{"
        echo '  "generated_at": "'"${SCRIPT_START_TIME}"'",'
        echo '  "version": "'"${SCRIPT_VERSION}"'",'
        echo '  "overall_status": "'"${OVERALL_STATUS}"'",'
        echo '  "sections": {'
    else
        echo "============================================================"
        echo "FOUNDRYVTT SYSTEM DIAGNOSTICS REPORT"
        echo "============================================================"
        echo "Generated: ${SCRIPT_START_TIME}"
        echo "Version: ${SCRIPT_VERSION}"
        echo ""
    fi
}

end_report() {
    if [[ "${JSON_MODE}" == true ]]; then
        echo "  }"
        echo "}"
    else
        echo "============================================================"
        echo "OVERALL STATUS: ${OVERALL_STATUS}"
        echo "============================================================"
    fi
}

# =============================================================================
# Phase 3: Diagnostic Collection Functions (User Story 1)
# =============================================================================

# T011 [US1]: Host System Status Collection
collect_host_system() {
    local section_status="HEALTHY"
    local os_info=""
    local uptime_info=""
    local cpu_percent=""
    local mem_percent=""
    local disk_percent=""
    
    # Get OS info
    if [[ -f /etc/os-release ]]; then
        os_info=$(grep "^PRETTY_NAME=" /etc/os-release | cut -d'=' -f2- | tr -d '"')
    else
        os_info=$(uname -s)
    fi
    
    # Get uptime
    if command -v uptime &>/dev/null; then
        uptime_info=$(uptime -p 2>/dev/null || uptime | awk -F',' '{print $1}' | sed 's/.*up //')
    fi
    
    # Get CPU usage
    if command -v top &>/dev/null; then
        cpu_percent=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | cut -d',' -f1)
        # Handle different top output formats
        if [[ -z "$cpu_percent" ]] || [[ "$cpu_percent" == "0.0" ]]; then
            cpu_percent=$(top -bn1 | grep "%Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
        fi
    fi
    
    # Get memory usage
    if command -v free &>/dev/null; then
        mem_percent=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')
    fi
    
    # Get disk usage for /home
    if command -v df &>/dev/null; then
        disk_percent=$(df -h /home | tail -1 | awk '{print $5}' | tr -d '%')
    fi
    
    # Determine status based on thresholds (T012)
    if [[ -n "$cpu_percent" ]] && [[ "${cpu_percent%.*}" -ge $CPU_CRITICAL ]]; then
        section_status="CRITICAL"
        set_overall_status "CRITICAL"
    elif [[ -n "$mem_percent" ]] && [[ "$mem_percent" -ge $MEM_CRITICAL ]]; then
        section_status="CRITICAL"
        set_overall_status "CRITICAL"
    elif [[ -n "$disk_percent" ]] && [[ "$disk_percent" -ge $DISK_CRITICAL ]]; then
        section_status="CRITICAL"
        set_overall_status "CRITICAL"
    elif [[ -n "$cpu_percent" ]] && [[ "${cpu_percent%.*}" -ge $CPU_WARNING ]]; then
        section_status="DEGRADED"
        set_overall_status "DEGRADED"
    elif [[ -n "$mem_percent" ]] && [[ "$mem_percent" -ge $MEM_WARNING ]]; then
        section_status="DEGRADED"
        set_overall_status "DEGRADED"
    elif [[ -n "$disk_percent" ]] && [[ "$disk_percent" -ge $DISK_WARNING ]]; then
        section_status="DEGRADED"
        set_overall_status "DEGRADED"
    fi
    
    # Output based on format
    if [[ "${JSON_MODE}" == true ]]; then
        echo '    "host_system": {'
        echo '      "status": "'"$section_status"'",'
        echo '      "os": "'"$os_info"'",'
        echo '      "uptime": "'"${uptime_info:-unknown}"'",'
        echo '      "cpu_percent": "'"${cpu_percent:-unknown}"'",'
        echo '      "memory_percent": "'"${mem_percent:-unknown}"'",'
        echo '      "disk_percent": "'"${disk_percent:-unknown}"'"'
        echo '    },'
    else
        echo "============================================================"
        echo "HOST SYSTEM"
        echo "============================================================"
        echo "OS: ${os_info}"
        echo "Uptime: ${uptime_info:-unknown}"
        echo "CPU Usage: ${cpu_percent:-unknown}% $([[ -n "$cpu_percent" ]] && [[ "${cpu_percent%.*}" -ge $CPU_WARNING ]] && status_warning || echo "")"
        echo "Memory Usage: ${mem_percent:-unknown}% $([[ -n "$mem_percent" ]] && [[ "$mem_percent" -ge $MEM_WARNING ]] && status_warning || echo "")"
        echo "Disk Usage (/home): ${disk_percent:-unknown}% $([[ -n "$disk_percent" ]] && [[ "$disk_percent" -ge $DISK_WARNING ]] && status_warning || echo "")"
        echo "Status: $(case $section_status in HEALTHY) status_healthy ;; DEGRADED) status_warning ;; CRITICAL) status_critical ;; esac)"
        echo ""
    fi
}

# T013 [US1]: Distrobox Container Status
collect_container_status() {
    local section_status="HEALTHY"
    local container_name
    local container_image=""
    local container_state=""
    local container_uptime=""
    
    container_name=$(get_config_value "CONTAINER_NAME" "foundryvtt")
    
    # Check if container exists
    if ! command -v distrobox &>/dev/null; then
        section_status="CRITICAL"
        set_overall_status "CRITICAL"
        container_state="distrobox_not_found"
    elif timeout $TIMEOUT_SHORT distrobox list 2>/dev/null | grep -qE "\| *${container_name} +\|"; then
        # Container exists, get details
        container_state=$(timeout $TIMEOUT_SHORT podman inspect "${container_name}" --format '{{.State.Status}}' 2>/dev/null || echo "unknown")
        container_image=$(timeout $TIMEOUT_SHORT podman inspect "${container_name}" --format '{{.Config.Image}}' 2>/dev/null || echo "unknown")
        
        # T028: Handle container doesn't exist edge case
        if [[ "$container_state" == "running" ]]; then
            # Get uptime
            local started_at
            started_at=$(timeout $TIMEOUT_SHORT podman inspect "${container_name}" --format '{{.State.StartedAt}}' 2>/dev/null)
            if [[ -n "$started_at" ]]; then
                container_uptime=$(echo "Started: $started_at")
            fi
        elif [[ "$container_state" == "exited" ]]; then
            section_status="DEGRADED"
            set_overall_status "DEGRADED"
        fi
    else
        # T028: Container doesn't exist
        section_status="CRITICAL"
        set_overall_status "CRITICAL"
        container_state="missing"
    fi
    
    # Output
    if [[ "${JSON_MODE}" == true ]]; then
        echo '    "container": {'
        echo '      "status": "'"$section_status"'",'
        echo '      "name": "'"$container_name"'",'
        echo '      "image": "'"$container_image"'",'
        echo '      "state": "'"$container_state"'",'
        echo '      "uptime": "'"${container_uptime:-}"'"'
        echo '    },'
    else
        echo "============================================================"
        echo "DISTROBOX CONTAINER"
        echo "============================================================"
        echo "Name: ${container_name}"
        echo "Image: ${container_image:-N/A}"
        echo "State: ${container_state}"
        if [[ -n "$container_uptime" ]]; then
            echo "Uptime: ${container_uptime}"
        fi
        if [[ "$container_state" == "missing" ]]; then
            echo ""
            warn "Container '${container_name}' is missing!"
            echo "  Run the setup script to create it:"
            echo "    ./setup-foundryvtt.sh"
        fi
        echo "Status: $(case $section_status in HEALTHY) status_healthy ;; DEGRADED) status_warning ;; CRITICAL) status_critical ;; esac)"
        echo ""
    fi
}

# T014 [US1]: FoundryVTT Instance Status
collect_instance_status() {
    local section_status="HEALTHY"
    local container_name
    local foundry_version=""
    local service_state=""
    local service_enabled=""
    local port=""
    local port_listening=false
    local foundry_installed=true
    
    container_name=$(get_config_value "CONTAINER_NAME" "foundryvtt")
    port=$(get_config_value "PORT" "30000")
    
    # T029: Check if FoundryVTT is installed
    if [[ ! -f "${CONFIG_FILE}" ]]; then
        foundry_installed=false
        section_status="NOT_INSTALLED"
    else
        # Get version from config
        foundry_version=$(get_config_value "FOUNDRY_VERSION" "unknown")
        
        # T015: Check systemd service status
        if command -v systemctl &>/dev/null; then
            service_state=$(systemctl --user is-active "${container_name}.service" 2>/dev/null || echo "inactive")
            if systemctl --user is-enabled "${container_name}.service" &>/dev/null; then
                service_enabled="true"
            else
                service_enabled="false"
            fi
        fi
        
        # T016: Check if port is listening
        if command -v ss &>/dev/null; then
            if ss -tlnp 2>/dev/null | grep -q ":${port}"; then
                port_listening=true
            fi
        elif command -v netstat &>/dev/null; then
            if netstat -tlnp 2>/dev/null | grep -q ":${port}"; then
                port_listening=true
            fi
        fi
        
        # Determine status
        if [[ "$service_state" == "failed" ]]; then
            section_status="CRITICAL"
            set_overall_status "CRITICAL"
        elif [[ "$service_state" == "inactive" ]] && [[ "$service_enabled" == "true" ]]; then
            section_status="DEGRADED"
            set_overall_status "DEGRADED"
        elif [[ "$port_listening" == false ]] && [[ "$service_state" == "active" ]]; then
            section_status="DEGRADED"
            set_overall_status "DEGRADED"
        fi
    fi
    
    # Output
    if [[ "${JSON_MODE}" == true ]]; then
        if [[ "$foundry_installed" == true ]]; then
            echo '    "instance": {'
            echo '      "status": "'"$section_status"'",'
            echo '      "name": "'"$container_name"'",'
            echo '      "version": "'"$foundry_version"'",'
            echo '      "service_state": "'"$service_state"'",'
            echo '      "service_enabled": "'"$service_enabled"'",'
            echo '      "port": "'"$port"'",'
            echo '      "port_listening": "'"$port_listening"'"'
            echo '    },'
        else
            echo '    "instance": {'
            echo '      "status": "NOT_INSTALLED",'
            echo '      "message": "FoundryVTT not configured. Run setup script first."'
            echo '    },'
        fi
    else
        echo "============================================================"
        echo "FOUNDRYVTT INSTANCE"
        echo "============================================================"
        if [[ "$foundry_installed" == true ]]; then
            echo "Name: ${container_name}"
            echo "Version: ${foundry_version}"
            echo "Service: ${service_state} $([[ "$service_enabled" == "true" ]] && echo "(enabled)" || echo "(disabled)")"
            echo "Port: ${port} $([[ "$port_listening" == true ]] && echo "[LISTENING]" || echo "[NOT LISTENING]")"
            echo "Status: $(case $section_status in HEALTHY) status_healthy ;; DEGRADED) status_warning ;; CRITICAL) status_critical ;; esac)"
        else
            echo "Status: NOT INSTALLED"
            warn "FoundryVTT is not configured on this system."
            echo "  Run the setup script to install it:"
            echo "    ./setup-foundryvtt.sh"
            set_overall_status "NOT_INSTALLED"
        fi
        echo ""
    fi
}

# T016 [US1]: Network Status
collect_network_status() {
    local section_status="HEALTHY"
    local port
    local http_status=""
    local port_listening=false
    
    port=$(get_config_value "PORT" "30000")
    
    # Check port listening
    if command -v ss &>/dev/null; then
        if ss -tlnp 2>/dev/null | grep -q ":${port}"; then
            port_listening=true
        fi
    elif command -v netstat &>/dev/null; then
        if netstat -tlnp 2>/dev/null | grep -q ":${port}"; then
            port_listening=true
        fi
    fi
    
    # Check HTTP response
    if command -v curl &>/dev/null && [[ "$port_listening" == true ]]; then
        http_status=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${port}" 2>/dev/null || echo "")
    fi
    
    # Determine status
    if [[ "$port_listening" == false ]]; then
        section_status="CRITICAL"
        set_overall_status "CRITICAL"
    fi
    
    # Output
    if [[ "${JSON_MODE}" == true ]]; then
        echo '    "network": {'
        echo '      "status": "'"$section_status"'",'
        echo '      "port": "'"$port"'",'
        echo '      "port_listening": "'"$port_listening"'",'
        echo '      "http_status": "'"${http_status:-}"'"'
        echo '    }'
    else
        echo "============================================================"
        echo "NETWORK"
        echo "============================================================"
        echo "Port ${port}: $([[ "$port_listening" == true ]] && echo "LISTENING" || echo "NOT LISTENING")"
        if [[ -n "$http_status" ]]; then
            echo "HTTP Status: ${http_status}"
        fi
        echo "Status: $(case $section_status in HEALTHY) status_healthy ;; DEGRADED) status_warning ;; CRITICAL) status_critical ;; esac)"
        echo ""
    fi
}

# T018 [US1]: Host System Update Check
collect_host_updates() {
    local section_status="HEALTHY"
    local updates_available="unknown"
    local update_info=""
    local check_status="unknown"
    
    # Check with rpm-ostree
    if command -v rpm-ostree &>/dev/null; then
        if timeout $TIMEOUT_MEDIUM rpm-ostree status &>/dev/null; then
            if rpm-ostree status 2>/dev/null | grep -q "pending"; then
                updates_available="yes"
                update_info="Pending deployment available"
                check_status="available"
                section_status="DEGRADED"
                set_overall_status "DEGRADED"
            else
                updates_available="no"
                update_info="System up to date"
                check_status="none"
            fi
        else
            check_status="failed"
            update_info="Unable to check updates"
        fi
    else
        check_status="unavailable"
        update_info="rpm-ostree not found"
    fi
    
    # Output
    if [[ "${JSON_MODE}" == true ]]; then
        echo '    "host_updates": {'
        echo '      "status": "'"$section_status"'",'
        echo '      "updates_available": "'"$updates_available"'",'
        echo '      "check_status": "'"$check_status"'",'
        echo '      "info": "'"$update_info"'"'
        echo '    },'
    else
        echo "============================================================"
        echo "HOST SYSTEM UPDATES"
        echo "============================================================"
        echo "Updates Available: ${updates_available}"
        echo "Info: ${update_info}"
        if [[ "$updates_available" == "yes" ]]; then
            warn "Host system has pending updates"
            echo "  Run: ujust update"
        fi
        echo "Status: $(case $section_status in HEALTHY) status_healthy ;; DEGRADED) status_warning ;; CRITICAL) status_critical ;; esac)"
        echo ""
    fi
}

# T019 [US1]: Guest Container Update Check
collect_guest_updates() {
    local section_status="HEALTHY"
    local container_name
    local updates_count="unknown"
    local security_count=0
    local check_status="unknown"
    
    container_name=$(get_config_value "CONTAINER_NAME" "foundryvtt")
    
    # Check if container is running
    if timeout $TIMEOUT_SHORT podman inspect "${container_name}" --format '{{.State.Status}}' 2>/dev/null | grep -q "running"; then
        # Try to check for updates
        if timeout $TIMEOUT_MEDIUM distrobox enter "${container_name}" -- sh -c "apt update -qq" &>/dev/null; then
            updates_count=$(timeout $TIMEOUT_MEDIUM distrobox enter "${container_name}" -- sh -c "apt list --upgradable 2>/dev/null | grep -c upgradable" 2>/dev/null || echo "0")
            security_count=$(timeout $TIMEOUT_MEDIUM distrobox enter "${container_name}" -- sh -c "apt list --upgradable 2>/dev/null | grep -i security | wc -l" 2>/dev/null || echo "0")
            check_status="checked"
            
            if [[ "$updates_count" -gt 0 ]]; then
                section_status="DEGRADED"
                set_overall_status "DEGRADED"
            fi
        else
            check_status="failed"
            updates_count="unknown"
        fi
    else
        check_status="container_not_running"
        updates_count="N/A"
    fi
    
    # Output
    if [[ "${JSON_MODE}" == true ]]; then
        echo '    "guest_updates": {'
        echo '      "status": "'"$section_status"'",'
        echo '      "updates_count": "'"$updates_count"'",'
        echo '      "security_count": "'"$security_count"'",'
        echo '      "check_status": "'"$check_status"'"'
        echo '    },'
    else
        echo "============================================================"
        echo "GUEST CONTAINER UPDATES"
        echo "============================================================"
        echo "Container: ${container_name}"
        echo "Upgradable Packages: ${updates_count}"
        if [[ "$security_count" -gt 0 ]]; then
            warn "Security Updates: ${security_count}"
        fi
        if [[ "$updates_count" != "unknown" ]] && [[ "$updates_count" != "N/A" ]] && [[ "$updates_count" -gt 0 ]]; then
            warn "Container has pending updates"
            echo "  Run: distrobox enter ${container_name} -- sudo apt upgrade"
        fi
        echo "Status: $(case $section_status in HEALTHY) status_healthy ;; DEGRADED) status_warning ;; CRITICAL) status_critical ;; esac)"
        echo ""
    fi
}

# T017 [US1]: Recent Log Collection
collect_recent_logs() {
    local section_status="HEALTHY"
    local container_name
    local log_entries=""
    local error_count=0
    
    container_name=$(get_config_value "CONTAINER_NAME" "foundryvtt")
    
    # Try to get logs from systemd journal
    if command -v journalctl &>/dev/null; then
        log_entries=$(timeout $TIMEOUT_SHORT journalctl --user -u "${container_name}.service" -n 10 --no-pager 2>/dev/null | tail -n 10 || echo "")
        
        # Count errors and warnings
        if [[ -n "$log_entries" ]]; then
            error_count=$(echo "$log_entries" | grep -cE "(ERROR|FATAL|Exception)" || echo 0)
            
            if [[ "$error_count" -gt 5 ]]; then
                section_status="CRITICAL"
                set_overall_status "CRITICAL"
            elif [[ "$error_count" -gt 0 ]]; then
                section_status="DEGRADED"
                set_overall_status "DEGRADED"
            fi
        fi
    fi
    
    # Output
    if [[ "${JSON_MODE}" == true ]]; then
        echo '    "logs": {'
        echo '      "status": "'"$section_status"'",'
        echo '      "error_count": "'"$error_count"'",'
        echo '      "recent_entries": ['
        if [[ -n "$log_entries" ]]; then
            local first=true
            while IFS= read -r line; do
                [[ "$first" == true ]] || echo ","
                first=false
                # Escape the line for JSON
                local escaped_line=$(echo "$line" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g')
                echo -n '        "'"$escaped_line"'"'
            done <<< "$log_entries"
            echo ""
        fi
        echo '      ]'
        echo '    },'
    else
        echo "============================================================"
        echo "RECENT LOGS"
        echo "============================================================"
        if [[ -n "$log_entries" ]]; then
            echo "$log_entries"
        else
            echo "No recent log entries available"
        fi
        if [[ "$error_count" -gt 0 ]]; then
            echo ""
            warn "Found ${error_count} errors in recent logs"
        fi
        echo "Status: $(case $section_status in HEALTHY) status_healthy ;; DEGRADED) status_warning ;; CRITICAL) status_critical ;; esac)"
        echo ""
    fi
}

# T020 [US1]: FoundryVTT Data Directory Analysis
collect_foundry_data() {
    local section_status="HEALTHY"
    local data_path
    local total_size="unknown"
    local worlds_count=0
    local modules_count=0
    local systems_count=0
    local assets_size="unknown"
    local permission_error=false
    
    data_path=$(get_config_value "DATA_PATH" "${HOME}/FoundryVTT-Data")
    
    # T030: Handle permission denied edge case
    if [[ ! -r "$data_path" ]]; then
        permission_error=true
        section_status="DEGRADED"
        set_overall_status "DEGRADED"
    else
        # T031: Handle large directories with timeout
        total_size=$(timeout $TIMEOUT_SHORT du -sh "$data_path" 2>/dev/null | cut -f1 || echo "timeout")
        
        if [[ "$total_size" == "timeout" ]]; then
            # For very large directories, just get approximate size
            total_size=$(df -h "$data_path" 2>/dev/null | tail -1 | awk '{print $3}' || echo "unknown")
            total_size="~${total_size} (estimated)"
        fi
        
        # Count worlds, modules, systems (fast operations)
        if [[ -d "$data_path/Data/worlds" ]]; then
            worlds_count=$(ls -1 "$data_path/Data/worlds" 2>/dev/null | wc -l)
        fi
        
        if [[ -d "$data_path/Data/modules" ]]; then
            modules_count=$(ls -1 "$data_path/Data/modules" 2>/dev/null | wc -l)
        fi
        
        if [[ -d "$data_path/Data/systems" ]]; then
            systems_count=$(ls -1 "$data_path/Data/systems" 2>/dev/null | wc -l)
        fi
        
        # Get assets size
        if [[ -d "$data_path/Data/assets" ]]; then
            assets_size=$(timeout $TIMEOUT_SHORT du -sh "$data_path/Data/assets" 2>/dev/null | cut -f1 || echo "timeout")
        fi
    fi
    
    # Output
    if [[ "${JSON_MODE}" == true ]]; then
        echo '    "foundry_data": {'
        echo '      "status": "'"$section_status"'",'
        echo '      "data_path": "'"$data_path"'",'
        echo '      "total_size": "'"$total_size"'",'
        echo '      "worlds_count": "'"$worlds_count"'",'
        echo '      "modules_count": "'"$modules_count"'",'
        echo '      "systems_count": "'"$systems_count"'",'
        echo '      "assets_size": "'"$assets_size"'",'
        echo '      "permission_error": "'"$permission_error"'"'
        echo '    },'
    else
        echo "============================================================"
        echo "FOUNDRYVTT DATA"
        echo "============================================================"
        echo "Data Path: ${data_path}"
        if [[ "$permission_error" == true ]]; then
            warn "Permission denied accessing data directory"
            echo "  Check permissions: ls -la ${data_path}"
        else
            echo "Total Size: ${total_size}"
            echo "Worlds: ${worlds_count}"
            echo "Modules: ${modules_count}"
            echo "Systems: ${systems_count}"
            if [[ "$assets_size" != "unknown" ]]; then
                echo "Assets: ${assets_size}"
            fi
        fi
        echo "Status: $(case $section_status in HEALTHY) status_healthy ;; DEGRADED) status_warning ;; CRITICAL) status_critical ;; esac)"
        echo ""
    fi
}

# T021 [US1]: FoundryVTT Configuration Parser
collect_foundry_config() {
    local section_status="HEALTHY"
    local data_path
    local config_port=""
    local config_upnp=""
    local config_hostname=""
    local config_compress=""
    local config_found=false
    
    data_path=$(get_config_value "DATA_PATH" "${HOME}/FoundryVTT-Data")
    local config_file="${data_path}/Config/options.json"
    
    # Try to parse config file
    if [[ -f "$config_file" ]] && [[ -r "$config_file" ]]; then
        config_found=true
        
        # Use grep/sed for simple parsing (more portable than jq)
        config_port=$(grep -o '"port":[[:space:]]*[0-9]*' "$config_file" 2>/dev/null | grep -o '[0-9]*' || echo "30000")
        config_upnp=$(grep -o '"upnp":[[:space:]]*true\|"upnp":[[:space:]]*false' "$config_file" 2>/dev/null | grep -o 'true\|false' || echo "false")
        config_hostname=$(grep -o '"hostname":[[:space:]]*"[^"]*"' "$config_file" 2>/dev/null | sed 's/.*"hostname":[[:space:]]*"\([^"]*\)".*/\1/' || echo "")
        config_compress=$(grep -o '"compressSocket":[[:space:]]*true\|"compressSocket":[[:space:]]*false' "$config_file" 2>/dev/null | grep -o 'true\|false' || echo "true")
    else
        section_status="DEGRADED"
        set_overall_status "DEGRADED"
    fi
    
    # Output
    if [[ "${JSON_MODE}" == true ]]; then
        echo '    "foundry_config": {'
        echo '      "status": "'"$section_status"'",'
        echo '      "config_found": "'"$config_found"'",'
        echo '      "port": "'"${config_port:-30000}"'",'
        echo '      "upnp": "'"${config_upnp:-false}"'",'
        echo '      "hostname": "'"${config_hostname:-}"'",'
        echo '      "compress_socket": "'"${config_compress:-true}"'"'
        echo '    },'
    else
        echo "============================================================"
        echo "FOUNDRYVTT CONFIGURATION"
        echo "============================================================"
        if [[ "$config_found" == true ]]; then
            echo "Config File: ${config_file}"
            echo "Port: ${config_port:-30000}"
            echo "UPnP: ${config_upnp:-false}"
            if [[ -n "$config_hostname" ]]; then
                echo "Hostname: ${config_hostname}"
            fi
            echo "Socket Compression: ${config_compress:-true}"
        else
            warn "Configuration file not found"
            echo "  Expected: ${config_file}"
            echo "  Run the setup script to configure FoundryVTT"
        fi
        echo "Status: $(case $section_status in HEALTHY) status_healthy ;; DEGRADED) status_warning ;; CRITICAL) status_critical ;; esac)"
        echo ""
    fi
}

# T022 [US1]: FoundryVTT Version Check
check_foundry_version() {
    local section_status="HEALTHY"
    local installed_version=""
    local latest_version="unknown"
    local version_status="unknown"
    local check_performed=false
    
    # Get installed version from config
    installed_version=$(get_config_value "FOUNDRY_VERSION" "unknown")
    
    # T032: Handle offline system - check if we can reach foundryvtt.com
    if command -v curl &>/dev/null; then
        # Try to get latest version with timeout
        latest_version=$(timeout $TIMEOUT_SHORT curl -s "https://foundryvtt.com/releases/stable" 2>/dev/null | grep -oP 'Version \K[0-9.]+' | head -1 || echo "")
        
        if [[ -n "$latest_version" ]]; then
            check_performed=true
            
            if [[ "$installed_version" == "$latest_version" ]]; then
                version_status="current"
            else
                version_status="outdated"
                section_status="DEGRADED"
                set_overall_status "DEGRADED"
            fi
        else
            version_status="offline"
            latest_version="unknown (cannot reach foundryvtt.com)"
        fi
    else
        version_status="no_curl"
        latest_version="unknown (curl not available)"
    fi
    
    # Output
    if [[ "${JSON_MODE}" == true ]]; then
        echo '    "version_check": {'
        echo '      "status": "'"$section_status"'",'
        echo '      "installed_version": "'"$installed_version"'",'
        echo '      "latest_version": "'"$latest_version"'",'
        echo '      "version_status": "'"$version_status"'",'
        echo '      "check_performed": "'"$check_performed"'"'
        echo '    },'
    else
        echo "============================================================"
        echo "VERSION CHECK"
        echo "============================================================"
        echo "Installed: ${installed_version}"
        if [[ "$version_status" == "current" ]]; then
            success "Up to date (latest: ${latest_version})"
        elif [[ "$version_status" == "outdated" ]]; then
            warn "Update available: ${latest_version}"
            echo "  Visit: https://foundryvtt.com to download"
        else
            info "Latest version: ${latest_version}"
        fi
        echo "Status: $(case $section_status in HEALTHY) status_healthy ;; DEGRADED) status_warning ;; CRITICAL) status_critical ;; esac)"
        echo ""
    fi
}

# T023 [US1]: Largest Files Identification
collect_largest_files() {
    local section_status="HEALTHY"
    local data_path
    local largest_files=""
    local file_count=0
    
    data_path=$(get_config_value "DATA_PATH" "${HOME}/FoundryVTT-Data")
    
    # Only proceed if directory is readable
    if [[ -r "$data_path" ]]; then
        # Find largest files with timeout (T031)
        largest_files=$(timeout $TIMEOUT_SHORT find "$data_path" -type f -exec ls -lh {} + 2>/dev/null | sort -k5 -hr | head -5 || echo "")
        
        if [[ -n "$largest_files" ]]; then
            file_count=$(echo "$largest_files" | wc -l)
        fi
    fi
    
    # Output
    if [[ "${JSON_MODE}" == true ]]; then
        echo '    "largest_files": {'
        echo '      "status": "'"$section_status"'",'
        echo '      "file_count": "'"$file_count"'",'
        echo '      "files": ['
        if [[ -n "$largest_files" ]]; then
            local first=true
            while IFS= read -r line; do
                [[ "$first" == true ]] || echo ","
                first=false
                # Parse ls output: permissions links owner group size date name
                local size=$(echo "$line" | awk '{print $5}')
                local name=$(echo "$line" | awk '{print $9}')
                # Escape for JSON
                name=$(echo "$name" | sed 's/\\/\\\\/g; s/"/\\"/g')
                echo -n '        {"size": "'"$size"'", "path": "'"$name"'"}'
            done <<< "$largest_files"
            echo ""
        fi
        echo '      ]'
        echo '    },'
    else
        echo "============================================================"
        echo "LARGEST FILES"
        echo "============================================================"
        if [[ -n "$largest_files" ]]; then
            echo "Top 5 largest files in data directory:"
            echo "$largest_files" | while IFS= read -r line; do
                local size=$(echo "$line" | awk '{print $5}')
                local name=$(echo "$line" | awk '{print $9}')
                echo "  ${size} - ${name}"
            done
        else
            echo "Could not determine largest files"
            echo "  (directory may be too large or inaccessible)"
        fi
        echo "Status: $(case $section_status in HEALTHY) status_healthy ;; DEGRADED) status_warning ;; CRITICAL) status_critical ;; esac)"
        echo ""
    fi
}

# Main function with diagnostic collection
main() {
    # Parse arguments
    parse_arguments "$@"
    
    # Auto-detect format if not explicitly set
    auto_detect_format
    
    # Require Bazzite
    require_bazzite
    
    # Acquire lock for concurrent runs
    acquire_lock
    
    # Start report
    start_report
    
    if [[ "${QUICK_MODE}" == true ]]; then
        # Quick mode - just check basic status
        collect_instance_status
        collect_container_status
    else
        # Full report - all sections
        collect_host_system
        collect_host_updates
        collect_container_status
        collect_guest_updates
        collect_instance_status
        collect_network_status
        collect_recent_logs
        collect_foundry_data
        collect_foundry_config
        check_foundry_version
        collect_largest_files
    fi
    
    # End report
    end_report
    
    # Return appropriate exit code
    exit "$(get_exit_code)"
}

# Run main function
main "$@"
