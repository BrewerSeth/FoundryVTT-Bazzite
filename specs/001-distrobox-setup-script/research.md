# Research: FoundryVTT Distrobox Setup Script

**Feature**: 001-distrobox-setup-script  
**Date**: 2026-02-15  
**Status**: Complete

## Research Questions

1. Which Ubuntu LTS version should we use for the container?
2. How do we reliably detect if the system is Bazzite?
3. How do we determine the required Node.js version for FoundryVTT?
4. How do we configure auto-start using Quadlet/systemd?

---

## 1. Ubuntu LTS Version

### Decision: Ubuntu 24.04 LTS (Noble)

### Rationale

Both Ubuntu 22.04 and 24.04 work equally well with NodeSource (required for Node.js installation), but 22.04 is preferred:

| Factor | Ubuntu 22.04 (Jammy) | Ubuntu 24.04 (Noble) |
|--------|---------------------|---------------------|
| **NodeSource Support** | Full (Node 18, 20, 22) | Full (Node 18, 20, 22) |
| **glibc version** | 2.35 (meets FoundryVTT requirement of 2.28+) | 2.39 |
| **LTS Support Until** | April 2027 | April 2029 |
| **Container Stability** | Proven, widely tested | Newer, less battle-tested |

**Why Noble over Jammy:**
- Longer LTS support (April 2029 vs April 2027)
- Both require NodeSource for Node.js anyway
- Modern base for future compatibility

### Alternatives Considered

- **Ubuntu 24.04**: Rejected due to less testing; no significant benefits since NodeSource is required anyway
- **Fedora**: Rejected per constitution—Ubuntu provides clear visual distinction from host (apt vs dnf)
- **Alpine**: Rejected due to musl libc compatibility concerns with Node.js native modules

### Distrobox Image

```bash
distrobox create --image ubuntu:24.04 --name foundryvtt
```

---

## 2. Bazzite Detection Method

### Decision: Check `ID=bazzite` in `/etc/os-release`

### Rationale

Bazzite explicitly sets `ID=bazzite` in `/etc/os-release` during build. This is:
- **Unique**: Vanilla Fedora uses `ID=fedora`
- **Reliable**: Set at build time, not user-modifiable in normal operation
- **Standard**: Uses the standard Linux os-release file

### Implementation

```bash
is_bazzite() {
    # Primary check: ID field in os-release
    if grep -q "^ID=bazzite" /etc/os-release 2>/dev/null; then
        return 0
    fi
    return 1
}

# Usage
if ! is_bazzite; then
    echo "Error: This script requires Bazzite Linux."
    echo "Detected OS: $(grep ^ID= /etc/os-release 2>/dev/null | cut -d= -f2)"
    echo "Get Bazzite at: https://bazzite.gg"
    exit 1
fi
```

### Fallback Methods (if needed)

1. Check `/usr/lib/os-release` (canonical location)
2. Check `/usr/share/ublue-os/image-info.json` for `"image-name": "bazzite"`

### What NOT to Use

- `ID_LIKE=fedora` - matches any Fedora derivative
- Hostname or installed packages - user-modifiable

---

## 3. FoundryVTT Node.js Version Discovery

### Decision: Extract version from Timed URL, use hardcoded mapping

### Rationale

FoundryVTT's Node.js requirements are documented per major version and don't change retroactively. The Timed URL contains the FoundryVTT version, allowing us to determine the required Node.js version before download.

### Current Requirements (from official docs)

| FoundryVTT Version | Minimum Node.js | Recommended Node.js | Incompatible |
|-------------------|-----------------|---------------------|--------------|
| V14, V13 | 20.18+ | **22.x** | 23+, 24+ |
| V12 | 18.x+ | 20.x | - |
| V11 | 18.x+ | 18.x LTS | - |

**Source**: https://foundryvtt.com/article/installation/

### Implementation

```bash
# Extract version from Timed URL
# Format: https://r2.foundryvtt.com/releases/{version}/FoundryVTT-{build}-{version}.zip?verify=...
parse_foundry_version() {
    local url="$1"
    echo "$url" | grep -oP 'releases/\K[0-9]+\.[0-9]+' | head -1
}

# Get recommended Node.js version for FoundryVTT version
get_node_version() {
    local foundry_version="$1"
    local major="${foundry_version%%.*}"
    
    case "$major" in
        14|13) echo "22" ;;  # V13+: Node 22.x recommended
        12)    echo "20" ;;  # V12: Node 20.x
        11|10) echo "18" ;;  # Older: Node 18.x
        *)     echo "22" ;;  # Future versions: default to latest LTS
    esac
}
```

### Node.js Installation (inside container)

```bash
# Install via NodeSource (recommended)
NODE_MAJOR=$(get_node_version "$FOUNDRY_VERSION")
curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | sudo -E bash -
sudo apt-get install -y nodejs
```

### Alternatives Considered

- **Check package.json after download**: Rejected—requires download before installing Node.js
- **Query FoundryVTT API**: Rejected—no public API for version requirements
- **nvm (Node Version Manager)**: Considered as alternative; adds complexity but provides flexibility

---

## 4. Auto-Start Configuration

### Decision: systemd user service (NOT Quadlet)

### Rationale

Quadlet is designed for raw Podman containers, not Distrobox containers. Distrobox containers have special initialization requirements that Quadlet cannot handle.

**Why systemd user service:**
- Works natively with Distrobox's `distrobox enter` command
- User-level (no root required)
- Bazzite's immutable filesystem restricts system-level changes
- Standard approach used by other Distrobox-based applications

### Implementation

**Service file location**: `~/.config/systemd/user/foundryvtt.service`

```ini
[Unit]
Description=FoundryVTT Server in Distrobox
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/distrobox enter foundryvtt -- node %h/foundryvtt/resources/app/main.js --dataPath=%h/FoundryVTT --port=30000
Restart=on-failure
RestartSec=10
TimeoutStartSec=300

[Install]
WantedBy=default.target
```

**Enable commands:**
```bash
systemctl --user daemon-reload
systemctl --user enable --now foundryvtt.service
# Required for boot-time startup without login:
loginctl enable-linger "$USER"
```

### Bazzite-Specific Considerations

1. **User lingering**: Required for services to start at boot before login
2. **SELinux**: Volume mounts may need `:Z` suffix for proper labeling
3. **Timeouts**: Set generous timeouts (300s) for initial container/image setup

### Alternatives Considered

- **Quadlet .container files**: Rejected—incompatible with Distrobox containers
- **distrobox-assemble**: Useful for container definition, but still needs systemd for auto-start
- **Cron @reboot**: Rejected—less reliable, no service management

---

## Summary of Decisions

| Question | Decision | Key Reason |
|----------|----------|------------|
| Ubuntu version | 22.04 LTS (Jammy) | Proven stability, NodeSource support |
| Bazzite detection | `ID=bazzite` in os-release | Unique, reliable, standard |
| Node.js version | Extract from URL, use mapping | Deterministic before download |
| Auto-start | systemd user service | Only option that works with Distrobox |

---

## References

- FoundryVTT Installation: https://foundryvtt.com/article/installation/
- FoundryVTT Requirements: https://foundryvtt.com/article/requirements/
- Bazzite Documentation: https://docs.bazzite.gg/
- NodeSource: https://github.com/nodesource/distributions
- Distrobox: https://github.com/89luca89/distrobox
- Quadlet: https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html
