# Feature Specification: Multiple FoundryVTT Instance Support

**Feature Branch**: `005-multi-instance-support`  
**Created**: 2026-02-15  
**Status**: Draft  
**Input**: User description: "The ability to have multiple servers set up for FoundryVTT. FoundryVTT only allows one active game at a time per instance. The user might want to have two different instances, like one for D&D5e and one for Pathfinder. Those instances might want to have shared content like music assets across both of them. Instances should be able to run concurrently so players from different groups can access them at the same time."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create Additional Instance (Priority: P1)

A user already has one FoundryVTT instance running (e.g., for their D&D campaign). They want to set up a second instance for a different game system (e.g., Pathfinder) without affecting their existing setup. They run a script that creates a new named instance with its own data directory, modules, worlds, and unique port number, while keeping both instances completely separate.

**Why this priority**: This is the core feature—the ability to have multiple isolated FoundryVTT installations. Without this, the other features don't matter.

**Independent Test**: Can be fully tested by creating a second instance, launching it, and verifying it has its own separate worlds and modules while the original instance remains unchanged.

**Acceptance Scenarios**:

1. **Given** a working FoundryVTT instance, **When** the user creates a new instance with a unique name (e.g., "pathfinder"), **Then** a separate instance is created with its own data directory and assigned port.

2. **Given** multiple instances exist, **When** the user lists instances, **Then** they see all instance names, their ports, and current status (running/stopped).

3. **Given** two instances exist, **When** the user modifies one instance (adds modules, creates worlds), **Then** the other instance is unaffected.

---

### User Story 2 - Run Multiple Instances Concurrently (Priority: P2)

A user hosts games for multiple groups—a Tuesday D&D group and a Thursday Pathfinder group. They want both instances running simultaneously so players can access their respective games anytime (to review character sheets, prepare for sessions, etc.). Each instance runs on its own port, and players connect to their specific game's URL.

**Why this priority**: Concurrent access is the key differentiator from simply having multiple data directories. This enables true multi-group hosting.

**Independent Test**: Can be tested by starting two instances simultaneously and verifying both are accessible from different browser tabs at the same time.

**Acceptance Scenarios**:

1. **Given** two instances exist, **When** the user starts both instances, **Then** both run concurrently on different ports and are accessible simultaneously.

2. **Given** multiple instances are running, **When** players access each instance's URL, **Then** they reach the correct FoundryVTT instance for their game.

3. **Given** multiple instances are running, **When** the user checks status, **Then** they see which instances are running and on which ports.

---

### User Story 3 - Share Assets Between Instances (Priority: P3)

A user has a large music library and art assets they want to use across multiple FoundryVTT instances. Instead of duplicating gigabytes of files, they configure a shared assets folder that all instances can access. When they add new music to the shared folder, it becomes available in all their instances.

**Why this priority**: This is an important optimization for users with multiple instances and large asset libraries. It saves disk space and simplifies asset management, but instances work fine without it.

**Independent Test**: Can be tested by setting up shared assets, adding a file to the shared folder, and verifying it's accessible from multiple instances.

**Acceptance Scenarios**:

1. **Given** multiple instances exist, **When** the user configures a shared assets folder, **Then** all instances can access files in that folder.

2. **Given** shared assets are configured, **When** the user adds a music file to the shared folder, **Then** the file is accessible from all instances without copying.

3. **Given** shared assets are configured, **When** the user accesses assets from an instance, **Then** they see both instance-specific assets and shared assets.

---

### User Story 4 - Manage Instance Lifecycle (Priority: P4)

A user no longer needs one of their FoundryVTT instances and wants to remove it. They can delete an instance (with confirmation) which removes its data directory. They can also view details about each instance, start/stop individual instances, or start/stop all instances at once.

**Why this priority**: Housekeeping feature for managing instances over time. Lower priority since users can work around this manually.

**Independent Test**: Can be tested by creating an instance, deleting it, and verifying it's removed from the instance list and its data is cleaned up.

**Acceptance Scenarios**:

1. **Given** an instance exists, **When** the user deletes it with confirmation, **Then** the instance is removed and its data directory is deleted.

2. **Given** an instance exists, **When** the user requests instance details, **Then** they see the instance name, port, data location, creation date, and disk usage.

