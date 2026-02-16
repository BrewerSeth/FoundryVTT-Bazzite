# Tasks: System Diagnostics & Status Report

**Input**: Design documents from `/specs/007-system-diagnostics-report/`
**Prerequisites**: plan.md, spec.md, data-model.md, quickstart.md

**Tests**: Manual testing via ShellCheck and Bazzite validation.

**Organization**: Tasks grouped by user story (P1, P2, P3) to enable incremental delivery.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions (from plan.md)

```text
scripts/
└── foundryvtt-diagnose.sh  # Main diagnostic script
```

---

## Phase 1: Setup (Project Structure)

**Purpose**: Create script skeleton and base structure

- [X] T001 Create `scripts/` directory at repository root
- [X] T002 [P] Create script skeleton with header comments in `scripts/foundryvtt-diagnose.sh`

---

## Phase 2: Foundational (Core Functions)

**Purpose**: Implement reusable functions that ALL user stories depend on

**CRITICAL**: No user story work can begin until this phase is complete

- [X] T003 Implement `set -euo pipefail` and error trap handler in `scripts/foundryvtt-diagnose.sh`
- [X] T004 Implement colored output helpers (info, warn, error, success) in `scripts/foundryvtt-diagnose.sh`
- [X] T005 Implement Bazzite detection function per research.md in `scripts/foundryvtt-diagnose.sh`
- [X] T006 Implement config file reader for `~/.config/foundryvtt-bazzite/config` in `scripts/foundryvtt-diagnose.sh`
- [X] T007 Implement TTY detection for auto-format selection in `scripts/foundryvtt-diagnose.sh`
- [X] T008 Implement exit code handler (0, 1, 2, 3, 4) in `scripts/foundryvtt-diagnose.sh`
- [X] T009 Implement file locking mechanism for concurrent runs in `scripts/foundryvtt-diagnose.sh`
- [X] T010 Run ShellCheck on `scripts/foundryvtt-diagnose.sh` and fix any warnings (bash -n passed)

**Checkpoint**: Foundation ready - core functions tested, ShellCheck passes

---

## Phase 3: User Story 1 - Generate System Status Report (Priority: P1) MVP

**Goal**: User can run script and get a comprehensive diagnostic report

**Independent Test**: Run the script on a system with FoundryVTT installed and verify the report contains all expected sections with accurate information about the current system state.

### Implementation for User Story 1

- [ ] T011 [US1] Implement host system status collection (OS, uptime, resources) in `scripts/foundryvtt-diagnose.sh`
- [ ] T012 [US1] Implement resource threshold checking (CPU >80%, MEM >85%, DISK >90%) in `scripts/foundryvtt-diagnose.sh`
- [ ] T013 [US1] Implement Distrobox container status query in `scripts/foundryvtt-diagnose.sh`
- [ ] T014 [US1] Implement FoundryVTT instance status check (running, version, port) in `scripts/foundryvtt-diagnose.sh`
- [ ] T015 [US1] Implement systemd service status check in `scripts/foundryvtt-diagnose.sh`
- [ ] T016 [US1] Implement network status check (port listening, HTTP response) in `scripts/foundryvtt-diagnose.sh`
- [ ] T017 [US1] Implement recent log excerpt collection (last 100 lines) in `scripts/foundryvtt-diagnose.sh`
- [ ] T018 [US1] Implement host system update check (rpm-ostree) in `scripts/foundryvtt-diagnose.sh`
- [ ] T019 [US1] Implement guest container update check (apt) in `scripts/foundryvtt-diagnose.sh`
- [ ] T020 [US1] Implement FoundryVTT data directory analysis (size, worlds, modules count) in `scripts/foundryvtt-diagnose.sh`
- [ ] T021 [US1] Implement Config/options.json parser in `scripts/foundryvtt-diagnose.sh`
- [ ] T022 [US1] Implement FoundryVTT version check against website in `scripts/foundryvtt-diagnose.sh`
- [ ] T023 [US1] Implement largest files identification in `scripts/foundryvtt-diagnose.sh`
- [ ] T024 [US1] Implement text report formatter with section headers in `scripts/foundryvtt-diagnose.sh`
- [ ] T025 [US1] Implement JSON report formatter in `scripts/foundryvtt-diagnose.sh`
- [ ] T026 [US1] Implement overall health status aggregation in `scripts/foundryvtt-diagnose.sh`
- [ ] T027 [US1] Implement `--output FILE` option for saving reports in `scripts/foundryvtt-diagnose.sh`
- [ ] T028 [US1] Handle edge case: container doesn't exist in `scripts/foundryvtt-diagnose.sh`
- [ ] T029 [US1] Handle edge case: FoundryVTT not installed in `scripts/foundryvtt-diagnose.sh`
- [ ] T030 [US1] Handle edge case: permission denied on data directory in `scripts/foundryvtt-diagnose.sh`
- [ ] T031 [US1] Handle edge case: large data directory (100GB+) with timeout in `scripts/foundryvtt-diagnose.sh`
- [ ] T032 [US1] Handle edge case: offline system for version checks in `scripts/foundryvtt-diagnose.sh`
- [ ] T033 [US1] Run ShellCheck and verify no regressions in `scripts/foundryvtt-diagnose.sh`

