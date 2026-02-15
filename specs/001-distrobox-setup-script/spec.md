# Feature Specification: FoundryVTT Distrobox Setup Script

**Feature Branch**: `001-distrobox-setup-script`  
**Created**: 2026-02-15  
**Status**: Draft  
**Input**: User description: "A user can download a script from this github repo. The script is for a Bazzite system. This will fire up a new instance of DistroBox and prepare it as the host for FoundryVTT. The script will help the user decide where the data will be stored. The script will help the user decide if they want FoundryVTT to run when the computer starts."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - First-Time Setup (Priority: P1)

A new Bazzite user wants to run FoundryVTT on their system. They download a single script from this GitHub repository and run it. The script guides them through creating a Distrobox container specifically configured for FoundryVTT. When prompted, the user goes to their FoundryVTT account, clicks "Timed URL" to generate a temporary download link, and pastes it into the script. The script downloads and installs FoundryVTT automatically. By the end, they have a working FoundryVTT installation ready to use—no manual file downloads or path management required.

**Why this priority**: This is the core value proposition—getting a complete, working FoundryVTT setup with minimal effort. Without this, nothing else matters.

**Independent Test**: Can be fully tested by running the script on a fresh Bazzite installation and verifying FoundryVTT launches successfully.

**Acceptance Scenarios**:

1. **Given** a Bazzite system with no existing FoundryVTT setup, **When** the user runs the setup script, **Then** a new Distrobox container is created with all FoundryVTT dependencies installed.

2. **Given** the script prompts for FoundryVTT download, **When** the user pastes a valid Timed URL from their account, **Then** the script downloads and installs FoundryVTT automatically.

3. **Given** the script is running, **When** the user is prompted for data storage location, **Then** they are presented with clear options and the selected location is configured correctly.

4. **Given** the setup completes successfully, **When** the user launches FoundryVTT, **Then** the application starts and is accessible via web browser.

---

### User Story 2 - Choose Data Storage Location (Priority: P2)

During setup, the user is asked where they want to store their FoundryVTT data (worlds, assets, modules, etc.). The script presents sensible default options and allows the user to specify a custom path. This ensures users can place data on their preferred drive (internal, external, or network storage).

**Why this priority**: Data location affects backups, available space, and portability. Users need control over this, but it's secondary to getting FoundryVTT running at all.

**Independent Test**: Can be tested by running setup, selecting different storage locations, and verifying data is written to the chosen path.

**Acceptance Scenarios**:

1. **Given** the script reaches the data location prompt, **When** the user selects the default location, **Then** data is stored in a standard location within their home directory.

2. **Given** the script reaches the data location prompt, **When** the user specifies a custom path, **Then** the script validates the path exists (or offers to create it) and configures FoundryVTT to use it.

3. **Given** the user selects an external drive path, **When** setup completes, **Then** FoundryVTT data is stored on the external drive and persists across container restarts.

---

### User Story 3 - Configure Auto-Start on Boot (Priority: P3)

The user is asked whether they want FoundryVTT to start automatically when they turn on their computer. If yes, the script configures the necessary systemd/Quadlet services. If no, the user can start FoundryVTT manually when needed.

**Why this priority**: Auto-start is a convenience feature. Users can always start FoundryVTT manually, so this enhances the experience but isn't essential for basic functionality.

**Independent Test**: Can be tested by enabling auto-start, rebooting the system, and verifying FoundryVTT is running without manual intervention.

**Acceptance Scenarios**:

1. **Given** the script reaches the auto-start prompt, **When** the user chooses to enable auto-start, **Then** a systemd service is configured to start FoundryVTT on system boot.

2. **Given** the script reaches the auto-start prompt, **When** the user declines auto-start, **Then** no startup service is created and FoundryVTT only runs when manually started.

3. **Given** auto-start is enabled and the system reboots, **When** the user logs in, **Then** FoundryVTT is already running and accessible.

---

### Edge Cases

- What happens when the user runs the script on a non-Bazzite system?
  - The script detects incompatible systems and exits with a clear message explaining requirements.

- What happens when a Distrobox container with the same name already exists?
  - The script detects the existing container and asks if the user wants to reconfigure it or abort.

- What happens when the specified data storage path doesn't exist?
  - The script offers to create the directory or prompts for a different path.

- What happens when the user lacks permissions for the chosen data path?
  - The script detects permission issues and provides guidance on how to resolve them.

- What happens when the script is interrupted mid-setup?
  - The script can be safely re-run; it detects partial setups and offers to continue or start fresh.

- What happens when the user's system has no internet connection?
  - The script detects this early and informs the user that internet is required for initial setup.

