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
    exit ${exit_code}
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
        local detected_os=$(grep "^ID=" /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')
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
                    exit ${EXIT_ERROR}
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
# Main Entry Point
# =============================================================================

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
    
    # TODO: Implement diagnostic collection functions
    # These will be added in Phase 3 (User Story 1)
    
    if [[ "${QUICK_MODE}" == true ]]; then
        # Quick mode - just show summary
        if [[ "${JSON_MODE}" == false ]]; then
            echo "Quick health check mode - not yet implemented"
        fi
    else
        # Full report - show all sections
        if [[ "${JSON_MODE}" == false ]]; then
            echo "Full diagnostic report - not yet implemented"
        fi
    fi
    
    # End report
    end_report
    
    # Return appropriate exit code
    exit $(get_exit_code)
}

# Run main function
main "$@"
