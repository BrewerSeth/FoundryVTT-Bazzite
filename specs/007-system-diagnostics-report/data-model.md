# Data Model: System Diagnostics & Status Report

**Feature**: 007-system-diagnostics-report  
**Date**: 2026-02-15

## Overview

This feature generates diagnostic reports by reading existing system state and configuration. No new persistent storage is created; the script reads from Feature 001's configuration and live system state.

---

## Entities

### 1. Diagnostic Report

**Type**: Generated output (not persisted)

The complete diagnostic report containing all system status information.

| Field | Type | Description |
|-------|------|-------------|
| `generated_at` | ISO 8601 timestamp | When the report was generated |
| `version` | string | Version of the diagnostic script |
| `overall_status` | enum | `HEALTHY`, `DEGRADED`, or `CRITICAL` |
| `sections` | array | List of report sections |

### 2. Report Section

**Type**: Component of Diagnostic Report

Individual sections of the diagnostic report.

| Section | Contents | Status Indicator |
|---------|----------|------------------|
| `host_system` | OS, uptime, resources | Component status |
| `host_updates` | Available Bazzite updates | Update availability |
| `containers` | Distrobox container list | Per-container status |
| `container_updates` | Available Ubuntu packages | Per-container update count |
| `instances` | FoundryVTT instances | Per-instance status |
| `network` | Ports, connectivity | Component status |
| `logs` | Recent log excerpts | Error count |

### 3. Component Status

**Type**: Enumeration

Health state of any system component.

| Status | Color | Meaning |
|--------|-------|---------|
| `HEALTHY` | 🟢 Green | Operating normally |
| `WARNING` | 🟡 Yellow | Approaching limits or minor issues |
| `CRITICAL` | 🔴 Red | Errors, failures, or exceeded thresholds |
| `UNKNOWN` | ⚪ White | Cannot determine status |
| `NOT_INSTALLED` | ⚫ N/A | Component not present (e.g., no FoundryVTT) |

### 4. Resource Metrics

**Type**: Data structure

Current system resource usage.

| Metric | Unit | Warning Threshold | Critical Threshold |
|--------|------|-------------------|-------------------|
| `cpu_percent` | % | >80% | >95% |
| `memory_percent` | % | >85% | >95% |
| `disk_percent` | % | >90% | >95% |
| `load_average` | float | >2.0 | >5.0 |

### 5. Update Status

**Type**: Data structure

Status of available system updates for host and guest.

| Field | Type | Description |
|-------|------|-------------|
| `host_updates_available` | boolean | Whether Bazzite host has pending updates |
| `host_update_info` | string | Description of available updates or error message |
| `host_check_status` | enum | `available`, `none`, `unknown`, `timeout` |
| `guest_updates_count` | integer | Number of upgradable packages in container |
| `guest_security_count` | integer | Number of security updates available |
| `guest_check_status` | enum | `available`, `none`, `unknown`, `timeout` |

**Update Check Timeout**: 10 seconds maximum for each check to keep report generation fast.

### 7. Container Status

**Type**: Data structure

Status of a Distrobox container.

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Container name (e.g., "foundryvtt") |
| `image` | string | Base image (e.g., "ubuntu:24.04") |
| `state` | enum | `running`, `exited`, `created`, `missing` |
| `uptime` | duration | How long container has been running |
| `cpu_percent` | float | Current CPU usage |
| `memory_usage` | string | Memory usage (e.g., "245MB / 1GB") |

### 8. Instance Status

**Type**: Data structure

Status of a FoundryVTT instance.

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Instance name (matches container) |
| `version` | string | FoundryVTT version (e.g., "13.351") |
| `node_version` | string | Node.js version (e.g., "22.x") |
| `service_state` | enum | `active`, `inactive`, `failed`, `unknown` |
| `service_enabled` | boolean | Whether service starts on boot |
| `port` | integer | Port number (default 30000) |
| `port_listening` | boolean | Whether port is open |
| `http_status` | integer | HTTP response code (200=OK) |
| `error_count` | integer | Number of recent errors in logs |

### 9. Log Entry

**Type**: Data structure

A single log line from FoundryVTT.

| Field | Type | Description |
|-------|------|-------------|
| `timestamp` | ISO 8601 | When the log was written |
| `level` | enum | `ERROR`, `WARN`, `INFO`, `DEBUG` |
| `message` | string | Log message content |
| `source` | string | Which component generated it |

---

## Configuration Reading

The diagnostic script reads from Feature 001's configuration:

**Source**: `~/.config/foundryvtt-bazzite/config`