3. **Given** multiple instances are running, **When** the user runs "stop all", **Then** all instances are stopped gracefully.

---

### Edge Cases

- What happens when the user tries to create an instance with a name that already exists?
  - The script detects the conflict and asks the user to choose a different name.

- What happens when the user tries to create an instance but all reasonable ports are in use?
  - The script warns about port exhaustion and suggests freeing ports or manually specifying one.

- What happens when the user tries to delete an instance that is currently running?
  - The script stops the instance first (with warning) before deleting, or requires the user to stop it manually.

- What happens when shared assets folder becomes unavailable (e.g., external drive disconnected)?
  - Running instances continue but log warnings about missing shared assets. Instance-specific assets still work.

- What happens when the system doesn't have enough resources for multiple concurrent instances?
  - The script provides guidance on resource requirements (RAM, CPU) per instance and warns if the system appears constrained.

- What happens when the user runs out of disk space while creating a new instance?
  - The script checks available space and warns before proceeding if space is low.

- What happens when two instances try to use the same port?
  - The script assigns unique ports automatically and detects/prevents port conflicts.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The script MUST allow users to create new named FoundryVTT instances with separate data directories.

- **FR-002**: The script MUST ensure each instance has isolated worlds, modules, and configuration.

- **FR-003**: The script MUST assign each instance a unique port number (auto-assigned or user-specified).

- **FR-004**: The script MUST list all configured instances with their names, ports, and current status.

- **FR-005**: The script MUST allow users to start a specific instance by name.

- **FR-006**: The script MUST allow users to stop a specific instance by name.

- **FR-007**: The script MUST support running multiple instances concurrently on different ports.

- **FR-008**: The script MUST provide commands to start all or stop all instances at once.

- **FR-009**: The script MUST support configuring a shared assets folder accessible by all instances.

- **FR-010**: The script MUST allow users to delete an instance with confirmation.

- **FR-011**: The script MUST display instance details (name, port, location, size, creation date, status).

- **FR-012**: The script MUST prevent creating instances with duplicate names.

- **FR-013**: The script MUST prevent port conflicts between instances.

- **FR-014**: The script MUST integrate with existing features (backup, remote access, auto-start) on a per-instance basis.

- **FR-015**: The script MUST allow configuring which instances auto-start on system boot.

### Key Entities

- **Instance**: A named FoundryVTT installation with its own data directory, configuration, worlds, modules, and assigned port. Multiple instances can run concurrently.

- **Instance Registry**: Record of all configured instances, their names, ports, data locations, and metadata. Used by scripts to manage instances.

- **Shared Assets Folder**: Optional common directory containing assets (music, images, etc.) accessible by all instances. Saves disk space for large asset libraries.

- **Instance Port**: The network port each instance listens on. Must be unique per instance to allow concurrent operation.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can create a new instance in under 2 minutes.

- **SC-002**: Users can start/stop individual instances in under 10 seconds.

- **SC-003**: Multiple instances (at least 3) can run concurrently without conflicts, each accessible on its own port.

- **SC-004**: Each instance's worlds and modules are completely isolated—changes to one never affect another.

- **SC-005**: Shared assets are accessible from all instances without file duplication.

- **SC-006**: Users can manage 5+ instances without confusion (clear naming, port visibility, status).

- **SC-007**: Existing features (backup, remote access, updates) work correctly on a per-instance basis.

- **SC-008**: Players from different groups can access their respective instances simultaneously.

## Assumptions

- Users have sufficient disk space for multiple instances (each instance requires space for its own worlds, modules, and instance-specific assets).
- Users have sufficient system resources (RAM, CPU) to run multiple concurrent instances. Each FoundryVTT instance has modest requirements, but running many simultaneously may require more capable hardware.
- The FoundryVTT license allows running multiple instances concurrently (users should verify their license terms).
- Instance names are simple identifiers (alphanumeric, no spaces) for easy command-line use.
- The first instance created by the setup script (feature 001) becomes the "default" instance on the default port.
- Shared assets use a folder outside any single instance's data directory.
- Remote access configuration (feature 004) is per-instance—each instance can have its own tunnel URL pointing to its unique port.
- Backup script (feature 002) backs up the specified instance (or all instances with an "all" option).
- Port numbers are auto-assigned starting from a base port (e.g., 30000, 30001, 30002...) unless user specifies otherwise.
