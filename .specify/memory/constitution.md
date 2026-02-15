<!--
SYNC IMPACT REPORT
==================
Version change: 1.2.0 → 1.3.0
Modified principles: None
Added sections:
  - Values: Transparency (AI-assisted development, open process)
  - Values: Open Source First (tool selection, licensing, community)
Removed sections: None
Templates requiring updates:
  - .specify/templates/plan-template.md ✅ (no changes needed - generic)
  - .specify/templates/spec-template.md ✅ (no changes needed - generic)
  - .specify/templates/tasks-template.md ✅ (no changes needed - generic)
Follow-up TODOs: None
-->

# FoundryVTT-Bazzite Constitution

## Mission

Make FoundryVTT approachable and fun for new users on Bazzite-powered computers.

We want gamers—especially those on Steam Deck and similar handheld hardware—to
easily set up and enjoy FoundryVTT without needing Linux expertise. The experience
should feel as natural as installing any other game: straightforward, well-guided,
and rewarding.

**Target Audience**:
- Gamers new to self-hosting
- Steam Deck and handheld PC users
- Bazzite users who want a "just works" FoundryVTT setup
- Tabletop RPG enthusiasts who aren't necessarily technical

**Success looks like**: A user with no Linux experience can follow our documentation,
run our scripts, and have a working FoundryVTT server in minutes—with a smile on
their face.

## Values

### Transparency

This project is built in the open. We are honest about our tools, methods, and
limitations.

- **AI-Assisted Development**: We use AI agents (such as Claude, GPT, and other LLMs)
  to help write scripts, documentation, and solve problems. We do not hide this—AI
  is a tool like any other, and we believe in being upfront about how we work.
- **Open Process**: Planning documents, specifications, and decision rationale are
  maintained in the repository. Anyone can see what we're working on and why.
- **Honest Limitations**: If something doesn't work well or has known issues, we
  document it rather than hide it.

### Open Source First

We prefer open source tools and contribute back to the community when possible.

- **Tool Selection**: When choosing dependencies or tools, open source options MUST
  be preferred over proprietary alternatives unless there is a compelling technical
  reason documented in the decision.
- **Licensing**: All project code is open source. We respect the licenses of tools
  we depend on.
- **Community**: We welcome contributions and aim to make the codebase accessible
  to new contributors.

## Core Principles

### I. Documentation-First

All features, scripts, and configurations MUST have accompanying documentation before
being considered complete. Documentation requirements:

- **User guides**: Step-by-step instructions a beginner can follow without prior knowledge
- **Script headers**: Every script MUST include a comment block explaining purpose, usage,
  and any prerequisites
- **README updates**: Any new functionality MUST be reflected in the project README
- **Troubleshooting**: Common issues and their solutions MUST be documented

**Rationale**: Our audience is gamers, not sysadmins. Documentation should feel
like a friendly guide, not a technical manual. If a user gets stuck or confused,
we've failed.

### II. Reproducibility

Every deployment MUST produce identical results given the same inputs. Requirements:

- **Pinned versions**: All dependencies (Node.js, FoundryVTT, Distrobox images) MUST
  specify exact versions or version ranges with documented upgrade procedures
- **Idempotent scripts**: Running a script multiple times MUST produce the same result
  as running it once (no duplicate entries, no errors on re-run)
- **Environment isolation**: Use Distrobox containers to isolate FoundryVTT from the
  host system, ensuring consistent behavior across Bazzite installations
- **Documented state**: Any manual configuration steps MUST be scripted or explicitly
  documented as required manual steps

**Rationale**: Users must be able to rebuild their setup from scratch and get the
same working environment. This also enables easy migration and disaster recovery.

### III. Simplicity

Prefer simple, understandable solutions over clever or complex ones. Guidelines:

- **Single-purpose scripts**: Each script SHOULD do one thing well
- **Minimal dependencies**: Avoid adding dependencies unless they provide clear value
- **Readable code**: Scripts MUST be readable by someone with basic Bash knowledge;
  complex logic MUST include explanatory comments
- **No premature optimization**: Solve the immediate problem; optimize only when
  performance issues are demonstrated
- **YAGNI**: Do not implement features "just in case" - wait for actual need

