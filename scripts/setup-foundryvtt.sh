#!/usr/bin/env bash
#
# setup-foundryvtt.sh - FoundryVTT Setup Script for Bazzite
#
# This script sets up FoundryVTT in an isolated Distrobox container on Bazzite.
# It guides users through downloading FoundryVTT, configuring storage, and
# optionally enabling auto-start on boot.
#
# Requirements:
#   - Bazzite Linux (Steam Deck or desktop variant)
#   - Internet connection for initial setup
#   - Valid FoundryVTT license (for generating Timed URL)
#
# Usage:
#   ./setup-foundryvtt.sh
#
# For more information, see the quickstart guide in the repository.
#
# Project: FoundryVTT-Bazzite
# License: MIT
# Repository: https://github.com/YOUR_USERNAME/FoundryVTT-Bazzite
#

# Script version
readonly SCRIPT_VERSION="1.0.0"

# Default configuration values
readonly DEFAULT_CONTAINER_NAME="foundryvtt"
readonly DEFAULT_DATA_PATH="${HOME}/FoundryVTT"
readonly DEFAULT_INSTALL_PATH="${HOME}/foundryvtt"
readonly DEFAULT_PORT="30000"
readonly CONFIG_DIR="${HOME}/.config/foundryvtt-bazzite"
readonly CONFIG_FILE="${CONFIG_DIR}/config"

# Container settings
readonly CONTAINER_IMAGE="ubuntu:24.04"

# Action tracking for summary report
declare -a ACTIONS_TAKEN=()
declare -a ACTIONS_SKIPPED=()
SETUP_MODE=""  # "fresh", "reconfigure", or "reinstall"

# =============================================================================
# Phase 2: Foundational Functions
# =============================================================================

# T006: Strict mode and error handling
set -euo pipefail

# Error trap handler - provides context when script fails
trap 'error "Script failed at line $LINENO. Command: $BASH_COMMAND"' ERR

# T051: Interrupt handler (Ctrl+C) with cleanup guidance
cleanup_on_interrupt() {
    echo ""
    warn "Setup interrupted!"
    echo ""
    echo "The setup was interrupted before completion."
    echo ""
    echo "To clean up and start fresh:"
    echo "  1. Remove partial container: distrobox rm -f ${DEFAULT_CONTAINER_NAME}"
    echo "  2. Remove config file: rm -f ${CONFIG_FILE}"
    echo "  3. Run this script again"
    echo ""
    echo "Your data directory (if created) has been preserved."
    exit 130
}
trap cleanup_on_interrupt INT TERM