Fields used:
- `FOUNDRY_VERSION` - Expected version
- `NODE_VERSION` - Expected Node.js version
- `DATA_PATH` - Where to check disk usage
- `INSTALL_PATH` - Where FoundryVTT is installed
- `CONTAINER_NAME` - Which container to check
- `PORT` - Which port to check
- `AUTO_START` - Whether service should be enabled

---

## Report Output Formats

### Format 1: Text (Human-Readable)

Default output format for terminal viewing.

Features:
- Section headers with `===` delimiters
- Color-coded status indicators
- Aligned columns for easy reading
- Copy/paste friendly

### Format 2: JSON (Machine-Readable)

Optional output for programmatic processing.

```json
{
  "generated_at": "2026-02-15T14:30:00Z",
  "version": "1.0.0",
  "overall_status": "HEALTHY",
  "sections": {
    "host_system": {
      "status": "HEALTHY",
      "os": "Bazzite 40",
      "uptime": "3 days, 2 hours",
      "cpu_percent": 12,
      "memory_percent": 45,
      "disk_percent": 67
    },
    "host_updates": {
      "status": "HEALTHY",
      "updates_available": false,
      "check_status": "none",
      "info": "System up to date"
    },
    "containers": [
      {
        "name": "foundryvtt",
        "status": "HEALTHY",
        "image": "ubuntu:24.04",
        "state": "running",
        "uptime": "2 days"
      }
    ],
    "container_updates": {
      "foundryvtt": {
        "updates_count": 3,
        "security_count": 1,
        "check_status": "available",
        "status": "WARNING"
      }
    },
    "instances": [
      {
        "name": "foundryvtt",
        "status": "HEALTHY",
        "version": "13.351",
        "service_state": "active",
        "port_listening": true,
        "http_status": 200
      }
    ]
  }
}
```

### Format 3: Redacted (Privacy-Safe)

Text or JSON format with sensitive data masked.

Replacements:
- IPs → `[REDACTED_IP]`
- Paths → `[REDACTED_PATH]`
- Usernames → `[REDACTED_USER]`
- Hostnames → `[REDACTED_HOST]`

---

## State Transitions

The diagnostic script doesn't modify state, but reports on it:

```
[Unknown] --query--> [Healthy|Warning|Critical|Not Installed]
```

For each component:
1. Check if component exists
2. If exists, query current state
3. Compare against thresholds
4. Assign status based on results
5. Aggregate into overall status

**Overall Status Logic**:
- `CRITICAL`: Any component is CRITICAL
- `DEGRADED`: Any component is WARNING (none CRITICAL)
- `HEALTHY`: All components are HEALTHY
- `NOT_INSTALLED`: FoundryVTT not configured

---

## Privacy Redaction Patterns

Patterns used to identify sensitive data:

| Pattern Type | Regex Pattern | Replacement |
|--------------|---------------|-------------|
| IPv4 Address | `[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}` | `[REDACTED_IP]` |
| IPv6 Address | `[0-9a-fA-F:]+:[0-9a-fA-F:]+` | `[REDACTED_IP]` |
| Home Path | `$HOME` or `/home/$USER` | `[REDACTED_PATH]` |
| Username | `$USER` | `[REDACTED_USER]` |
| Hostname | output of `hostname` | `[REDACTED_HOST]` |

---

## Validation Rules

### Resource Threshold Validation

```
IF cpu_percent > 95 THEN status = CRITICAL
ELSE IF cpu_percent > 80 THEN status = WARNING
ELSE status = HEALTHY

IF memory_percent > 95 THEN status = CRITICAL
ELSE IF memory_percent > 85 THEN status = WARNING
ELSE status = HEALTHY

IF disk_percent > 95 THEN status = CRITICAL
ELSE IF disk_percent > 90 THEN status = WARNING
ELSE status = HEALTHY
```

### Service State Validation

```
IF service_state == "failed" THEN status = CRITICAL
ELSE IF service_state == "inactive" AND auto_start == true THEN status = WARNING
ELSE IF service_state == "active" THEN status = HEALTHY
ELSE status = UNKNOWN
```

### Container State Validation

```
IF state == "missing" THEN status = CRITICAL (or NOT_INSTALLED)
ELSE IF state == "exited" THEN status = WARNING
ELSE IF state == "running" THEN status = HEALTHY
ELSE status = UNKNOWN
```

---

## Relationships

```
Diagnostic Report
├── Host System Section
│   └── Resource Metrics (CPU, Memory, Disk)
├── Containers Section
│   └── Container Status[]
├── Instances Section
│   └── Instance Status[]
│       └── Log Entry[]
└── Network Section
    └── Connectivity Status
```

**Data Flow**:
1. Script reads config from Feature 001
2. Script queries live system state
3. Script compares state against thresholds
4. Script generates report with status indicators
5. Script outputs in selected format (text/JSON/redacted)