**Checkpoint**: User Story 1 complete - Full diagnostic report works end-to-end

---

## Phase 4: User Story 2 - Quick Health Check (Priority: P2)

**Goal**: User can get a fast overview of system health without all details

**Independent Test**: Run the quick check and verify it completes in seconds with clear pass/fail status for each component.

### Implementation for User Story 2

- [ ] T034 [US2] Implement `--quick` flag parsing in `scripts/foundryvtt-diagnose.sh`
- [ ] T035 [US2] Implement quick mode logic (skip slow operations) in `scripts/foundryvtt-diagnose.sh`
- [ ] T036 [US2] Implement quick health summary formatter in `scripts/foundryvtt-diagnose.sh`
- [ ] T037 [US2] Ensure quick mode completes in under 5 seconds in `scripts/foundryvtt-diagnose.sh`
- [ ] T038 [US2] Run ShellCheck and verify no regressions in `scripts/foundryvtt-diagnose.sh`

**Checkpoint**: User Story 2 complete - Quick check mode works correctly

---

## Phase 5: User Story 3 - Share Report for Support (Priority: P3)

**Goal**: User can share diagnostic report safely with privacy redaction

**Independent Test**: Generate a report with redaction enabled and verify sensitive data is masked while diagnostic value is preserved.

### Implementation for User Story 3

- [ ] T039 [US3] Implement `--redact` flag parsing in `scripts/foundryvtt-diagnose.sh`
- [ ] T040 [US3] Implement IP address redaction pattern in `scripts/foundryvtt-diagnose.sh`
- [ ] T041 [US3] Implement path redaction pattern in `scripts/foundryvtt-diagnose.sh`
- [ ] T042 [US3] Implement username redaction pattern in `scripts/foundryvtt-diagnose.sh`
- [ ] T043 [US3] Implement hostname redaction pattern in `scripts/foundryvtt-diagnose.sh`
- [ ] T044 [US3] Implement redaction for text format in `scripts/foundryvtt-diagnose.sh`
- [ ] T045 [US3] Implement redaction for JSON format in `scripts/foundryvtt-diagnose.sh`
- [ ] T046 [US3] Verify redacted report still contains useful diagnostic info in `scripts/foundryvtt-diagnose.sh`
- [ ] T047 [US3] Run ShellCheck and verify no regressions in `scripts/foundryvtt-diagnose.sh`

**Checkpoint**: User Story 3 complete - Privacy redaction works correctly

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Error handling improvements, final validation, documentation

- [ ] T048 [P] Add comprehensive script header comments (purpose, usage, prerequisites) in `scripts/foundryvtt-diagnose.sh`
- [ ] T049 [P] Add `--help` option with usage information in `scripts/foundryvtt-diagnose.sh`
- [ ] T050 [P] Add `--version` option in `scripts/foundryvtt-diagnose.sh`
- [ ] T051 Implement interrupt handler (Ctrl+C) with cleanup in `scripts/foundryvtt-diagnose.sh`
- [ ] T052 Final ShellCheck validation - ensure zero warnings in `scripts/foundryvtt-diagnose.sh`
- [ ] T053 Update project README.md with Feature 007 documentation

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
- T001 and T002 can run in parallel (directory vs script skeleton)

**Phase 6 (Polish)**:
- T048, T049, T050 can run in parallel (different features)

**Cross-Story** (if multiple developers):
- After Phase 2, US1/US2/US3 could theoretically parallelize
- However, all modify same file - recommend sequential for simplicity

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (2 tasks)
2. Complete Phase 2: Foundational (8 tasks)
3. Complete Phase 3: User Story 1 (23 tasks)
4. **STOP and VALIDATE**: Test on Bazzite with full report
5. Can ship MVP with just US1!

### Incremental Delivery

1. **MVP**: Setup + Foundational + US1 = Working diagnostic tool with full report
2. **v1.1**: Add US2 = Quick health check mode
3. **v1.2**: Add US3 = Privacy redaction for sharing
4. **v1.3**: Add Polish = Documentation and error handling refinement

### Single Developer Strategy (Recommended)

Execute phases sequentially in order:
- Phase 1 → Phase 2 → Phase 3 (MVP!) → Phase 4 → Phase 5 → Phase 6

---

## Notes

- All user story tasks modify `scripts/foundryvtt-diagnose.sh` - sequential execution recommended
- [P] tasks indicate different files or features - safe to parallelize
- ShellCheck validation required at end of each phase
- Commit after each completed phase (not individual tasks)
- Test on actual Bazzite system before shipping
- Constitution requires: `set -euo pipefail`, ShellCheck compliance, clear error messages
