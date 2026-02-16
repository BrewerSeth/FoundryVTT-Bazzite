# CLI Contract: foundryvtt-diagnose.sh

**Feature**: 007-system-diagnostics-report  
**Type**: Command-line Interface Specification  
**Version**: 1.0.0

---

## Command Syntax

```bash
foundryvtt-diagnose.sh [OPTIONS]
```

---

## Options

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--quick` | `-q` | Quick health check (fast summary only) | Disabled |
| `--json` | `-j` | Output in JSON format | Disabled (text) |
| `--redact` | `-r` | Redact sensitive information | Disabled |
| `--output FILE` | `-o FILE` | Save output to file | stdout |
| `--help` | `-h` | Show help message | - |
| `--version` | `-v` | Show version | - |

---

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success - System is HEALTHY |
| `1` | General error |
| `2` | System is DEGRADED (warnings present) |
| `3` | System is CRITICAL (errors present) |
| `4` | FoundryVTT not installed |
| `5` | Not running on Bazzite |

---

## Output Formats

### Text Format (Default)

Human-readable format with color coding (when TTY detected).

**Structure**:
```
HEADER (title, timestamp, version)
SECTION (labeled with ===)
  - Field: Value [STATUS]
  - Subsections indented
FOOTER (overall status)
```

**Example**:
```
============================================================
FOUNDRYVTT SYSTEM DIAGNOSTICS REPORT
============================================================
Generated: 2026-02-15T14:30:00Z
Version: 1.0.0

============================================================
HOST SYSTEM
============================================================
OS: Bazzite 40 (Fedora-based) [OK]
Uptime: 3 days, 2 hours
CPU Usage: 12% [OK]
Memory Usage: 45% [OK]
Disk Usage: 67% [OK]

============================================================
OVERALL STATUS: HEALTHY
============================================================
```

### JSON Format (--json)

Machine-parseable JSON with consistent schema.

**Schema**:
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["generated_at", "version", "overall_status", "sections"],
  "properties": {
    "generated_at": {
      "type": "string",
      "format": "date-time",
      "description": "ISO 8601 timestamp"
    },
    "version": {
      "type": "string",
      "description": "Script version"
    },
    "overall_status": {
      "type": "string",
      "enum": ["HEALTHY", "DEGRADED", "CRITICAL", "NOT_INSTALLED"]
    },
    "sections": {
      "type": "object",
      "properties": {
        "host_system": {
          "type": "object",
          "properties": {
            "status": {"type": "string"},
            "os": {"type": "string"},
            "uptime": {"type": "string"},
            "cpu_percent": {"type": "number"},
            "memory_percent": {"type": "number"},
            "disk_percent": {"type": "number"}
          }
        },
        "containers": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "name": {"type": "string"},
              "status": {"type": "string"},
              "image": {"type": "string"},
              "state": {"type": "string"},
              "uptime": {"type": "string"}
            }
          }
        },
        "instances": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "name": {"type": "string"},
              "status": {"type": "string"},
              "version": {"type": "string"},
              "service_state": {"type": "string"},
              "port_listening": {"type": "boolean"},
              "http_status": {"type": "integer"}
            }
          }
        },
        "network": {
          "type": "object",
          "properties": {
            "status": {"type": "string"},
            "port_30000_listening": {"type": "boolean"},
            "local_accessible": {"type": "boolean"}
          }
        },
        "logs": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "timestamp": {"type": "string"},
              "level": {"type": "string"},
              "message": {"type": "string"}
            }
          }
        }
      }
    }
  }
}
```

---

## Redaction Patterns

When `--redact` is specified, the following patterns are replaced:

| Pattern | Matches | Replacement |
|---------|---------|-------------|
| IPv4 | `xxx.xxx.xxx.xxx` | `[REDACTED_IP]` |
| IPv6 | IPv6 addresses | `[REDACTED_IP]` |
| Home path | `/home/username` | `[REDACTED_PATH]` |
| Username | Current username | `[REDACTED_USER]` |
| Hostname | System hostname | `[REDACTED_HOST]` |

**Example**:
```
# Before redaction
IP Address: 192.168.1.100
Data Path: /home/gamemaster/FoundryVTT-Data
User: gamemaster
Host: copernicus

# After redaction
IP Address: [REDACTED_IP]
Data Path: [REDACTED_PATH]
User: [REDACTED_USER]
Host: [REDACTED_HOST]
```

---

## Quick Mode (--quick)

When `--quick` is specified, only high-level status is reported:

**Output**:
```
╔══════════════════════════════════════════════════════════╗
║     FOUNDRYVTT SYSTEM DIAGNOSTICS - QUICK CHECK         ║
╚══════════════════════════════════════════════════════════╝

Host System:    🟢 HEALTHY
Containers:     🟢 HEALTHY (1 running)
Instances:      🟢 HEALTHY (1 active)
Network:        🟢 HEALTHY

Overall Status: 🟢 HEALTHY

Run without --quick for detailed report.
```

**Execution Time**: <5 seconds

---

## Error Handling

### Permission Denied

If the script cannot access system information:

```
[WARN] Cannot read process information (permission denied)
[WARN] Some diagnostic data may be unavailable
```

The script continues with available information.

### Missing Dependencies

If required tools are missing:

```
[ERROR] Required tool not found: jq
[INFO] Install with: sudo apt install jq
```

### Not Bazzite

If not running on Bazzite:

```
[ERROR] This script requires Bazzite Linux.
Detected OS: fedora
Get Bazzite at: https://bazzite.gg
```

Exit code: 5

---

## Examples

### Basic Usage

```bash
# Quick check
./foundryvtt-diagnose.sh --quick

# Full report to stdout
./foundryvtt-diagnose.sh

# Full report to file
./foundryvtt-diagnose.sh --output report.txt

# JSON for automation
./foundryvtt-diagnose.sh --json --output report.json

# Privacy-safe for sharing
./foundryvtt-diagnose.sh --redact --output report.txt

# Combined: JSON, redacted, saved
./foundryvtt-diagnose.sh -j -r -o report.json
```

### CI/CD Integration

```bash
# Check if system is healthy (fails if not)
./foundryvtt-diagnose.sh --quick
if [ $? -ne 0 ]; then
    echo "System not healthy!"
    exit 1
fi

# Get structured data for monitoring
./foundryvtt-diagnose.sh --json | jq '.overall_status'
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-02-15 | Initial release |
