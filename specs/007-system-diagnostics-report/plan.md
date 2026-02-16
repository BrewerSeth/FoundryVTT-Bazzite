# Implementation Plan: System Diagnostics & Status Report

**Branch**: `007-system-diagnostics-report` | **Date**: 2026-02-15 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/007-system-diagnostics-report/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Create a diagnostic script that generates comprehensive system status reports for FoundryVTT installations on Bazzite. The script provides quick health checks (<5 sec) and detailed diagnostic reports (<30 sec) covering host system, Distrobox containers, FoundryVTT instances, network status, and resource usage. Reports are formatted for both human readability and AI assistant parsing, with optional privacy redaction for safe sharing.

## Technical Context

**Language/Version**: Bash (POSIX-compatible per constitution)  
**Primary Dependencies**: Standard Linux utilities (ps, df, free, ss, journalctl), Distrobox CLI, systemd utilities  
**Storage**: File-based reports (text/markdown output), reads from `~/.config/foundryvtt-bazzite/config`  
**Testing**: Manual testing on Bazzite (ShellCheck for static analysis)  
**Target Platform**: Bazzite Linux (Fedora-based immutable desktop, Steam Deck compatible)  
**Project Type**: Single CLI script  
**Performance Goals**: Quick check <5 seconds, full report <30 seconds  
**Constraints**: No elevated privileges required, must work offline, lightweight (<10MB RAM usage)  
**Scale/Scope**: Single-user diagnostic tool, one instance per run, supports Feature 005 multi-instance reporting

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle Compliance (Constitution v1.3.0)

| Principle | Requirement | Status | Notes |
|-----------|-------------|--------|-------|
| **I. Documentation-First** | User guide, script headers, README, troubleshooting | ✅ PLANNED | quickstart.md will cover user guide; script will have header comments |
| **II. Reproducibility** | Pinned versions, idempotent, isolated, documented state | ✅ DESIGNED | Reads from existing config file, consistent report format |
| **III. Simplicity** | Single-purpose, minimal deps, readable, no premature optimization | ✅ DESIGNED | Single script, uses standard Linux tools, no external dependencies |
| **IV. Immutable Infrastructure** | No manual mods, declarative config, rebuild over repair | ✅ PLANNED | Script only reads/diagnoses, doesn't modify systems |
| **V. Script Quality** | ShellCheck, error handling, logging, tested paths | ✅ PLANNED | `set -euo pipefail`, graceful degradation for missing info, ShellCheck CI |

### Technology Constraints Check

| Constraint | Requirement | Status |
|------------|-------------|--------|
| Host OS | Bazzite | ✅ Script detects Bazzite using same method as Feature 001 |
| Container | Distrobox (Podman) | ✅ Queries existing containers, no modifications |
| Service Mgmt | systemd | ✅ Reads service status via systemctl --user |
| Language | Bash (POSIX-compatible) | ✅ Single Bash script |
| No root | Avoid sudo unless necessary | ✅ Reads-only, no privilege escalation needed |

### Gate Status: ✅ PASS (no violations requiring justification)

### Post-Design Re-Check (Phase 1 Complete)

| Principle | Post-Design Status | Notes |
|-----------|-------------------|-------|
| **I. Documentation-First** | ✅ SATISFIED | quickstart.md created, script header spec'd in data-model |
| **II. Reproducibility** | ✅ SATISFIED | Report format consistent, reads from Feature 001 config |
| **III. Simplicity** | ✅ SATISFIED | Single script, standard Linux tools only |
| **IV. Immutable Infrastructure** | ✅ SATISFIED | Read-only diagnostics, no system modifications |
| **V. Script Quality** | ✅ PLANNED | Will enforce during implementation |

## Project Structure

### Documentation (this feature)

```text
specs/007-system-diagnostics-report/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
scripts/
└── foundryvtt-diagnose.sh  # Main diagnostic script (feature 007)

docs/
└── troubleshooting.md   # Common issues and solutions (reference for diagnostics)
```

**Structure Decision**: Simple structure with `scripts/` for executable diagnostic script. Follows Feature 001 pattern. Script name `foundryvtt-diagnose.sh` to be consistent with `setup-foundryvtt.sh` naming convention.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

*No violations. All constitution principles satisfied without exceptions.*

**Design Decisions**:
- Single script approach (vs. multiple specialized scripts) - simpler for users
- Standard Linux tools only (vs. external dependencies like `jq`) - meets Simplicity principle
- Read-only diagnostics (vs. auto-repair) - meets Immutable Infrastructure principle
