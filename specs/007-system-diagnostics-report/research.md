# Research: System Diagnostics & Status Report

**Feature**: 007-system-diagnostics-report  
**Date**: 2026-02-15  
**Status**: Complete

## Research Questions

1. How do we efficiently collect host system diagnostics on Bazzite?
2. How do we query Distrobox container status programmatically?
3. How do we check FoundryVTT instance status and logs?
4. What format is best for both human readability and AI parsing?
5. How do we implement privacy redaction effectively?

---

## 1. Host System Diagnostics

### Decision: Use standard Linux utilities with fallbacks

### Rationale

Bazzite (Fedora-based) provides standard Linux diagnostic tools. We need commands that:
- Work without elevated privileges
- Are available on all Bazzite systems
- Execute quickly (<5 seconds for quick check)

### Tools Selected

| Information | Command | Fallback |
|-------------|---------|----------|
| OS Version | `grep ^PRETTY_NAME /etc/os-release` | `uname -a` |
| Uptime | `uptime -p` | `cat /proc/uptime` |
| CPU Usage | `top -bn1 | grep "Cpu(s)"` | `/proc/stat` parsing |
| Memory | `free -h` | `/proc/meminfo` |
| Disk Usage | `df -h` (filter relevant mounts) | `df` without -h |
| Load Average | `cat /proc/loadavg` | `uptime` |

### Implementation

```bash
# Quick resource check (for summary mode)
get_quick_resources() {
    local cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    local mem=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')
    local disk=$(df -h /home | tail -1 | awk '{print $5}' | tr -d '%')
    echo "CPU:${cpu}% MEM:${mem}% DISK:${disk}%"
}
```

### Thresholds

Per spec assumptions:
- **Warning**: CPU >80%, Memory >85%, Disk >90%
- **Critical**: CPU >95%, Memory >95%, Disk >95%

---

## 2. Distrobox Container Status

### Decision: Use `distrobox list` and `podman inspect`

### Rationale

Distrobox provides a `list` command that shows container status. For detailed info, we can use `podman` directly (Distrobox uses Podman on Bazzite).

### Commands

```bash
# List all containers with status
distrobox list --no-color

# Get specific container status
podman inspect foundryvtt --format '{{.State.Status}}'

# Get container resource usage
podman stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Check if container exists
podman inspect foundryvtt &>/dev/null && echo "exists" || echo "missing"
```

### Container Health States

- **running**: Container is active
- **exited**: Container stopped (may be intentional)
- **created**: Container exists but never started
- **missing**: Container doesn't exist (broken installation)

---

## 3. FoundryVTT Instance Status

### Decision: Check systemd service status and read logs

### Rationale

Feature 001 creates systemd user services. We can query service status and recent logs to determine instance health.

### Commands

```bash
# Check if service is active
systemctl --user is-active foundryvtt.service

# Check if service is enabled
systemctl --user is-enabled foundryvtt.service

# Get service status details
systemctl --user status foundryvtt.service --no-pager

# Read recent logs (last 50 lines)
journalctl --user -u foundryvtt.service -n 50 --no-pager

# Check if FoundryVTT is listening on port
ss -tlnp | grep :30000
```

### Log Analysis

- Filter for ERROR and WARN levels
- Look for common issues:
  - "EACCES" - Permission denied
  - "EADDRINUSE" - Port already in use
  - "ENOENT" - Missing files
  - Connection timeouts

---

## 4. Network Status

### Decision: Use `ss` for ports, simple connectivity checks

### Rationale

Lightweight network diagnostics without external dependencies.

### Commands

```bash
# Check if FoundryVTT port is listening
ss -tlnp | grep :30000

# Check local connectivity
curl -s -o /dev/null -w "%{http_code}" http://localhost:30000

# Get IP addresses (for redaction)
ip addr show | grep "inet " | awk '{print $2}'
```

### Privacy Note

IP addresses should be redacted in shared reports: `[REDACTED_IP]`

