# Feature Specification: FoundryVTT Update & Maintenance Script

**Feature Branch**: `003-update-maintenance-script`  
**Created**: 2026-02-15  
**Status**: Draft  
**Input**: User description: "A script to help a user update and maintain DistroBox and their FoundryVTT installation. Could be simply ran to make sure the software and dependencies are up to date."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Quick Health Check (Priority: P1)

A user wants to quickly verify their FoundryVTT installation is healthy and up to date. They run the maintenance script without any arguments, and it checks the status of the Distrobox container, FoundryVTT installation, and dependencies. The script reports what's current and what needs attention, without making any changes unless requested.

**Why this priority**: Users need a safe, non-destructive way to check their system status. This is the foundation for all maintenance activities and should be the default behavior.

**Independent Test**: Can be fully tested by running the script on a known-good installation and verifying it correctly reports component versions and status.

**Acceptance Scenarios**:

1. **Given** a working FoundryVTT installation, **When** the user runs the maintenance script, **Then** they see a summary of all component statuses (container health, FoundryVTT version, Node.js version, available updates).

2. **Given** the script completes its check, **When** updates are available, **Then** the user is informed which components have updates and how to apply them.

3. **Given** the script completes its check, **When** everything is up to date, **Then** the user sees confirmation that no action is needed.

---

### User Story 2 - Update Container Dependencies (Priority: P2)

A user wants to update the packages and dependencies inside their Distrobox container to get security patches and bug fixes. They run the maintenance script with an update option, and it safely updates the container's system packages and Node.js to the latest compatible versions.

**Why this priority**: Keeping dependencies updated is essential for security and stability. This is a common maintenance task that should be simple to perform.

**Independent Test**: Can be tested by running the update on a container with outdated packages and verifying packages are updated without breaking FoundryVTT.

**Acceptance Scenarios**:

1. **Given** a Distrobox container with outdated packages, **When** the user runs the update command, **Then** system packages inside the container are updated to current versions.

2. **Given** an update is in progress, **When** the update completes, **Then** the user sees a summary of what was updated.

3. **Given** the user initiates an update, **When** the update would affect FoundryVTT compatibility, **Then** the user is warned and asked to confirm before proceeding.

---

### User Story 3 - Check for FoundryVTT Updates (Priority: P3)

A user wants to know if a new version of FoundryVTT is available. The script checks the current installed version against the latest available version and informs the user. The script does NOT automatically update FoundryVTT (since this requires license verification and user decision about version compatibility with their modules).

**Why this priority**: FoundryVTT updates require careful consideration (module compatibility, world compatibility). The script should inform but not automatically update.

**Independent Test**: Can be tested by running on systems with different FoundryVTT versions and verifying correct version comparison and reporting.

**Acceptance Scenarios**:

1. **Given** FoundryVTT is installed, **When** the user runs the maintenance script, **Then** they see their current version and whether a newer version is available.

2. **Given** a newer FoundryVTT version is available, **When** the script reports this, **Then** it provides guidance on how to manually update (link to FoundryVTT documentation or update procedure).

3. **Given** FoundryVTT is already at the latest version, **When** the script checks, **Then** the user sees confirmation that they have the latest version.

---

### Edge Cases

- What happens when the Distrobox container doesn't exist or is corrupted?
  - The script detects the missing/broken container and suggests running the setup script (feature 001) to recreate it.

- What happens when there's no internet connection?
  - The script detects this and informs the user that it cannot check for updates without internet, but can still report local status.

- What happens when an update fails mid-process?
  - The script provides clear error messages and suggests recovery steps. Container updates should be atomic where possible.

- What happens when the user has modified the container manually?
  - The script warns about detected modifications and proceeds cautiously, documenting any unexpected configurations.

- What happens when Node.js needs a major version upgrade?
  - The script warns about major version changes and their potential impact, requiring explicit confirmation before proceeding.

- What happens when FoundryVTT is currently running?
  - The script detects this and warns the user. Updates should not proceed while FoundryVTT is running.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The script MUST check the health status of the Distrobox container (running, stopped, missing, corrupted).

- **FR-002**: The script MUST report the current version of FoundryVTT installed.

- **FR-003**: The script MUST report the current version of Node.js in the container.

- **FR-004**: The script MUST check for available system package updates inside the container.

- **FR-005**: The script MUST check if a newer version of FoundryVTT is available (without automatically updating).

- **FR-006**: The script MUST provide an option to update container system packages.

- **FR-007**: The script MUST warn users before applying updates that could affect FoundryVTT compatibility.

- **FR-008**: The script MUST detect if FoundryVTT is currently running and prevent updates during operation.

- **FR-009**: The script MUST provide clear progress feedback during update operations.

- **FR-010**: The script MUST handle errors gracefully and provide recovery guidance when updates fail.

- **FR-011**: The script MUST work without making changes when run without explicit update flags (safe by default).

- **FR-012**: The script MUST check for internet connectivity before attempting to check for or download updates.

### Key Entities

- **Distrobox Container**: The isolated environment running FoundryVTT. Has a health status (running, stopped, missing) and contains system packages that can be updated.

- **FoundryVTT Installation**: The application installed within the container. Has a version number that can be compared against available releases.

- **Container Dependencies**: System packages and Node.js runtime inside the container. Can be updated independently of FoundryVTT.

- **Update Report**: Summary generated by the script showing current versions, available updates, and recommended actions.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can check their system status in under 30 seconds by running a single command.

- **SC-002**: Users receive clear, actionable information about what updates are available and how to apply them.

- **SC-003**: 95% of container dependency updates complete successfully without breaking FoundryVTT functionality.

- **SC-004**: The script never automatically modifies FoundryVTT version without explicit user action.

- **SC-005**: Users can safely run the script at any time without risk of unintended changes (safe by default behavior).

- **SC-006**: Update operations complete within 5 minutes for typical dependency updates.

## Assumptions

- The FoundryVTT installation was set up using the setup script (feature 001) or follows compatible conventions.
- Users are responsible for deciding when to update FoundryVTT itself (the script only informs, doesn't auto-update the application).
- Container package updates follow the base image's package manager conventions.
- Internet connectivity is required to check for updates (local status can be reported offline).
- FoundryVTT must be stopped before applying updates to the container.
- The script recommends but does not require users to create a backup (feature 002) before major updates.
