# Feature Specification: System Diagnostics & Status Report

**Feature Branch**: `007-system-diagnostics-report`  
**Created**: 2026-02-15  
**Status**: Draft  
**Input**: User description: "The user must be able to understand what is going on with the server at any time. A script that a user could run to report what is going on with the server, the host, the distrobox, etc. I would expect this log would be able to be consumed by an AI assistant to help the user troubleshoot the system."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Generate System Status Report (Priority: P1)

A user notices something isn't working right with their FoundryVTT setup—maybe players can't connect, or the game is running slowly. They run the diagnostics script, which generates a comprehensive report covering the host system, Distrobox container, FoundryVTT instances, network status, and resource usage. The report is formatted so both humans and AI assistants can easily understand and analyze it.

**Why this priority**: This is the core feature—generating actionable diagnostic information. Without this, troubleshooting is guesswork.

**Independent Test**: Can be fully tested by running the script and verifying the report contains all expected sections with accurate information about the current system state.

**Acceptance Scenarios**:

1. **Given** a system with FoundryVTT installed, **When** the user runs the diagnostics script, **Then** a comprehensive status report is generated covering all system components.

2. **Given** the report is generated, **When** the user views it, **Then** they can identify which components are healthy (green), warning (yellow), or problematic (red).

3. **Given** the report is generated, **When** an AI assistant receives the report text, **Then** it can parse the information and provide troubleshooting guidance.

---

### User Story 2 - Quick Health Check (Priority: P2)

A user wants a fast overview of system health without all the details—just a quick "is everything okay?" check. They run the script with a summary option, which shows a brief status of each major component (host, container, instances, network) with simple pass/fail indicators.

**Why this priority**: Often users just need to quickly verify things are working. A full report is overkill for routine checks.

**Independent Test**: Can be tested by running the quick check and verifying it completes in seconds with clear pass/fail status for each component.

**Acceptance Scenarios**:

1. **Given** a healthy system, **When** the user runs the quick health check, **Then** they see all components marked as healthy within a few seconds.

2. **Given** a system with an issue, **When** the user runs the quick health check, **Then** the problematic component is clearly flagged, prompting them to run a full report.

---

### User Story 3 - Share Report for Support (Priority: P3)

A user needs help troubleshooting and wants to share their diagnostics report with someone (community forum, AI assistant, tech-savvy friend). The script can output the report in a format that's easy to copy/paste (text) or save to a file. Sensitive information (like IP addresses or paths) can optionally be redacted for privacy.

**Why this priority**: Sharing diagnostic info is key to getting help. Privacy-conscious export options enable this safely.

**Independent Test**: Can be tested by generating a report with redaction enabled and verifying sensitive data is masked while diagnostic value is preserved.

**Acceptance Scenarios**:

1. **Given** a generated report, **When** the user saves it to a file, **Then** they can share that file with support resources.

2. **Given** the user runs the report with privacy redaction, **When** the report is generated, **Then** IP addresses, full paths, and usernames are masked.

3. **Given** a redacted report, **When** an AI assistant analyzes it, **Then** there is still enough information to provide useful troubleshooting advice.

---

### Edge Cases

- What happens when the Distrobox container doesn't exist?
  - The report indicates the container is missing and suggests running the setup script.

- What happens when FoundryVTT isn't installed yet?
  - The report shows host system status and indicates FoundryVTT is not configured.

- What happens when the script can't access certain information (permissions)?
  - The report indicates which sections couldn't be collected and why.

- What happens when the system is severely resource-constrained?
  - The script is lightweight and still generates a report, highlighting the resource issues.

- What happens when running the report while the system is under heavy load?
  - The report captures the current state, showing high resource usage as part of diagnostics.

- What happens when multiple FoundryVTT instances exist (feature 005)?
  - The report includes status for all configured instances.

- What happens when the host system cannot check for updates (offline or broken rpm-ostree)?
  - The report indicates update check failed and suggests manual check with `ujust update --check`.

- What happens when the guest container cannot check for updates (offline or broken apt)?
  - The report indicates update check failed and suggests entering the container and running `apt update`.

- What happens when update checks take too long?
  - The script implements a 10-second timeout for update checks to keep the report generation fast.

- What happens when FoundryVTT data directory is extremely large (100GB+)?
  - The script uses sampling or timeout for size calculation to prevent hanging, and reports "Large directory (sampling)" with estimated size.