# T007: Colored output helpers
# Colors for terminal output (disabled if not a terminal)
if [[ -t 1 ]]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[0;33m'
    readonly BLUE='\033[0;34m'
    readonly NC='\033[0m' # No Color
else
    readonly RED=''
    readonly GREEN=''
    readonly YELLOW=''
    readonly BLUE=''
    readonly NC=''
fi

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

# Track actions for summary report
track_action() {
    ACTIONS_TAKEN+=("$1")
}

track_skipped() {
    ACTIONS_SKIPPED+=("$1")
}

# T008: Bazzite detection function per research.md
is_bazzite() {
    # Primary check: ID field in os-release
    if grep -q "^ID=bazzite" /etc/os-release 2>/dev/null; then
        return 0
    fi
    # Fallback: check /usr/lib/os-release (canonical location)
    if grep -q "^ID=bazzite" /usr/lib/os-release 2>/dev/null; then
        return 0
    fi
    return 1
}

# Check if a path is safe on an immutable system like Bazzite
# Safe paths: user's home directory, /var (persistent), mounted drives
is_safe_immutable_path() {
    local path="$1"
    
    # Paths under user's home directory are always safe
    if [[ "${path}" == "${HOME}"* ]]; then
        return 0
    fi
    
    # /var is persistent on immutable systems
    if [[ "${path}" == /var/* ]]; then
        return 0
    fi
    
    # /run/media is where removable drives are mounted
    if [[ "${path}" == /run/media/* ]]; then
        return 0
    fi
    
    # /mnt is a common mount point
    if [[ "${path}" == /mnt/* ]]; then
        return 0
    fi
    
    # Path is potentially unsafe (e.g., /opt, /usr, etc.)
    return 1
}

# T009: Internet connectivity check
check_internet() {
    info "Checking internet connectivity..."
    if curl -s --connect-timeout 5 --max-time 10 https://foundryvtt.com > /dev/null 2>&1; then
        success "Internet connection verified"
        return 0
    fi
    error "No internet connection detected"
    error "Please connect to the internet and try again."
    return 1
}

# T010: Config file read/write functions
load_config() {
    if [[ -f "${CONFIG_FILE}" ]]; then
        # shellcheck source=/dev/null
        source "${CONFIG_FILE}"
        return 0
    fi
    return 1
}

save_config() {
    local foundry_version="${1:-}"
    local node_version="${2:-}"
    local data_path="${3:-${DEFAULT_DATA_PATH}}"
    local install_path="${4:-${DEFAULT_INSTALL_PATH}}"
    local container_name="${5:-${DEFAULT_CONTAINER_NAME}}"
    local port="${6:-${DEFAULT_PORT}}"
    local auto_start="${7:-false}"
    
    # Create config directory if needed
    mkdir -p "${CONFIG_DIR}"
    
    # Write config file (shell-sourceable format)
    cat > "${CONFIG_FILE}" << EOF
# FoundryVTT-Bazzite Setup Configuration
# Generated: $(date -Iseconds)

FOUNDRY_VERSION="${foundry_version}"
NODE_VERSION="${node_version}"
DATA_PATH="${data_path}"
INSTALL_PATH="${install_path}"
CONTAINER_NAME="${container_name}"
PORT="${port}"
AUTO_START="${auto_start}"
SETUP_DATE="$(date -Iseconds)"
SETUP_VERSION="${SCRIPT_VERSION}"
EOF
    
    success "Configuration saved to ${CONFIG_FILE}"
    track_action "Saved configuration"
}

# T011: Idempotency check - detect existing setup
check_existing_setup() {
    if [[ -f "${CONFIG_FILE}" ]]; then
        info "Existing configuration found at ${CONFIG_FILE}"
        load_config
        return 0  # Setup exists
    fi
    return 1  # Fresh install
}

# T012: Container state detection functions
container_exists() {
    local name="${1:-${DEFAULT_CONTAINER_NAME}}"
    if distrobox list 2>/dev/null | grep -q "^${name} "; then
        return 0
    fi
    # Also check with different output format
    if distrobox list 2>/dev/null | grep -q "| ${name} |"; then
        return 0
    fi
    return 1
}

container_running() {
    local name="${1:-${DEFAULT_CONTAINER_NAME}}"
    if podman ps --filter "name=${name}" --format "{{.Names}}" 2>/dev/null | grep -q "^${name}$"; then
        return 0
    fi
    return 1
}

# =============================================================================
# Phase 3: User Story 1 - First-Time Setup (MVP)
# =============================================================================

# T014: Bazzite system check with friendly error message
check_bazzite() {
    info "Checking if running on Bazzite..."
    if ! is_bazzite; then
        error "This script requires Bazzite Linux."
        echo ""
        echo "Detected OS: $(grep ^ID= /etc/os-release 2>/dev/null | cut -d= -f2 || echo 'unknown')"
        echo ""
        echo "This tool is specifically designed for Bazzite Linux,"
        echo "an immutable Fedora-based distribution optimized for gaming."
        echo ""
        echo "Get Bazzite at: https://bazzite.gg"
        exit 1
    fi
    success "Bazzite detected"
}

# T015 & T016: Timed URL prompt with validation
# Regex pattern from data-model.md (slightly relaxed for flexibility)
readonly TIMED_URL_PATTERN='^https://r2\.foundryvtt\.com/releases/[0-9]+\.[0-9]+/FoundryVTT-[a-zA-Z]+-[0-9]+\.[0-9]+\.zip\?.*$'

prompt_timed_url() {
    echo ""
    echo "=========================================="
    echo "Step 1: FoundryVTT Download Link"
    echo "=========================================="
    echo ""
    echo "To download FoundryVTT, you need a Timed URL from your account:"
    echo ""
    echo "  1. Go to https://foundryvtt.com and log in"
    echo "  2. Navigate to your 'Purchased Licenses' page"
    echo "  3. Select 'Node.js' as the operating system"
    echo "  4. Click the 'Timed URL' button"
    echo "  5. Copy the link (it's valid for 5 minutes)"
    echo ""
    read -rp "Paste your Timed URL here: " TIMED_URL
    
    validate_timed_url "${TIMED_URL}"
}

validate_timed_url() {
    local url="$1"
    
    # Check if URL is empty
    if [[ -z "${url}" ]]; then
        error "No URL provided. Please paste a valid Timed URL."
        exit 1
    fi
    
    # Check URL pattern
    if [[ ! "${url}" =~ ${TIMED_URL_PATTERN} ]]; then
        error "Invalid URL format."
        echo ""
        echo "Expected format:"
        echo "  https://r2.foundryvtt.com/releases/XX.XXX/FoundryVTT-linux-XX.XXX.zip?verify=..."
        echo ""
        echo "Make sure you:"
        echo "  - Selected 'Node.js' as the operating system (NOT Linux)"
        echo "  - Copied the complete URL including the ?verify= part"
        echo ""
        exit 1
    fi
    
    success "URL format validated"
}

# T017: Extract FoundryVTT version from URL per research.md
parse_foundry_version() {
    local url="$1"
    # Extract version from URL: releases/{version}/FoundryVTT-...
    echo "${url}" | grep -oE 'releases/[0-9]+\.[0-9]+' | cut -d'/' -f2
}

# T018: Node.js version mapping per research.md
get_node_version() {
    local foundry_version="$1"
    local major="${foundry_version%%.*}"
    
    case "${major}" in
        14|13) echo "22" ;;  # V13+: Node 22.x recommended
        12)    echo "20" ;;  # V12: Node 20.x
        11|10) echo "18" ;;  # Older: Node 18.x
        *)     echo "22" ;;  # Future versions: default to latest LTS
    esac
}

# T019: Distrobox container creation
create_container() {
    local name="${1:-${DEFAULT_CONTAINER_NAME}}"
    
    info "Creating Distrobox container '${name}' with Ubuntu 22.04..."
    echo ""
    echo "    This may take a few minutes on first run while the"
    echo "    Ubuntu container image is downloaded..."
    echo ""
    
    if ! distrobox create --image "${CONTAINER_IMAGE}" --name "${name}" --yes 2>&1; then
        error "Failed to create Distrobox container"
        echo "Please check your Podman/Distrobox installation."
        exit 1
    fi
    
    success "Container '${name}' created successfully"
    track_action "Created Distrobox container '${name}'"
}

# T020: Node.js installation via NodeSource inside container
install_nodejs() {
    local container_name="${1:-${DEFAULT_CONTAINER_NAME}}"
    local node_major="$2"
    
    info "Installing Node.js ${node_major}.x in container..."
    echo ""
    echo "    This will install Node.js and required packages."
    echo "    Please wait..."
    echo ""
    
    # Run commands inside the container
    distrobox enter "${container_name}" -- bash -c "
        set -e
        echo 'Updating package lists...'
        sudo apt-get update -qq
        
        echo 'Installing prerequisites...'
        sudo apt-get install -y -qq curl ca-certificates gnupg
        
        echo 'Setting up NodeSource repository...'
        curl -fsSL https://deb.nodesource.com/setup_${node_major}.x | sudo -E bash -
        
        echo 'Installing Node.js...'
        sudo apt-get install -y -qq nodejs
        
        echo 'Installing unzip...'
        sudo apt-get install -y -qq unzip
        
        echo 'Verifying Node.js installation...'
        node --version
    "
    
    success "Node.js ${node_major}.x installed successfully"
    track_action "Installed Node.js ${node_major}.x"
}

# T021: FoundryVTT download and extraction
download_foundryvtt() {
    local url="$1"
    local install_path="${2:-${DEFAULT_INSTALL_PATH}}"
    local container_name="${3:-${DEFAULT_CONTAINER_NAME}}"
    
    info "Downloading FoundryVTT..."
    
    # Create install directory
    mkdir -p "${install_path}"
    
    local temp_zip="${install_path}/foundryvtt.zip"
    
    # Download using curl with progress
    if ! curl -L --progress-bar -o "${temp_zip}" "${url}"; then
        handle_download_error
    fi
    
    # Verify download succeeded (file should be > 100KB)
    local file_size
    file_size=$(stat -f%z "${temp_zip}" 2>/dev/null || stat -c%s "${temp_zip}" 2>/dev/null || echo "0")
    
    if [[ "${file_size}" -lt 100000 ]]; then
        handle_download_error
    fi
    
    info "Extracting FoundryVTT..."
    
    # Extract the zip file
    if ! unzip -q -o "${temp_zip}" -d "${install_path}"; then
        error "Failed to extract FoundryVTT"
        exit 1
    fi
    
    # Clean up zip file
    rm -f "${temp_zip}"
    
    success "FoundryVTT installed to ${install_path}"
    track_action "Downloaded and extracted FoundryVTT"
}

# T25: Handle expired Timed URL error
handle_download_error() {
    error "Download failed!"
    echo ""
    echo "This usually means your Timed URL has expired."
    echo "Timed URLs are only valid for 5 minutes."
    echo ""
    echo "Please:"
    echo "  1. Go back to https://foundryvtt.com"
    echo "  2. Generate a fresh Timed URL"
    echo "  3. Run this script again"
    echo ""
    exit 1
}

# T022: Default data directory creation
create_data_directory() {
    local data_path="${1:-${DEFAULT_DATA_PATH}}"
    
    info "Creating data directory at ${data_path}..."
    
    if [[ -d "${data_path}" ]]; then
        warn "Data directory already exists at ${data_path}"
        track_skipped "Data directory (already exists)"
    else
        mkdir -p "${data_path}"
        success "Data directory created at ${data_path}"
        track_action "Created data directory"
    fi
}

# T026: Handle existing container scenario
handle_existing_container() {
    local name="${1:-${DEFAULT_CONTAINER_NAME}}"
    
    if container_exists "${name}"; then
        warn "Container '${name}' already exists."
        echo ""
        echo "Options:"
        echo "  1) Reconfigure - Remove existing container and start fresh"
        echo "  2) Abort - Exit without making changes"
        echo ""
        read -rp "Choose an option (1 or 2): " choice
        
        case "${choice}" in
            1)
                info "Removing existing container..."
                distrobox rm --force "${name}" 2>/dev/null || true
                success "Container removed"
                ;;
            2|*)
                info "Aborting setup."
                exit 0
                ;;
        esac
    fi
}

# =============================================================================
# Phase 4: User Story 2 - Choose Data Storage Location
# =============================================================================

# T028: Data location prompt with default option
prompt_data_location() {
    echo ""
    echo "=========================================="
    echo "Step 2: Data Storage Location"
    echo "=========================================="
    echo ""
    echo "Where should FoundryVTT store your data?"
    echo "(worlds, modules, assets, configuration)"
    echo ""
    echo "  Default: ${DEFAULT_DATA_PATH}"
    echo ""
    echo "IMPORTANT: Bazzite is an immutable system. Your data must be stored in"
    echo "a location that persists across system updates:"
    echo ""
    echo "  SAFE locations:"
    echo "    - Your home directory: ~/  (e.g., ~/FoundryVTT)"
    echo "    - Secondary drives mounted under /var/mnt/ or ~/mnt/"
    echo ""
    echo "  UNSAFE locations (data will be LOST on updates):"
    echo "    - /opt, /usr, or other system directories"
    echo ""
    read -rp "Press Enter for default, or type a custom path: " custom_path
    
    if [[ -z "${custom_path}" ]]; then
        DATA_PATH="${DEFAULT_DATA_PATH}"
        info "Using default location: ${DATA_PATH}"
    else
        # T029: Custom path input
        DATA_PATH="${custom_path}"
        info "Using custom location: ${DATA_PATH}"
        
        # Expand ~ to full path
        DATA_PATH="${DATA_PATH/#\~/$HOME}"
        
        # T030: Validate the path
        validate_data_path "${DATA_PATH}"
    fi
}

# T030: Path validation per data-model.md
validate_data_path() {
    local path="$1"
    
    # Check for spaces (Distrobox limitation)
    if [[ "${path}" =~ \  ]]; then
        error "Path cannot contain spaces."
        echo "Please choose a path without spaces."
        exit 1
    fi
    
    # Check if path is absolute
    if [[ "${path}" != /* ]]; then
        error "Path must be absolute (start with /)"
        exit 1
    fi
    
    # Check if path is in a safe location for immutable systems
    # Safe: /home/*, /var/*, ~/*, paths under user's home
    if ! is_safe_immutable_path "${path}"; then
        echo ""
        warn "WARNING: This path may not persist across system updates!"
        echo ""
        echo "On Bazzite (an immutable system), only these locations are safe:"
        echo "  - Your home directory: ${HOME}/"
        echo "  - Secondary drives: /var/mnt/ or mounted drives"
        echo ""
        echo "Paths like /opt, /usr, etc. are READ-ONLY or reset on updates."
        echo ""
        read -rp "Are you sure you want to use this path? (y/n): " confirm_unsafe
        if [[ ! "${confirm_unsafe}" =~ ^[Yy] ]]; then
            error "Please choose a safe path."
            exit 1
        fi
        warn "Proceeding with potentially unsafe path at user's request."
    fi
    
    # T031: Check if path exists, offer to create
    if [[ ! -d "${path}" ]]; then
        warn "Directory does not exist: ${path}"
        read -rp "Create this directory? (y/n): " create_dir
        
        case "${create_dir}" in
            [Yy]*)
                if mkdir -p "${path}" 2>/dev/null; then
                    success "Directory created: ${path}"
                else
                    error "Failed to create directory. Check permissions."
                    exit 1
                fi
                ;;
            *)
                error "Cannot proceed without a valid data directory."
                exit 1
                ;;
        esac
    fi
    
    # T032: Permission check
    if [[ ! -w "${path}" ]]; then
        error "You don't have write permission to: ${path}"
        echo ""
        echo "Options:"
        echo "  - Choose a different path"
        echo "  - Fix permissions: chmod u+w ${path}"
        echo "  - Use a path in your home directory"
        echo ""
        exit 1
    fi
    
    success "Data path validated: ${path}"
    return 0
}

# =============================================================================
# Data Migration Functions (for reconfigure)
# =============================================================================

# Check if a directory has any content
directory_has_data() {
    local path="$1"
    [[ -d "${path}" ]] && [[ -n "$(ls -A "${path}" 2>/dev/null)" ]]
}

# Handle data migration when changing data path
handle_data_migration() {
    local old_path="$1"
    local new_path="$2"
    
    # Check if old path has data
    if ! directory_has_data "${old_path}"; then
        info "No existing data to migrate."
        mkdir -p "${new_path}"
        return 0
    fi
    
    # Check if new path already has files
    if directory_has_data "${new_path}"; then
        error "Directory already contains files: ${new_path}"
        echo "Please choose a different path or remove existing files first."
        return 1
    fi
    
    # Show migration menu
    echo ""
    echo "=========================================="
    echo "Data Migration Options"
    echo "=========================================="
    echo ""
    echo "Your existing data is at: ${old_path}"
    echo ""
    echo "What would you like to do with your existing data?"
    echo ""
    echo "  1) Move data to new location (original will be removed)"
    echo "  2) Copy data to new location (keep original as backup)"
    echo "  3) Start fresh (new location will be empty)"
    echo ""
    read -rp "Choose an option (1-3): " migration_choice
    
    case "${migration_choice}" in
        1) migrate_move "${old_path}" "${new_path}" ;;
        2) migrate_copy "${old_path}" "${new_path}" ;;
        3) migrate_fresh "${old_path}" "${new_path}" ;;
        *) 
            error "Invalid choice"
            return 1
            ;;
    esac
}

# Option 1: Move data to new location
migrate_move() {
    local old_path="$1"
    local new_path="$2"
    
    echo ""
    warn "This will MOVE all data to the new location."
    echo "The contents of ${old_path} will be DELETED after transfer."
    echo ""
    read -rp "Are you sure? (y/n): " confirm
    
    if [[ ! "${confirm}" =~ ^[Yy] ]]; then
        info "Move cancelled."
        return 1
    fi
    
    # Create destination directory
    mkdir -p "${new_path}"
    
    echo ""
    info "Moving data from ${old_path} to ${new_path}..."
    echo ""
    
    # Use rsync with progress, then remove source files
    if rsync -ah --info=progress2 --remove-source-files "${old_path}/" "${new_path}/"; then
        # Remove empty directories left behind (rsync --remove-source-files only removes files)
        find "${old_path}" -type d -empty -delete 2>/dev/null || true
        echo ""
        success "Data moved successfully!"
        info "Original directory emptied: ${old_path}"
        track_action "Moved data to new location"
        return 0
    else
        echo ""
        error "Move failed! Your original data is still at: ${old_path}"
        return 1
    fi
}

# Option 2: Copy data to new location
migrate_copy() {
    local old_path="$1"
    local new_path="$2"
    
    # Create destination directory
    mkdir -p "${new_path}"
    
    echo ""
    info "Copying data from ${old_path} to ${new_path}..."
    echo "This may take a while depending on the amount of data."
    echo ""
    
    if rsync -ah --info=progress2 "${old_path}/" "${new_path}/"; then
        echo ""
        success "Data copied successfully!"
        info "Original data preserved at: ${old_path}"
        track_action "Copied data to new location"
        return 0
    else
        echo ""
        error "Copy failed!"
        return 1
    fi
}

# Option 3: Start fresh (empty directory)
migrate_fresh() {
    local old_path="$1"
    local new_path="$2"
    
    echo ""
    warn "Your existing data will NOT be available in the new location."
    echo "Your worlds, modules, and settings will need to be manually moved from:"
    echo "  ${old_path}"
    echo ""
    read -rp "Continue with empty directory? (y/n): " confirm
    
    if [[ ! "${confirm}" =~ ^[Yy] ]]; then
        info "Cancelled."
        return 1
    fi
    
    mkdir -p "${new_path}"
    success "New empty data directory created at: ${new_path}"
    info "Your old data remains at: ${old_path}"
    track_action "Created fresh data directory"
    return 0
}

# =============================================================================
# Phase 5: User Story 3 - Configure Auto-Start on Boot
# =============================================================================

# T036: Auto-start prompt
prompt_auto_start() {
    echo ""
    echo "=========================================="
    echo "Step 3: Auto-Start Configuration"
    echo "=========================================="
    echo ""
    echo "Would you like FoundryVTT to start automatically"
    echo "when you turn on your computer?"
    echo ""
    echo "  - Yes: Great for dedicated game servers"
    echo "  - No: Start manually when you want to play (saves resources)"
    echo ""
    read -rp "Enable auto-start? (y/n): " auto_start_choice
    
    case "${auto_start_choice}" in
        [Yy]*)
            AUTO_START="true"
            info "Auto-start will be enabled"
            configure_auto_start
            ;;
        *)
            # T043: Skip service creation when user declines
            AUTO_START="false"
            info "Auto-start disabled. You can start FoundryVTT manually."
            track_skipped "Auto-start (user declined)"
            ;;
    esac
}

# T037, T039: Generate and install systemd service file
configure_auto_start() {
    local service_dir="${HOME}/.config/systemd/user"
    local service_file="${service_dir}/foundryvtt.service"
    
    info "Configuring auto-start service..."
    
    # Create systemd user directory if needed
    mkdir -p "${service_dir}"
    
    # T037: Generate service file from template with variable substitution
    cat > "${service_file}" << EOF
# FoundryVTT Systemd User Service
# Generated by setup-foundryvtt.sh v${SCRIPT_VERSION}
# Generated: $(date -Iseconds)

[Unit]
Description=FoundryVTT Server in Distrobox
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/distrobox enter ${DEFAULT_CONTAINER_NAME} -- node ${DEFAULT_INSTALL_PATH}/main.js --dataPath=${DATA_PATH} --port=${DEFAULT_PORT}
Restart=on-failure
RestartSec=10
TimeoutStartSec=300

[Install]
WantedBy=default.target
EOF
    
    success "Service file created at ${service_file}"
    
    # T040: Reload systemd
    info "Reloading systemd..."
    if systemctl --user daemon-reload; then
        success "Systemd reloaded"
    else
        warn "Failed to reload systemd. You may need to run: systemctl --user daemon-reload"
    fi
    
    # T041: Enable the service
    info "Enabling FoundryVTT service..."
    if systemctl --user enable foundryvtt.service 2>/dev/null; then
        success "Service enabled"
    else
        warn "Failed to enable service. You may need to run: systemctl --user enable foundryvtt.service"
    fi
    
    # T042: Enable user lingering for boot-time startup
    info "Enabling user lingering for boot-time startup..."
    if loginctl enable-linger "${USER}" 2>/dev/null; then
        success "User lingering enabled"
    else
        warn "Failed to enable lingering. You may need to run: loginctl enable-linger ${USER}"
    fi
    
    success "Auto-start configured successfully!"
    track_action "Configured auto-start service"
}

# Comprehensive summary report
show_summary_report() {
    local install_path="${1:-${DEFAULT_INSTALL_PATH}}"
    local data_path="${2:-${DEFAULT_DATA_PATH}}"
    local container_name="${3:-${DEFAULT_CONTAINER_NAME}}"
    local port="${4:-${DEFAULT_PORT}}"
    local auto_start="${5:-false}"
    
    # Box width: 66 characters inside the borders (total 68 with │ on each side)
    local box_width=66
    
    echo ""
    echo "┌──────────────────────────────────────────────────────────────────┐"
    echo "│                        SETUP COMPLETE                            │"
    echo "└──────────────────────────────────────────────────────────────────┘"
    echo ""
    
    # Setup mode header
    case "${SETUP_MODE}" in
        fresh)
            success "Fresh installation completed successfully!"
            ;;
        reconfigure)
            success "Configuration updated successfully!"
            ;;
        reinstall)
            success "Reinstallation completed successfully!"
            ;;
        *)
            success "Setup completed successfully!"
            ;;
    esac
    
    echo ""
    echo "┌──────────────────────────────────────────────────────────────────┐"
    echo "│  ACTIONS PERFORMED                                               │"
    echo "├──────────────────────────────────────────────────────────────────┤"
    
    if [[ ${#ACTIONS_TAKEN[@]} -gt 0 ]]; then
        for action in "${ACTIONS_TAKEN[@]}"; do
            # Truncate action if too long (max 60 chars to leave room for checkmark)
            local display_action="${action:0:60}"
            printf "│  %b✓%b %-60s │\n" "${GREEN}" "${NC}" "${display_action}"
        done
    else
        echo "│  No actions were taken                                           │"
    fi
    
    if [[ ${#ACTIONS_SKIPPED[@]} -gt 0 ]]; then
        echo "├──────────────────────────────────────────────────────────────────┤"
        echo "│  UNCHANGED                                                       │"
        echo "├──────────────────────────────────────────────────────────────────┤"
        for action in "${ACTIONS_SKIPPED[@]}"; do
            local display_action="${action:0:60}"
            printf "│  %b○%b %-60s │\n" "${BLUE}" "${NC}" "${display_action}"
        done
    fi
    
    echo "└──────────────────────────────────────────────────────────────────┘"
    echo ""
    
    echo "┌──────────────────────────────────────────────────────────────────┐"
    echo "│  CURRENT CONFIGURATION                                           │"
    echo "├──────────────────────────────────────────────────────────────────┤"
    printf "│  %-18s %-44s │\n" "FoundryVTT:" "${FOUNDRY_VERSION:-unknown}"
    printf "│  %-18s %-44s │\n" "Node.js:" "${NODE_VERSION:-unknown}.x"
    printf "│  %-18s %-44s │\n" "Container:" "${container_name}"
    printf "│  %-18s %-44s │\n" "Install Path:" "${install_path}"
    printf "│  %-18s %-44s │\n" "Data Path:" "${data_path}"
    printf "│  %-18s %-44s │\n" "Port:" "${port}"
    if [[ "${auto_start}" == "true" ]]; then
        printf "│  %-18s %b%-44s%b │\n" "Auto-Start:" "${GREEN}" "Enabled" "${NC}"
    else
        printf "│  %-18s %b%-44s%b │\n" "Auto-Start:" "${YELLOW}" "Disabled" "${NC}"
    fi
    echo "└──────────────────────────────────────────────────────────────────┘"
    echo ""
    
    echo "┌──────────────────────────────────────────────────────────────────┐"
    echo "│  ACCESS YOUR SERVER                                              │"
    echo "├──────────────────────────────────────────────────────────────────┤"
    printf "│  Open in browser: %-46s │\n" "http://localhost:${port}"
    echo "│                                                                  │"
    if [[ "${auto_start}" == "true" ]]; then
        echo "│  FoundryVTT will start automatically on boot.                    │"
    else
        echo "│  To start FoundryVTT manually, see command below.                │"
    fi
    echo "└──────────────────────────────────────────────────────────────────┘"
    
    if [[ "${auto_start}" != "true" ]]; then
        echo ""
        echo "Manual start command:"
        echo "  distrobox enter ${container_name} -- \\"
        echo "    node ${install_path}/main.js \\"
        echo "    --dataPath=${data_path} --port=${port}"
    fi
    echo ""
    
    if [[ "${auto_start}" == "true" ]]; then
        echo "┌──────────────────────────────────────────────────────────────────┐"
        echo "│  USEFUL COMMANDS                                                 │"
        echo "├──────────────────────────────────────────────────────────────────┤"
        echo "│  Check status:  systemctl --user status foundryvtt.service       │"
        echo "│  View logs:     journalctl --user -u foundryvtt.service -f       │"
        echo "│  Stop server:   systemctl --user stop foundryvtt.service         │"
        echo "│  Start server:  systemctl --user start foundryvtt.service        │"
        echo "│  Restart:       systemctl --user restart foundryvtt.service      │"
        echo "└──────────────────────────────────────────────────────────────────┘"
        echo ""
    fi
    
    echo "┌──────────────────────────────────────────────────────────────────┐"
    echo "│  NEXT STEPS                                                      │"
    echo "├──────────────────────────────────────────────────────────────────┤"
    printf "│  1. Open %-55s │\n" "http://localhost:${port}"
    echo "│  2. Enter your FoundryVTT license key                            │"
    echo "│  3. Create your first world and start gaming!                    │"
    echo "│                                                                  │"
    echo "│  Need help? See docs/troubleshooting.md                          │"
    echo "└──────────────────────────────────────────────────────────────────┘"
    echo ""
}

# =============================================================================
# Main Script Logic
# =============================================================================

# Handle existing installation - offer reconfigure options
handle_existing_installation() {
    echo ""
    echo "=========================================="
    echo "Existing Installation Detected"
    echo "=========================================="
    echo ""
    info "FoundryVTT is already installed."
    echo ""
    echo "Current configuration:"
    echo "  Version:    ${FOUNDRY_VERSION:-unknown}"
    echo "  Data path:  ${DATA_PATH:-unknown}"
    echo "  Auto-start: ${AUTO_START:-unknown}"
    echo ""
    echo "What would you like to do?"
    echo ""
    echo "  1) Reconfigure settings (data path, auto-start)"
    echo "  2) Reinstall completely (requires new Timed URL)"
    echo "  3) Exit without changes"
    echo ""
    read -rp "Choose an option (1-3): " choice
    
    case "${choice}" in
        1)
            reconfigure_existing
            ;;
        2)
            reinstall_fresh
            ;;
        3|*)
            info "Exiting without changes."
            exit 0
            ;;
    esac
}

# Reconfigure existing installation (no Timed URL needed)
reconfigure_existing() {
    SETUP_MODE="reconfigure"
    info "Reconfiguring existing installation..."
    
    # Stop service if running
    if systemctl --user is-active foundryvtt.service &>/dev/null; then
        info "Stopping FoundryVTT service..."
        systemctl --user stop foundryvtt.service
        track_action "Stopped FoundryVTT service"
    fi
    
    # Keep existing values as defaults
    local old_data_path="${DATA_PATH}"
    local old_auto_start="${AUTO_START}"
    
    # Prompt for new data location with migration handling
    while true; do
        echo ""
        echo "=========================================="
        echo "Reconfigure: Data Storage Location"
        echo "=========================================="
        echo ""
        echo "Current data path: ${old_data_path}"
        echo ""
        read -rp "Press Enter to keep current, or type a new path: " new_path
        
        # No change - keep current path
        if [[ -z "${new_path}" ]]; then
            DATA_PATH="${old_data_path}"
            info "Keeping current data path: ${DATA_PATH}"
            track_skipped "Data path (unchanged)"
            break
        fi
        
        # Expand ~ to full path
        new_path="${new_path/#\~/$HOME}"
        
        # Same path entered - no change needed
        if [[ "${new_path}" == "${old_data_path}" ]]; then
            info "Same path entered. No change needed."
            DATA_PATH="${old_data_path}"
            track_skipped "Data path (unchanged)"
            break
        fi
        
        # Validate the new path format (spaces, absolute path)
        # Note: We don't create the directory yet - migration will handle that
        if [[ "${new_path}" =~ \  ]]; then
            error "Path cannot contain spaces."
            echo "Please choose a path without spaces."
            continue
        fi
        
        if [[ "${new_path}" != /* ]]; then
            error "Path must be absolute (start with /)"
            continue
        fi
        
        # Handle data migration
        if handle_data_migration "${old_data_path}" "${new_path}"; then
            DATA_PATH="${new_path}"
            success "Data path changed to: ${DATA_PATH}"
            break
        fi
        
        # Migration failed or was cancelled - loop back to prompt
        warn "Let's try again..."
    done
    
    # Prompt for auto-start
    prompt_auto_start
    
    # Save updated configuration
    save_config "${FOUNDRY_VERSION}" "${NODE_VERSION}" "${DATA_PATH}" "${INSTALL_PATH:-${DEFAULT_INSTALL_PATH}}" "${CONTAINER_NAME:-${DEFAULT_CONTAINER_NAME}}" "${PORT:-${DEFAULT_PORT}}" "${AUTO_START}"
    
    # Restart service if it was enabled
    if [[ "${AUTO_START}" == "true" ]]; then
        info "Starting FoundryVTT service..."
        systemctl --user start foundryvtt.service
        track_action "Started FoundryVTT service"
    fi
    
    # Show completion
    show_summary_report "${INSTALL_PATH:-${DEFAULT_INSTALL_PATH}}" "${DATA_PATH}" "${CONTAINER_NAME:-${DEFAULT_CONTAINER_NAME}}" "${PORT:-${DEFAULT_PORT}}" "${AUTO_START}"
}

# Reinstall fresh (removes container, requires new Timed URL)
reinstall_fresh() {
    SETUP_MODE="reinstall"
    warn "This will remove the existing container and reinstall FoundryVTT."
    echo "Your data in ${DATA_PATH:-${DEFAULT_DATA_PATH}} will be preserved."
    echo ""
    read -rp "Are you sure? (y/n): " confirm
    
    if [[ ! "${confirm}" =~ ^[Yy] ]]; then
        info "Reinstall cancelled."
        exit 0
    fi
    
    # Stop service if running
    if systemctl --user is-active foundryvtt.service &>/dev/null; then
        info "Stopping FoundryVTT service..."
        systemctl --user stop foundryvtt.service
    fi
    
    # Remove existing container
    if container_exists "${DEFAULT_CONTAINER_NAME}"; then
        info "Removing existing container..."
        distrobox rm --force "${DEFAULT_CONTAINER_NAME}" 2>/dev/null || true
        success "Container removed"
        track_action "Removed existing container"
    fi
    
    # Remove config to start fresh
    rm -f "${CONFIG_FILE}"
    
    # Run fresh install
    fresh_install
}

# Fresh installation (first time or after reinstall)
fresh_install() {
    # Set mode if not already set (reinstall sets it before calling this)
    if [[ -z "${SETUP_MODE}" ]]; then
        SETUP_MODE="fresh"
    fi
    
    # T015/T016: Prompt for Timed URL
    prompt_timed_url
    
    # T017: Extract FoundryVTT version from URL
    FOUNDRY_VERSION=$(parse_foundry_version "${TIMED_URL}")
    if [[ -z "${FOUNDRY_VERSION}" ]]; then
        error "Could not determine FoundryVTT version from URL"
        exit 1
    fi
    info "Detected FoundryVTT version: ${FOUNDRY_VERSION}"
    
    # T018: Determine Node.js version
    NODE_VERSION=$(get_node_version "${FOUNDRY_VERSION}")
    info "Required Node.js version: ${NODE_VERSION}.x"
    
    # T019: Create the Distrobox container
    create_container "${DEFAULT_CONTAINER_NAME}"
    
    # T020: Install Node.js in the container
    install_nodejs "${DEFAULT_CONTAINER_NAME}" "${NODE_VERSION}"
    
    # T021: Download and extract FoundryVTT
    download_foundryvtt "${TIMED_URL}" "${DEFAULT_INSTALL_PATH}" "${DEFAULT_CONTAINER_NAME}"
    
    # T028-T032: Prompt for data location (Phase 4 - User Story 2)
    prompt_data_location
    
    # T022: Create data directory (now uses user-specified path)
    create_data_directory "${DATA_PATH}"
    
    # T036-T043: Prompt for auto-start (Phase 5 - User Story 3)
    prompt_auto_start
    
    # T023/T033/T044: Save configuration (includes DATA_PATH and AUTO_START)
    save_config "${FOUNDRY_VERSION}" "${NODE_VERSION}" "${DATA_PATH}" "${DEFAULT_INSTALL_PATH}" "${DEFAULT_CONTAINER_NAME}" "${DEFAULT_PORT}" "${AUTO_START}"
    
    # T024/T034/T045: Show completion message with auto-start info
    show_summary_report "${DEFAULT_INSTALL_PATH}" "${DATA_PATH}" "${DEFAULT_CONTAINER_NAME}" "${DEFAULT_PORT}" "${AUTO_START}"
}

main() {
    echo "FoundryVTT Setup for Bazzite v${SCRIPT_VERSION}"
    echo "=============================================="
    echo ""
    echo "This script will guide you through setting up FoundryVTT."
    echo ""
    
    # T014: Check if running on Bazzite
    check_bazzite
    
    # Check for existing setup first
    if check_existing_setup; then
        # Existing installation found - offer options
        handle_existing_installation
    else
        # Fresh install
        # T009: Check internet connectivity
        check_internet
        
        # T026: Check for orphaned container (config missing but container exists)
        handle_existing_container "${DEFAULT_CONTAINER_NAME}"
        
        fresh_install
    fi
}

# Run main function
main "$@"
