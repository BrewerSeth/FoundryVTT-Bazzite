# Implementation Plan: FoundryVTT Distrobox Setup Script

**Branch**: `001-distrobox-setup-script` | **Date**: 2026-02-15 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-distrobox-setup-script/spec.md`

## Summary

Create a single Bash script that enables Bazzite users to set up FoundryVTT in an isolated Distrobox container. The script guides users through: (1) creating an Ubuntu LTS container, (2) downloading FoundryVTT via user-provided Timed URL, (3) installing the correct Node.js version, (4) configuring data storage location, and (5) optionally enabling auto-start via Quadlet/systemd.

## Technical Context

**Language/Version**: Bash (POSIX-compatible where practical, per constitution)
**Primary Dependencies**: Distrobox, Podman (pre-installed on Bazzite), curl/wget
**Container Base**: Ubuntu 22.04 LTS (Jammy)
**Storage**: File-based config (`~/.config/foundryvtt-bazzite/`), user data directory (default `~/FoundryVTT`)
**Testing**: Manual testing on Bazzite (ShellCheck for static analysis)
**Target Platform**: Bazzite (Fedora-based immutable desktop, including Steam Deck)
**Project Type**: Single script (CLI tool)
**Performance Goals**: Setup completes in <10 minutes, FoundryVTT accessible within 30s of launch
**Constraints**: No root/sudo required, must work offline after initial setup, idempotent
**Scale/Scope**: Single-user setup script, supports one FoundryVTT instance per run

**Research Completed** (see [research.md](./research.md)):
- Ubuntu LTS: **22.04 (Jammy)** - proven stability, NodeSource support for Node.js installation
- Bazzite detection: Check `ID=bazzite` in `/etc/os-release` - unique, reliable, standard
- Node.js version: Extract FoundryVTT version from Timed URL, use hardcoded mapping (V13+: Node 22.x)
- Auto-start: **systemd user service** (NOT Quadlet) - Quadlet incompatible with Distrobox containers

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle Compliance (Constitution v1.4.0)

| Principle | Requirement | Status | Notes |
|-----------|-------------|--------|-------|
| **I. Documentation-First** | User guide, script headers, README, troubleshooting | ✅ PLANNED | quickstart.md will cover user guide; script will have header comments |
| **II. Reproducibility** | Pinned versions, idempotent, isolated, documented state | ✅ PLANNED | Ubuntu LTS pinned, Node.js version from FoundryVTT, config file tracks state |
| **III. Simplicity** | Single-purpose, minimal deps, readable, no premature optimization | ✅ DESIGNED | Single script, uses pre-installed Distrobox/Podman, no external deps |
| **IV. Immutable Infrastructure** | No manual mods, declarative config, rebuild over repair | ✅ PLANNED | systemd user service for auto-start, script recreates container if needed |
| **V. Script Quality** | ShellCheck, error handling, logging, tested paths | ✅ PLANNED | `set -euo pipefail`, progress output, ShellCheck CI |

### Technology Constraints Check

| Constraint | Requirement | Status |
|------------|-------------|--------|
| Host OS | Bazzite | ✅ Script detects and requires Bazzite |
| Container | Distrobox (Podman) with Ubuntu LTS | ✅ Per spec FR-002 |
| Service Mgmt | systemd user service | ✅ Per spec FR-007 (Quadlet not compatible with Distrobox) |
| Language | Bash (POSIX-compatible) | ✅ Single Bash script |
| No root | Avoid sudo unless necessary | ✅ Distrobox handles privilege |

### Gate Status: ✅ PASS (no violations requiring justification)

### Post-Design Re-Check (Phase 1 Complete)

| Principle | Post-Design Status | Notes |
|-----------|-------------------|-------|
| **I. Documentation-First** | ✅ SATISFIED | quickstart.md created, script header spec'd in data-model |
| **II. Reproducibility** | ✅ SATISFIED | Ubuntu 22.04 pinned, Node.js version mapping defined, config schema documented |
| **III. Simplicity** | ✅ SATISFIED | Single script, no external deps beyond pre-installed tools |
| **IV. Immutable Infrastructure** | ✅ SATISFIED | systemd user service (research found Quadlet incompatible with Distrobox) |
| **V. Script Quality** | ✅ PLANNED | Will enforce during implementation |

**Design Changes from Research**:
- Changed from Quadlet to systemd user service (Quadlet doesn't support Distrobox)
- Selected Ubuntu 22.04 over 24.04 (proven stability)

## Project Structure

### Documentation (this feature)

```text
specs/001-distrobox-setup-script/
├── plan.md              # This file
├── research.md          # Phase 0: Technical research findings
├── data-model.md        # Phase 1: Configuration schema, entities
├── quickstart.md        # Phase 1: User-facing setup guide
├── contracts/           # Phase 1: N/A (no API contracts for CLI script)
└── tasks.md             # Phase 2: Implementation tasks (/speckit.tasks)
```

### Source Code (repository root)

```text
scripts/
└── setup-foundryvtt.sh  # Main setup script (feature 001)

templates/
└── systemd/
    └── foundryvtt.service    # Systemd user service template for auto-start

docs/
└── troubleshooting.md   # Common issues and solutions
```

**Structure Decision**: Simple flat structure with `scripts/` for executable scripts and `templates/` for systemd service configuration. No complex directory hierarchy needed for a single-script feature. Future features (backup, update, etc.) will add additional scripts to `scripts/`.

**Note**: Research determined that Quadlet cannot manage Distrobox containers (Quadlet is for raw Podman containers only). Auto-start is implemented via standard systemd user services instead.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

*No violations. All constitution principles satisfied without exceptions.*