- What happens when Config/options.json is missing or corrupted?
  - The report indicates configuration is unavailable and suggests checking data directory permissions.

- What happens when FoundryVTT version check API is unreachable?
  - The report shows installed version without comparison, indicating "version check unavailable (offline)".

- What happens when a world/module/system directory cannot be read?
  - The report counts accessible items and notes permission errors for inaccessible directories.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The script MUST report host system status (OS version, uptime, resource usage).

- **FR-002**: The script MUST report Distrobox container status (running, stopped, health, resource usage).

- **FR-003**: The script MUST report FoundryVTT instance status for all configured instances (running, stopped, version, port, errors).

- **FR-004**: The script MUST report network status (local connectivity, remote access status, tunnel status if configured).

- **FR-005**: The script MUST report disk space usage for the host and FoundryVTT data directories.

- **FR-006**: The script MUST report recent errors or warnings from FoundryVTT logs.

- **FR-007**: The script MUST provide a quick summary mode showing pass/fail for major components.

- **FR-008**: The script MUST provide a detailed report mode with comprehensive diagnostic information.

- **FR-009**: The script MUST format output for both human readability and AI assistant parsing (structured, labeled sections).

- **FR-010**: The script MUST support saving the report to a file.

- **FR-011**: The script MUST support optional privacy redaction (mask IPs, paths, usernames).

- **FR-012**: The script MUST indicate the overall health status (healthy, degraded, critical) based on component states.

- **FR-013**: The script MUST include timestamps for when the report was generated and when data was collected.

- **FR-014**: The script MUST complete the quick check within 5 seconds; full report within 30 seconds.

- **FR-015**: The script MUST report available system updates for the host (Bazzite) using `rpm-ostree status` and `ujust update --check`.

- **FR-016**: The script MUST report available package updates for the guest Distrobox container using `apt list --upgradable`.

- **FR-017**: The script SHOULD warn users if the host system has pending updates that may affect FoundryVTT operation.

- **FR-018**: The script SHOULD warn users if the guest container has security updates available.

- **FR-019**: The script MUST report detailed FoundryVTT configuration information including:
  - Data directory size and breakdown (worlds, modules, systems, assets)
  - Count of installed worlds, modules, and systems
  - Key configuration values from Config/options.json (without sensitive data)
  - Total number of users/players (if accessible)

- **FR-020**: The script SHOULD check if the installed FoundryVTT version is the latest available by querying the FoundryVTT releases API or website.

- **FR-021**: The script MUST report the largest directories/files in the FoundryVTT data path to help identify storage bloat.

- **FR-022**: The script SHOULD identify potential configuration issues (missing required settings, deprecated options, performance-related settings).

### Key Entities

- **Diagnostic Report**: The complete output document containing all system status information. Structured in sections for easy parsing.

- **Component Status**: Health state of a system component (host, container, instance, network). States: healthy, warning, critical, unknown.

- **Log Excerpt**: Recent entries from FoundryVTT logs relevant to troubleshooting. Limited to recent timeframe to keep report manageable.

- **Resource Metrics**: Current usage of CPU, memory, disk. Compared against thresholds to determine warning/critical states.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can generate a quick health check in under 5 seconds.

- **SC-002**: Users can generate a full diagnostic report in under 30 seconds.

- **SC-003**: The report clearly identifies the source of common issues (container not running, disk full, port conflict) 90% of the time.

- **SC-004**: An AI assistant can parse the report and provide relevant troubleshooting steps based on its contents.

- **SC-005**: Users can share a privacy-redacted report without exposing sensitive system information.

- **SC-006**: The report format remains consistent across runs, enabling comparison of system state over time.

## Assumptions

- The diagnostics script can access necessary system information without requiring elevated privileges (or gracefully handles restricted access).
- Report format uses clear section headers and labels that AI assistants can reliably parse.
- "Recent" logs means last 100 entries or last 24 hours, whichever is smaller.
- Resource thresholds for warnings: CPU >80%, Memory >85%, Disk >90%.
- Resource thresholds for critical: CPU >95%, Memory >95%, Disk >95%.
- Privacy redaction replaces sensitive values with placeholder tokens (e.g., `[REDACTED_IP]`, `[REDACTED_PATH]`).
- The report includes version numbers of FoundryVTT-Bazzite scripts for support context.
