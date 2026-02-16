# Quick Start: System Diagnostics & Status Report

**Time required**: ~2 minutes  
**Difficulty**: Beginner-friendly

---

## Before You Start

You'll need:

1. A computer running **Bazzite** (Steam Deck or desktop)
2. **FoundryVTT installed** using Feature 001 (or diagnostics will show "not installed")
3. Basic terminal familiarity (copy/paste commands)

---

## Step 1: Download the Diagnostic Script

Open a terminal and run:

```bash
curl -fsSL https://raw.githubusercontent.com/BrewerSeth/FoundryVTT-Bazzite/master/scripts/foundryvtt-diagnose.sh -o foundryvtt-diagnose.sh
chmod +x foundryvtt-diagnose.sh
```

---

## Step 2: Run a Quick Health Check

For a fast overview (takes ~2 seconds):

```bash
./foundryvtt-diagnose.sh --quick
```

You'll see output like:

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

---

## Step 3: Generate a Full Diagnostic Report

For comprehensive diagnostics (takes ~10-15 seconds):

```bash
./foundryvtt-diagnose.sh
```

This generates a detailed report with:
- Host system resources (CPU, memory, disk)
- Distrobox container status
- FoundryVTT instance details
- Network connectivity
- Recent log excerpts

---

## Step 4: Save the Report to a File

To save the report for later analysis or sharing:

```bash
./foundryvtt-diagnose.sh --output report.txt
```

Or as JSON for programmatic processing:

```bash
./foundryvtt-diagnose.sh --json --output report.json
```

---

## Step 5: Generate a Privacy-Safe Report

When sharing for support (masks sensitive info):

```bash
./foundryvtt-diagnose.sh --redact --output report-redacted.txt
```

This replaces:
- IP addresses → `[REDACTED_IP]`
- Full paths → `[REDACTED_PATH]`
- Usernames → `[REDACTED_USER]`
- Hostnames → `[REDACTED_HOST]`

---

## Understanding the Report

### Status Indicators

| Indicator | Meaning | Action Needed? |
|-----------|---------|----------------|
| 🟢 **HEALTHY** | Operating normally | No |
| 🟡 **WARNING** | Approaching limits or minor issues | Monitor |
| 🔴 **CRITICAL** | Errors or failures detected | Yes - investigate |
| ⚪ **UNKNOWN** | Cannot determine status | Check manually |

### Common Issues

**Container Not Running**
```
Containers:     🔴 CRITICAL (foundryvtt: exited)
```
→ Start the container: `distrobox enter foundryvtt` or restart the service

**Service Not Enabled**
```
Instances:      🟡 WARNING (service: inactive)
```
→ Enable auto-start: `./setup-foundryvtt.sh` and select "Reconfigure"

**High Resource Usage**
```
Memory Usage:   🔴 CRITICAL (94%)
```
→ Close other applications or add more RAM

**Disk Space Low**
```
Disk Usage:     🔴 CRITICAL (Data: 96%)
```
→ Free up space or move data to external drive

---

## Command Reference

```bash
# Quick health check (fast)
./foundryvtt-diagnose.sh --quick
./foundryvtt-diagnose.sh -q

# Full report (default)
./foundryvtt-diagnose.sh

# Save to file
./foundryvtt-diagnose.sh --output report.txt
./foundryvtt-diagnose.sh -o report.txt

# JSON format
./foundryvtt-diagnose.sh --json
./foundryvtt-diagnose.sh -j

# Privacy redaction
./foundryvtt-diagnose.sh --redact
./foundryvtt-diagnose.sh -r

# Combined options
./foundryvtt-diagnose.sh --json --redact --output report.json
```

---

## Sharing for Support

When asking for help:

1. **Run the diagnostic**:
   ```bash
   ./foundryvtt-diagnose.sh --redact --output diagnostic-report.txt
   ```

2. **Copy the contents** of `diagnostic-report.txt`

3. **Paste into**:
   - GitHub issue: https://github.com/BrewerSeth/FoundryVTT-Bazzite/issues
   - FoundryVTT Discord: https://discord.gg/foundryvtt
   - AI assistant (ChatGPT, Claude, etc.)

The redacted report is safe to share publicly - no sensitive information is exposed.

---

## Troubleshooting

### "Command not found"
Make sure you're in the directory where you downloaded the script, or use the full path.

### "Permission denied"
Run: `chmod +x foundryvtt-diagnose.sh`

### "FoundryVTT not installed"
The diagnostic script can only report on what's installed. If you haven't run Feature 001 setup yet, the report will show "NOT_INSTALLED" status.

### Script takes too long
Use `--quick` mode for a 2-second summary instead of the full report.

---

## Next Steps

- **Everything healthy?** Great! Your FoundryVTT setup is working well.
- **Issues detected?** Check the detailed report for specific problems and solutions.
- **Need help?** Share a redacted report on GitHub or Discord.

---

## Getting Help

- **FoundryVTT Discord**: [discord.gg/foundryvtt](https://discord.gg/foundryvtt)
- **Bazzite Discord**: [discord.bazzite.gg](https://discord.bazzite.gg)
- **This project**: [GitHub Issues](https://github.com/BrewerSeth/FoundryVTT-Bazzite/issues)
