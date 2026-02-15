# Data Model: FoundryVTT Distrobox Setup Script

**Feature**: 001-distrobox-setup-script  
**Date**: 2026-02-15

## Overview

This feature uses file-based configuration stored in the user's home directory. No database or external storage is required.

---

## Entities

### 1. Setup Configuration

**Location**: `~/.config/foundryvtt-bazzite/config`

Stores user preferences from setup for idempotent re-runs and future scripts.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `FOUNDRY_VERSION` | string | Yes | - | FoundryVTT version (e.g., "13.351") |
| `NODE_VERSION` | string | Yes | - | Node.js major version used (e.g., "22") |
| `DATA_PATH` | path | Yes | `~/FoundryVTT-Data` | User data directory (worlds, modules, etc.) |
| `INSTALL_PATH` | path | Yes | `~/.foundryvtt` | FoundryVTT application location (hidden) |
| `CONTAINER_NAME` | string | Yes | `foundryvtt` | Distrobox container name |
| `PORT` | integer | Yes | `30000` | FoundryVTT server port |
| `AUTO_START` | boolean | Yes | `false` | Whether auto-start is enabled |
| `SETUP_DATE` | timestamp | Yes | - | When setup was completed |
| `SETUP_VERSION` | string | Yes | - | Version of this setup script |

**Format**: Shell-sourceable key=value pairs

```bash
# ~/.config/foundryvtt-bazzite/config
# FoundryVTT-Bazzite Setup Configuration
# Generated: 2026-02-15T10:30:00Z

FOUNDRY_VERSION="13.351"
NODE_VERSION="22"
DATA_PATH="/home/user/FoundryVTT-Data"
INSTALL_PATH="/home/user/.foundryvtt"
CONTAINER_NAME="foundryvtt"
PORT="30000"
AUTO_START="true"
SETUP_DATE="2026-02-15T10:30:00Z"
SETUP_VERSION="1.0.0"
```

### 2. Distrobox Container

**Name**: `foundryvtt` (configurable)  
**Base Image**: `ubuntu:24.04`

| Property | Value | Notes |
|----------|-------|-------|
| Image | `ubuntu:24.04` | Ubuntu LTS (Noble) - support until 2029 |
| Home mount | Automatic | Distrobox shares host home directory |
| Packages | `nodejs`, `curl`, `unzip` | Installed via apt after NodeSource setup |

**State Transitions**:

```
[Not Exists] --create--> [Created] --enter--> [Running]
                              |
                              v
                         [Configured] (Node.js + FoundryVTT installed)
```

### 3. Systemd User Service

**Location**: `~/.config/systemd/user/foundryvtt.service`

Created only when `AUTO_START=true`.

| Field | Value | Notes |
|-------|-------|-------|
| Type | `simple` | Single foreground process |
| ExecStart | `distrobox enter ... node main.js` | Runs FoundryVTT via Distrobox |
| Restart | `on-failure` | Auto-restart on crash |
| WantedBy | `default.target` | Starts at user login |

### 4. FoundryVTT Data Directory

**Location**: User-specified (default `~/FoundryVTT-Data`)

Standard FoundryVTT data structure. This is user data that should be backed up.

```
~/FoundryVTT-Data/
├── Config/
│   └── options.json      # FoundryVTT server configuration
├── Data/
│   ├── worlds/           # Game worlds
│   ├── modules/          # Installed modules
│   └── systems/          # Game systems
└── Logs/
    └── *.log             # Application logs
```

### 5. FoundryVTT Installation

**Location**: `~/.foundryvtt/` (hidden directory, inside container but on host filesystem via mount)

This is the application code that can be re-downloaded with a new Timed URL.

```
~/.foundryvtt/
├── main.js           # Entry point (V13+)
├── main.mjs          # ES module entry point
├── package.json      # Node.js manifest
├── package-lock.json
├── license.html
├── client/           # Client-side code
├── common/           # Shared code
├── dist/             # Distribution files
├── node_modules/     # Dependencies
├── public/           # Static assets
└── templates/        # HTML templates
```

**Note**: The hidden directory `~/.foundryvtt` keeps the application files out of the user's visible home directory, following Linux convention for application data.

---

## Validation Rules

### Timed URL Validation

```regex
^https://r2\.foundryvtt\.com/releases/[0-9]+\.[0-9]+/FoundryVTT-[a-z]+-[0-9]+\.[0-9]+\.zip\?verify=[a-zA-Z0-9%]+$
```

**Components**:
- Domain: `r2.foundryvtt.com`
- Path: `/releases/{version}/FoundryVTT-{build}-{version}.zip`
- Query: `verify={token}`

### Path Validation

- Must be absolute path (starts with `/` or `~`)
- Must be within user's home directory or mounted volume
- Must be writable by current user
- Cannot contain spaces (limitation of some Distrobox operations)

### Port Validation

- Must be integer 1024-65535 (non-privileged ports)
- Default: 30000 (FoundryVTT standard)
- Must not be in use by another service

---

## State Management

### Idempotency Checks

The script uses the config file to detect existing setups:

1. **Fresh install**: No config file exists → full setup
2. **Re-run**: Config file exists → offer to reconfigure or skip
3. **Upgrade**: Config file exists with older `SETUP_VERSION` → migration path

### Container State Detection

```bash
# Check if container exists
distrobox list | grep -q "^foundryvtt "

# Check if container is running
podman ps --filter name=foundryvtt --format "{{.Status}}"
```

### Service State Detection

```bash
# Check if service is enabled
systemctl --user is-enabled foundryvtt.service

# Check if service is running
systemctl --user is-active foundryvtt.service
```

---

## Relationships

```
┌─────────────────────────────────────────────────────────────┐
│                     Host (Bazzite)                          │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ ~/.config/foundryvtt-bazzite/config                  │   │
│  │ (Setup preferences - read by future scripts)         │   │
│  └──────────────────────────────────────────────────────┘   │
│                              │                               │
│                              │ references                    │
│                              ▼                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Distrobox Container: foundryvtt                      │   │
│  │ Image: ubuntu:24.04                                  │   │
│  │ ┌──────────────────────────────────────────────────┐ │   │
│  │ │ Node.js 22.x (via NodeSource)                    │ │   │
│  │ │ FoundryVTT application (~/.foundryvtt/)          │ │   │
│  │ └──────────────────────────────────────────────────┘ │   │
│  └──────────────────────────────────────────────────────┘   │
│                              │                               │
│                              │ mounts                        │
│                              ▼                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ ~/FoundryVTT-Data/ (User Data)                       │   │
│  │ - Worlds, modules, systems, logs                     │   │
│  │ - Persists across container rebuilds                 │   │
│  │ - BACK THIS UP!                                      │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ ~/.config/systemd/user/foundryvtt.service            │   │
│  │ (Optional: auto-start on boot)                       │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## Migration Considerations

### Future Multi-Instance Support (Feature 005)

The current config structure supports a single instance. Future multi-instance support will require:

- Config directory per instance: `~/.config/foundryvtt-bazzite/instances/{name}/config`
- Container naming: `foundryvtt-{name}`
- Port allocation: Sequential from 30000 or user-specified
- Service naming: `foundryvtt@{name}.service` (template unit)

The current design does not preclude this evolution.
