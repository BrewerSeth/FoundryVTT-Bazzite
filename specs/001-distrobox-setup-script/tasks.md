# Tasks: FoundryVTT Distrobox Setup Script

**Input**: Design documents from `/specs/001-distrobox-setup-script/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Not explicitly requested in spec. Manual testing via ShellCheck and Bazzite validation.

**Organization**: Tasks grouped by user story (P1, P2, P3) to enable incremental delivery.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions (from plan.md)

```text
scripts/
└── setup-foundryvtt.sh  # Main setup script

templates/
└── systemd/
    └── foundryvtt.service  # Systemd user service template

docs/
└── troubleshooting.md  # Common issues and solutions
```

---

## Phase 1: Setup (Project Structure)

**Purpose**: Create directory structure and script skeleton

- [x] T001 Create `scripts/` directory at repository root
- [x] T002 Create `templates/systemd/` directory structure at repository root
- [x] T003 Create `docs/` directory at repository root
- [x] T004 [P] Create script skeleton with header comments in `scripts/setup-foundryvtt.sh`
- [x] T005 [P] Create systemd service template in `templates/systemd/foundryvtt.service`

---

## Phase 2: Foundational (Core Functions)

**Purpose**: Implement reusable functions that ALL user stories depend on

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T006 Implement `set -euo pipefail` and error trap handler in `scripts/setup-foundryvtt.sh`
- [x] T007 Implement colored output helpers (info, warn, error, success) in `scripts/setup-foundryvtt.sh`
- [x] T008 Implement `is_bazzite()` detection function per research.md in `scripts/setup-foundryvtt.sh`
- [x] T009 Implement internet connectivity check function in `scripts/setup-foundryvtt.sh`
- [x] T010 Implement config file read/write functions for `~/.config/foundryvtt-bazzite/config` in `scripts/setup-foundryvtt.sh`
- [x] T011 Implement idempotency check (detect existing setup) in `scripts/setup-foundryvtt.sh`
- [x] T012 Implement container state detection functions (exists, running) in `scripts/setup-foundryvtt.sh`
- [x] T013 Run ShellCheck on `scripts/setup-foundryvtt.sh` and fix any warnings

**Checkpoint**: Foundation ready - core functions tested, ShellCheck passes

---

## Phase 3: User Story 1 - First-Time Setup (Priority: P1) MVP

**Goal**: User can run script and get a working FoundryVTT installation with default settings

**Independent Test**: Run script on fresh Bazzite, paste Timed URL, accept defaults, verify FoundryVTT starts at http://localhost:30000

### Implementation for User Story 1

- [x] T014 [US1] Implement Bazzite system check with friendly error message in `scripts/setup-foundryvtt.sh`
- [x] T015 [US1] Implement Timed URL prompt with instructions in `scripts/setup-foundryvtt.sh`
- [x] T016 [US1] Implement Timed URL validation (regex pattern from data-model.md) in `scripts/setup-foundryvtt.sh`
- [x] T017 [US1] Implement `parse_foundry_version()` to extract version from URL per research.md in `scripts/setup-foundryvtt.sh`
- [x] T018 [US1] Implement `get_node_version()` mapping function per research.md in `scripts/setup-foundryvtt.sh`
- [x] T019 [US1] Implement Distrobox container creation (ubuntu:22.04) in `scripts/setup-foundryvtt.sh`
- [x] T020 [US1] Implement Node.js installation via NodeSource inside container in `scripts/setup-foundryvtt.sh`
- [x] T021 [US1] Implement FoundryVTT download and extraction using Timed URL in `scripts/setup-foundryvtt.sh`
- [x] T022 [US1] Implement default data directory creation (`~/FoundryVTT`) in `scripts/setup-foundryvtt.sh`
- [x] T023 [US1] Implement config file save (write setup state) in `scripts/setup-foundryvtt.sh`
- [x] T024 [US1] Implement setup completion message with launch command in `scripts/setup-foundryvtt.sh`
- [x] T025 [US1] Handle expired Timed URL error with helpful retry message in `scripts/setup-foundryvtt.sh`
- [x] T026 [US1] Handle existing container scenario (reconfigure or abort prompt) in `scripts/setup-foundryvtt.sh`
- [x] T027 [US1] Run ShellCheck and verify no regressions in `scripts/setup-foundryvtt.sh`

**Checkpoint**: User Story 1 complete - Fresh install with defaults works end-to-end

---

## Phase 4: User Story 2 - Choose Data Storage Location (Priority: P2)

**Goal**: User can specify custom data directory during setup

**Independent Test**: Run script, choose custom path (e.g., `/mnt/external/FoundryVTT`), verify data is stored there

### Implementation for User Story 2

- [x] T028 [US2] Implement data location prompt with default option (`~/FoundryVTT`) in `scripts/setup-foundryvtt.sh`
- [x] T029 [US2] Implement custom path input with validation in `scripts/setup-foundryvtt.sh`
- [x] T030 [US2] Implement path validation (exists, writable, no spaces) per data-model.md in `scripts/setup-foundryvtt.sh`
- [x] T031 [US2] Implement directory creation offer if path doesn't exist in `scripts/setup-foundryvtt.sh`
- [x] T032 [US2] Implement permission check with guidance message in `scripts/setup-foundryvtt.sh`
- [x] T033 [US2] Update config file save to include custom DATA_PATH in `scripts/setup-foundryvtt.sh`
- [x] T034 [US2] Update launch command output to use user-specified path in `scripts/setup-foundryvtt.sh`
- [x] T035 [US2] Run ShellCheck and verify no regressions in `scripts/setup-foundryvtt.sh`

**Checkpoint**: User Story 2 complete - Custom data paths work correctly

---

## Phase 5: User Story 3 - Configure Auto-Start on Boot (Priority: P3)

**Goal**: User can enable/disable auto-start, systemd service created when enabled

**Independent Test**: Enable auto-start, reboot system, verify FoundryVTT running at http://localhost:30000 without manual start

### Implementation for User Story 3

- [x] T036 [US3] Implement auto-start prompt (yes/no) in `scripts/setup-foundryvtt.sh`
- [x] T037 [US3] Implement systemd service file generation from template in `scripts/setup-foundryvtt.sh`
- [x] T038 [US3] Update `templates/systemd/foundryvtt.service` with variable placeholders per research.md
- [x] T039 [US3] Implement service file installation to `~/.config/systemd/user/foundryvtt.service` in `scripts/setup-foundryvtt.sh`
- [x] T040 [US3] Implement `systemctl --user daemon-reload` call in `scripts/setup-foundryvtt.sh`
- [x] T041 [US3] Implement `systemctl --user enable foundryvtt.service` call in `scripts/setup-foundryvtt.sh`
- [x] T042 [US3] Implement `loginctl enable-linger` for boot-time startup in `scripts/setup-foundryvtt.sh`
- [x] T043 [US3] Implement skip service creation when user declines auto-start in `scripts/setup-foundryvtt.sh`
- [x] T044 [US3] Update config file save to include AUTO_START preference in `scripts/setup-foundryvtt.sh`
- [x] T045 [US3] Add systemctl status/stop commands to completion message in `scripts/setup-foundryvtt.sh`
- [x] T046 [US3] Run ShellCheck and verify no regressions in `scripts/setup-foundryvtt.sh`

**Checkpoint**: User Story 3 complete - Auto-start works on reboot when enabled

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, error handling improvements, final validation

- [x] T047 [P] Create `docs/troubleshooting.md` with common issues from spec.md edge cases
- [x] T048 [P] Update quickstart.md with actual GitHub repository URL in `specs/001-distrobox-setup-script/quickstart.md`
- [x] T049 [P] Add comprehensive script header comments (purpose, usage, prerequisites) in `scripts/setup-foundryvtt.sh`
- [x] T050 Implement progress indicators for long operations (container creation, download) in `scripts/setup-foundryvtt.sh`
- [x] T051 Add interrupt handler (Ctrl+C) with cleanup guidance in `scripts/setup-foundryvtt.sh`
- [x] T052 Final ShellCheck validation - ensure zero warnings in `scripts/setup-foundryvtt.sh`
- [x] T053 Update project README.md with feature 001 installation instructions
- [x] T054 Manual end-to-end test on Bazzite following quickstart.md

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Phase 2 - MVP delivery point
- **User Story 2 (Phase 4)**: Depends on Phase 2 - Can run parallel to US1 if needed
- **User Story 3 (Phase 5)**: Depends on Phase 2 - Can run parallel to US1/US2 if needed
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

| Story | Depends On | Can Parallel With |
|-------|------------|-------------------|
| US1 (P1) | Foundational only | None (MVP) |
| US2 (P2) | Foundational only | US1, US3 |
| US3 (P3) | Foundational only | US1, US2 |

### Within Each User Story

1. Implementation tasks are sequential (build on each other)
2. ShellCheck validation at end of each story
3. Each story adds to single script file (no parallel within story)

### Parallel Opportunities

**Phase 1 (Setup)**:
- T004 and T005 can run in parallel (different files)

**Phase 6 (Polish)**:
- T047, T048, T049 can run in parallel (different files)

**Cross-Story** (if multiple developers):
- After Phase 2, US1/US2/US3 could theoretically parallelize
- However, all modify same file - recommend sequential for simplicity

---

## Parallel Example: Phase 1 Setup

```bash
# These can run together (different files):
Task: "Create script skeleton with header comments in scripts/setup-foundryvtt.sh"
Task: "Create systemd service template in templates/systemd/foundryvtt.service"
```

## Parallel Example: Phase 6 Polish

```bash
# These can run together (different files):
Task: "Create docs/troubleshooting.md with common issues"
Task: "Update quickstart.md with actual GitHub repository URL"  
Task: "Add comprehensive script header comments"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (5 tasks)
2. Complete Phase 2: Foundational (8 tasks)
3. Complete Phase 3: User Story 1 (14 tasks)
4. **STOP and VALIDATE**: Test on Bazzite with defaults
5. Can ship MVP with just US1!

### Incremental Delivery

1. **MVP**: Setup + Foundational + US1 = Working installer with defaults
2. **v1.1**: Add US2 = Custom data paths
3. **v1.2**: Add US3 = Auto-start on boot
4. **v1.3**: Add Polish = Documentation and error handling refinement

### Single Developer Strategy (Recommended)

Execute phases sequentially in order:
- Phase 1 → Phase 2 → Phase 3 (MVP!) → Phase 4 → Phase 5 → Phase 6

---

## Notes

- All user story tasks modify `scripts/setup-foundryvtt.sh` - sequential execution recommended
- [P] tasks indicate different files - safe to parallelize
- ShellCheck validation required at end of each phase
- Commit after each completed phase (not individual tasks)
- Test on actual Bazzite system before shipping
- Constitution requires: `set -euo pipefail`, ShellCheck compliance, clear error messages