---

## 5. Report Format

### Decision: Structured text with clear section headers and status indicators

### Rationale

Must be:
- Human-readable (clear headers, colors if terminal)
- AI-parseable (consistent structure, labeled sections)
- Easy to copy/paste (text format)
- Machine-processable (optional JSON output)

### Format Structure

```text
============================================================
FOUNDRYVTT SYSTEM DIAGNOSTICS REPORT
============================================================
Generated: 2026-02-15T14:30:00Z
Version: 1.0.0
Status: [HEALTHY|DEGRADED|CRITICAL]

============================================================
HOST SYSTEM
============================================================
OS: Bazzite (Fedora-based)
Uptime: 3 days, 2 hours
CPU Usage: 12% [OK]
Memory Usage: 45% [OK]
Disk Usage: 67% [OK]

============================================================
DISTROBOX CONTAINERS
============================================================
foundryvtt: RUNNING [OK]
  Image: ubuntu:24.04
  Status: Up 2 days

============================================================
FOUNDRYVTT INSTANCES
============================================================
Instance: foundryvtt
  Status: RUNNING [OK]
  Version: 13.351
  Port: 30000 [LISTENING]
  Service: enabled, active

============================================================
NETWORK
============================================================
Local Access: OK (HTTP 200)
Port 30000: LISTENING
Public IP: [REDACTED]

============================================================
RECENT LOGS
============================================================
[Last 10 lines from journalctl]
...
```

### Color Coding (Terminal Output)

- 🟢 [OK] - Healthy
- 🟡 [WARN] - Warning (approaching limits)
- 🔴 [CRIT] - Critical (over thresholds or errors)
- ⚪ [INFO] - Informational

### AI-Parseable Elements

- Clear section headers with `===` delimiters
- Labeled fields with colons: `Field: Value`
- Status indicators in brackets: `[OK]`, `[WARN]`, `[CRIT]`
- Consistent formatting across runs

---

## 6. Privacy Redaction

### Decision: Pattern-based replacement with placeholder tokens

### Rationale

Users need to share diagnostics safely. Redaction should:
- Remove sensitive data (IPs, paths, usernames)
- Preserve diagnostic value
- Be reversible (if user has original)

### Patterns to Redact

| Pattern | Example | Replacement |
|---------|---------|-------------|
| IP Addresses | 192.168.1.100 | [REDACTED_IP] |
| Full Paths | /home/username/FoundryVTT | [REDACTED_PATH] |
| Usernames | gamemaster | [REDACTED_USER] |
| Hostnames | copernicus | [REDACTED_HOST] |
| License Keys | ABC-123-DEF | [REDACTED_KEY] |

### Implementation

```bash
redact_sensitive_info() {
    local input="$1"
    # IP addresses (IPv4 and IPv6)
    input=$(echo "$input" | sed -E 's/[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[REDACTED_IP]/g')
    # Home directory paths
    input=$(echo "$input" | sed -E "s|$HOME|[REDACTED_PATH]|g")
    # Username
    input=$(echo "$input" | sed -E "s|$USER|[REDACTED_USER]|g")
    echo "$input"
}
```

---

## Summary of Decisions

| Question | Decision | Key Reason |
|----------|----------|------------|
| Host diagnostics | Standard Linux utils (ps, free, df, etc.) | Universal, no dependencies, fast |
| Container status | `distrobox list` + `podman inspect` | Native tools, detailed info |
| Instance status | `systemctl --user` + `journalctl` | Standard service management |
| Network status | `ss` + `curl` | Lightweight, no external deps |
| Report format | Structured text with sections | Human + AI readable |
| Privacy | Pattern-based redaction | Safe sharing, preserves value |

---

## References

- Bazzite Documentation: https://docs.bazzite.gg/
- Distrobox Documentation: https://github.com/89luca89/distrobox
- systemd Documentation: https://systemd.io/
- FoundryVTT Troubleshooting: https://foundryvtt.com/kb/
