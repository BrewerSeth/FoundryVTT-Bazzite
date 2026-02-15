# Feature Specification: Data Backup Script

**Feature Branch**: `002-data-backup-script`  
**Created**: 2026-02-15  
**Status**: Draft  
**Input**: User description: "002 Data backup script"

## Overview

A script that allows users to back up their FoundryVTT data (worlds, modules, assets, configuration) to protect against data loss. The backup should be easy to create, portable, and restorable.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create a Backup (Priority: P1)

As a FoundryVTT user, I want to create a backup of all my FoundryVTT data with a single command so that I can protect my worlds and assets from data loss.

**Why this priority**: This is the core functionality - without the ability to create backups, no other features matter. Users need confidence that their game data is safe.

**Independent Test**: Run the backup script, verify a backup archive is created containing all FoundryVTT data directories (worlds, modules, assets, etc.), and confirm the archive is valid and complete.

**Acceptance Scenarios**:

1. **Given** FoundryVTT is installed with the setup script, **When** user runs the backup script, **Then** a compressed backup archive is created containing all user data
2. **Given** FoundryVTT is running, **When** user runs the backup script, **Then** the script warns the user and offers to stop FoundryVTT before backing up (to ensure data consistency)
3. **Given** backup completes successfully, **When** user views the output, **Then** they see a summary showing backup size, location, and files included

---

### User Story 2 - Restore from Backup (Priority: P2)

As a FoundryVTT user, I want to restore my data from a previous backup so that I can recover from data loss or migrate to a new system.

**Why this priority**: Backups are useless without restore capability. This completes the data protection story.

**Independent Test**: Create a backup, delete the data directory, run restore, verify all data is recovered and FoundryVTT works correctly.

**Acceptance Scenarios**:

1. **Given** a valid backup archive exists, **When** user runs restore command with the backup path, **Then** data is extracted to the correct location
2. **Given** data already exists at the target location, **When** user runs restore, **Then** they are warned and asked to confirm overwrite or merge
3. **Given** restore completes, **When** user starts FoundryVTT, **Then** all worlds, modules, and settings are intact

---

### User Story 3 - List Available Backups (Priority: P3)

As a FoundryVTT user, I want to see a list of my available backups so that I can choose which one to restore or manage my backup storage.

**Why this priority**: Helpful for users with multiple backups, but not essential for basic backup/restore functionality.

**Independent Test**: Create multiple backups, run list command, verify all backups are shown with dates and sizes.

**Acceptance Scenarios**:

1. **Given** multiple backups exist in the default backup location, **When** user runs list command, **Then** backups are displayed sorted by date with size information
2. **Given** no backups exist, **When** user runs list command, **Then** a helpful message indicates no backups found

---

### Edge Cases

- What happens when disk space is insufficient for the backup?
- How does the system handle corrupted backup archives during restore?
- What happens if FoundryVTT data directory doesn't exist (fresh system)?
- How are very large data directories (10GB+) handled?
- What happens if backup is interrupted (Ctrl+C)?
- How are permission issues handled (read-only files, locked files)?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST create a compressed archive of the FoundryVTT data directory
- **FR-002**: System MUST include all subdirectories: worlds, modules, systems, assets, Config, Data
- **FR-003**: System MUST detect if FoundryVTT is running and warn the user before backup
- **FR-004**: System MUST display progress during backup and restore operations
- **FR-005**: System MUST verify backup integrity after creation (validate archive)
- **FR-006**: System MUST restore backups to the configured data directory
- **FR-007**: System MUST prompt for confirmation before overwriting existing data during restore
- **FR-008**: System MUST read the data path from the existing FoundryVTT-Bazzite configuration
- **FR-009**: System MUST create timestamped backup filenames for easy identification
- **FR-010**: System MUST support a custom backup destination path
- **FR-011**: System MUST list available backups with date and size information
- **FR-012**: System MUST handle insufficient disk space gracefully with a clear error message
- **FR-013**: System MUST clean up partial backups if the process is interrupted

### Key Entities

- **Backup Archive**: A compressed file containing all FoundryVTT user data, identified by timestamp
- **Data Directory**: The FoundryVTT data path (from setup script configuration) containing worlds, modules, etc.
- **Backup Location**: Where backup archives are stored (default: alongside data directory or user-specified)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can create a complete backup in under 5 minutes for data directories up to 5GB
- **SC-002**: Users can restore from backup in under 5 minutes for archives up to 5GB
- **SC-003**: 100% of backup operations produce valid, extractable archives
- **SC-004**: Users can identify backups by date/time from the filename and list output
- **SC-005**: Zero data loss when restoring from a backup created while FoundryVTT was stopped

## Scope

### In Scope

- Manual backup triggered by user command
- Local backup storage (same machine or mounted drive)
- Backup and restore of FoundryVTT data directory
- Integration with existing FoundryVTT-Bazzite setup (reads config)
- Backup listing and management

### Out of Scope

- Automatic/scheduled backups (future feature)
- Remote/cloud backup destinations (future feature)
- Incremental backups (full backups only)
- Backup encryption (future feature)
- Backup rotation/retention policies (manual management for now)

## Assumptions

- User has already installed FoundryVTT using the setup script (config file exists)
- Sufficient disk space exists for backup archive (script will check and warn)
- User has read access to FoundryVTT data directory
- User has write access to backup destination
- Standard compression tools available on Bazzite (tar, gzip)
- Backups stored locally (not network/cloud)

## Dependencies

- Feature 001 (Distrobox Setup Script) must be complete - backup script reads configuration from it
- FoundryVTT data directory must exist with standard structure
