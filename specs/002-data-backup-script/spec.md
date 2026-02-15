# Feature Specification: FoundryVTT Data Backup Script

**Feature Branch**: `002-data-backup-script`  
**Created**: 2026-02-15  
**Status**: Draft  
**Input**: User description: "A script to help a user back up their FoundryVTT data. This would be used for when the user wants to change hosts or for backup."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create a Full Backup (Priority: P1)

A user wants to create a complete backup of their FoundryVTT data before making changes to their system or as a regular safety measure. They run the backup script, which packages all their worlds, modules, assets, and configuration into a single portable archive. The user can then store this backup wherever they choose (external drive, cloud storage, etc.).

**Why this priority**: This is the core functionality—without the ability to create a backup, nothing else matters. Every other feature depends on this.

**Independent Test**: Can be fully tested by running the backup script on a FoundryVTT installation with data, then verifying the backup archive contains all expected files.

**Acceptance Scenarios**:

1. **Given** a FoundryVTT installation with worlds and modules, **When** the user runs the backup script, **Then** a complete backup archive is created containing all user data.

2. **Given** the backup script is running, **When** the backup completes successfully, **Then** the user is shown the backup file location and size.

3. **Given** a backup archive exists, **When** the user examines its contents, **Then** all worlds, modules, assets, and configuration files are present.

---

### User Story 2 - Restore from Backup (Priority: P2)

A user has moved to a new system or needs to recover from data loss. They have a backup archive created by the backup script and want to restore their FoundryVTT data. The script extracts the backup to the appropriate location, and FoundryVTT recognizes all their previous worlds and configurations.

**Why this priority**: A backup is only valuable if it can be restored. This completes the backup/restore cycle and is essential for the migration use case.

**Independent Test**: Can be tested by creating a backup, wiping the data directory, running restore, and verifying FoundryVTT works with all previous data intact.

**Acceptance Scenarios**:

1. **Given** a valid backup archive and a fresh FoundryVTT installation, **When** the user runs the restore command, **Then** all data from the backup is restored to the data directory.

2. **Given** a restore is in progress, **When** the restore completes, **Then** FoundryVTT can be launched and all worlds, modules, and settings from the backup are accessible.

3. **Given** the target data directory already has data, **When** the user attempts to restore, **Then** they are warned and asked to confirm before overwriting existing data.

---

### User Story 3 - Verify Backup Integrity (Priority: P3)

A user wants to ensure their backup archive is valid and complete before relying on it for migration or disaster recovery. The script can verify that a backup archive is not corrupted and contains all expected components.

**Why this priority**: Peace of mind feature—users should be able to trust their backups. Less critical than create/restore but important for confidence.

**Independent Test**: Can be tested by running verify on known-good backups (should pass) and corrupted backups (should fail with clear error).

**Acceptance Scenarios**:

1. **Given** a valid backup archive, **When** the user runs the verify command, **Then** the script confirms the backup is complete and uncorrupted.

2. **Given** a corrupted or incomplete backup archive, **When** the user runs the verify command, **Then** the script reports specific issues found.

---

### Edge Cases

- What happens when the user runs backup with no FoundryVTT data present?
  - The script detects the empty/missing data directory and informs the user there's nothing to back up.

- What happens when there's insufficient disk space for the backup?
  - The script checks available space before starting and warns the user if there's not enough room.

- What happens when a backup is interrupted mid-process?
  - Partial backup files are cleaned up, and the user is informed the backup did not complete.

- What happens when the user tries to restore a backup from an incompatible FoundryVTT version?
  - The script warns about version differences and asks for confirmation before proceeding.

- What happens when the backup destination is not writable?
  - The script detects permission issues and provides guidance on how to resolve them.

- What happens when restoring to a location with existing data?
  - The script warns the user and requires explicit confirmation before overwriting.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The script MUST create a complete backup of all FoundryVTT user data (worlds, modules, assets, configuration).

- **FR-002**: The script MUST package the backup into a single portable archive file.

- **FR-003**: The script MUST allow users to specify a custom destination for the backup file.

- **FR-004**: The script MUST provide a default backup destination if none is specified (user's home directory or data directory).

- **FR-005**: The script MUST display progress feedback during backup and restore operations.

- **FR-006**: The script MUST restore data from a backup archive to the FoundryVTT data directory.

- **FR-007**: The script MUST warn users before overwriting existing data during restore.

- **FR-008**: The script MUST verify backup archive integrity when requested.

- **FR-009**: The script MUST include a timestamp in backup filenames for easy identification.

- **FR-010**: The script MUST check for sufficient disk space before starting backup or restore operations.

- **FR-011**: The script MUST handle errors gracefully and provide actionable guidance when something goes wrong.

- **FR-012**: The script MUST work with the data directory location configured in the setup script (feature 001).

### Key Entities

- **Backup Archive**: A single compressed file containing all FoundryVTT user data. Includes timestamp in filename for identification. Portable across systems.

- **FoundryVTT Data Directory**: The location where FoundryVTT stores user data (worlds, modules, assets, configuration). Source for backups, target for restores.

- **Backup Manifest**: Metadata included in the backup describing its contents, creation date, source FoundryVTT version, and data directory structure.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can create a complete backup of their FoundryVTT data in under 5 minutes for typical installations (under 10GB of data).

- **SC-002**: Users can restore from a backup and have a fully functional FoundryVTT installation in under 10 minutes.

- **SC-003**: 95% of backup archives created by the script can be successfully restored without data loss.

- **SC-004**: Users can identify backups by date/time from the filename without opening the archive.

- **SC-005**: The backup archive is portable—a backup created on one Bazzite system can be restored on a different Bazzite system.

- **SC-006**: Users receive clear confirmation when backup/restore operations complete successfully.

## Assumptions

- The FoundryVTT installation was set up using the setup script (feature 001) or follows standard data directory conventions.
- Users have sufficient disk space for both the backup archive and the restore operation.
- Backup archives are stored by the user in a safe location (the script creates the backup but doesn't manage long-term storage).
- Standard compression formats are sufficient (no need for encryption in the initial version).
- The backup includes user data only, not the FoundryVTT application itself (users can reinstall the application separately).