- What happens when the Timed URL has expired (older than 5 minutes)?
  - The script detects the download failure, explains that Timed URLs expire after 5 minutes, and prompts the user to generate a fresh URL from their FoundryVTT account.

- What happens when the user pastes an invalid URL?
  - The script validates the URL format and provides clear guidance on how to generate a valid Timed URL.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The script MUST detect if it's running on a Bazzite system and exit gracefully with a helpful message if not.

- **FR-002**: The script MUST create a new Distrobox container using Ubuntu LTS as the base image.

- **FR-003**: The script MUST install the specific Node.js version recommended by the official FoundryVTT release being installed.

- **FR-004**: The script MUST prompt the user for a data storage location with a sensible default option.

- **FR-005**: The script MUST validate that the chosen data storage path is accessible and writable.

- **FR-006**: The script MUST prompt the user to enable or disable auto-start on system boot.

- **FR-007**: The script MUST create appropriate systemd/Quadlet service files when auto-start is enabled.

- **FR-008**: The script MUST provide clear progress feedback during each step of the setup process.

- **FR-009**: The script MUST handle errors gracefully and provide actionable guidance when something goes wrong.

- **FR-010**: The script MUST be idempotent—running it multiple times should not create duplicate configurations or break existing setups.

- **FR-011**: The script MUST check for internet connectivity before attempting to download dependencies.

- **FR-012**: The script MUST provide a way to launch FoundryVTT after setup completes (manual command or shortcut instructions).

- **FR-013**: The script MUST prompt the user to paste a Timed URL from their FoundryVTT account (generated via the "Timed URL" button on the download page).

- **FR-014**: The script MUST download the Node.js version of FoundryVTT directly using the user-provided Timed URL.

- **FR-015**: The script MUST validate the Timed URL format before attempting download and provide clear guidance if the URL is invalid or expired. Valid URLs match the pattern: `https://r2.foundryvtt.com/releases/{version}/FoundryVTT-{build}-{version}.zip?verify=...`

- **FR-016**: The script MUST check the FoundryVTT release requirements and install the matching Node.js version.

### Key Entities

- **Distrobox Container**: The isolated environment where FoundryVTT runs. Based on Ubuntu LTS (deliberately different from Bazzite's Fedora base to provide clear visual distinction—apt vs dnf—preventing users from accidentally modifying the immutable host). Named consistently for easy identification. Contains Node.js and FoundryVTT application files.

- **Timed URL**: Temporary download link generated from the FoundryVTT website. Format: `https://r2.foundryvtt.com/releases/{version}/FoundryVTT-{build}-{version}.zip?verify={token}`. Expires after 5 minutes. The script should instruct users to select "Node.js" as the build type before generating the URL.

- **Data Directory**: User-specified location for persistent FoundryVTT data (worlds, modules, assets, configuration). Mounted into the container from the host system.

- **Systemd Service**: Optional service unit that manages FoundryVTT auto-start. Created via Quadlet for Bazzite compatibility.

- **User Configuration**: Stored preferences from setup (data path, auto-start preference) that allow the script to be re-run or updated.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user with no Linux experience can complete the entire setup process in under 10 minutes by following on-screen prompts.

- **SC-002**: After setup completes, FoundryVTT is accessible via web browser within 30 seconds of launching.

- **SC-003**: 90% of users complete setup successfully on their first attempt without needing external help.

- **SC-004**: The script runs successfully on all current Bazzite releases (desktop and Steam Deck variants).

- **SC-005**: Data stored in the user-specified location persists across container restarts and system reboots.

- **SC-006**: When auto-start is enabled, FoundryVTT is running and accessible within 2 minutes of system boot completing.

## Clarifications

### Session 2026-02-15

- Q: How does FoundryVTT get installed in the container? → A: User generates a Timed URL from their FoundryVTT account and pastes it into the script. The script downloads FoundryVTT directly using the temporary link (expires in 5 minutes). No credentials are stored or handled by the script.
- Q: Which base image should the Distrobox container use? → A: Ubuntu LTS—provides clear visual distinction from host (apt vs dnf), preventing accidental host modification on immutable Bazzite.
- Q: How should Node.js versioning be handled? → A: Use the specific Node.js version recommended by the official FoundryVTT release, checked at install time.

## Assumptions

- Users have a valid FoundryVTT license. The script prompts users to generate a Timed URL from their account and paste it—no credentials are stored or handled by the script.
- The target system has sufficient disk space for the Distrobox container and FoundryVTT data.
- Users have basic familiarity with running commands in a terminal (copy-paste a single command).
- Distrobox is pre-installed on Bazzite (this is standard for Bazzite systems).
- The default data storage location will be `~/FoundryVTT` unless the user specifies otherwise.
- The official FoundryVTT installation guide is available at: https://foundryvtt.com/article/installation/