**Rationale**: Maintainability depends on simplicity. Complex solutions become
unmaintainable and discourage community contributions.

### IV. Immutable Infrastructure

Treat containers and configurations as immutable artifacts. Requirements:

- **No manual container modifications**: All changes MUST be made through scripts or
  configuration files, never by manually entering a container and making changes
- **Declarative configuration**: Use Quadlet files and systemd units for service
  definitions; avoid imperative setup scripts where declarative alternatives exist
- **Rebuild over repair**: When issues arise, prefer recreating the container from
  scratch over attempting in-place fixes
- **Version-controlled state**: All configuration files MUST be tracked in version
  control; data directories are excluded but their structure MUST be documented

**Rationale**: Immutable infrastructure eliminates configuration drift, makes
deployments predictable, and simplifies troubleshooting.

### V. Script Quality

All automation scripts MUST meet quality standards before merge. Requirements:

- **ShellCheck compliance**: All Bash scripts MUST pass ShellCheck with no errors
  and no unaddressed warnings
- **Error handling**: Scripts MUST use `set -euo pipefail` (or equivalent) and
  handle expected failure modes gracefully with helpful error messages
- **Logging**: Scripts MUST provide clear output indicating progress and any issues
- **Tested paths**: Critical user paths MUST be manually tested before release;
  automated tests are encouraged but not required for this project scope

**Rationale**: Users trust these scripts with their systems. Poor quality scripts
can cause data loss or system instability.

## Technology Constraints

**Runtime Environment**:
- Host OS: Bazzite (Fedora-based immutable desktop)
- Container: Distrobox (Podman-backed)
- Service Management: Quadlet/Systemd
- Application: FoundryVTT (Node.js-based)

**Script Requirements**:
- Language: Bash (POSIX-compatible where practical)
- Compatibility: Must work with Bazzite's default shell environment
- No root requirement: Scripts SHOULD NOT require root/sudo unless absolutely
  necessary (Distrobox handles most privilege escalation)

**Documentation Format**:
- Markdown for all documentation
- GitHub-Flavored Markdown (GFM) for compatibility

## Reference Materials

**FoundryVTT Knowledge Base**:
- Main KB: https://foundryvtt.com/kb/

**FoundryVTT Search Endpoints**:
- Package Search: `https://foundryvtt.com/search/?type=package&q={SearchString}`
- Release Notes Search: `https://foundryvtt.com/search/?type=release&q={SearchString}`
- Knowledge Base Search: `https://foundryvtt.com/search/?type=article&q={SearchString}`

**Bazzite Documentation**:
- Main Docs: https://docs.bazzite.gg/

**Usage**: When implementing features or troubleshooting, consult the official
documentation first. Use FoundryVTT KB for application-specific questions and
Bazzite docs for OS/container/system-level questions.

## Development Workflow

**Before Implementation**:
1. Document what the script/feature will do (Documentation-First)
2. Verify the approach is the simplest viable solution (Simplicity)
3. Ensure the solution is reproducible and doesn't require manual steps (Reproducibility)

**During Implementation**:
1. Write scripts with proper error handling and logging (Script Quality)
2. Keep containers immutable - no manual modifications (Immutable Infrastructure)
3. Run ShellCheck on all Bash scripts before committing

**Before Merge**:
1. All documentation is complete and accurate
2. ShellCheck passes with no errors
3. Manual testing of the user-facing workflow completed
4. README updated if user-visible changes

## Governance

This constitution establishes the non-negotiable standards for the FoundryVTT-Bazzite
project. All contributions MUST comply with these principles.

**Amendment Process**:
1. Propose changes via pull request modifying this constitution
2. Document rationale for the change
3. Version bump follows semantic versioning:
   - MAJOR: Principle removed or fundamentally redefined
   - MINOR: New principle added or significant expansion
   - PATCH: Clarifications, typo fixes, minor refinements
4. Update dependent templates if principles change

**Compliance**:
- All pull requests MUST be checked against these principles
- Violations MUST be resolved before merge or explicitly justified with documented
  rationale in the Complexity Tracking section of the relevant plan

**Version**: 1.3.0 | **Ratified**: 2026-02-15 | **Last Amended**: 2026-02-15
