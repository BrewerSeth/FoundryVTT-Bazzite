# Troubleshooting: FoundryVTT on Bazzite

This guide covers common issues you may encounter when setting up or running FoundryVTT on Bazzite.

---

## Setup Issues

### "This script requires Bazzite"

**Cause**: You're running the script on a non-Bazzite system.

**Solution**: This tool is specifically designed for Bazzite Linux, an immutable Fedora-based distribution. Get Bazzite at [bazzite.gg](https://bazzite.gg).

---

### "Timed URL has expired" / Download Failed

**Cause**: The FoundryVTT Timed URL is only valid for 5 minutes.

**Solution**:
1. Go back to [foundryvtt.com](https://foundryvtt.com)
2. Navigate to your Purchased Licenses page
3. Select "Node.js" as the operating system
4. Click "Timed URL" to generate a fresh link
5. Run the setup script again immediately

---

### "Invalid URL format"

**Cause**: The URL doesn't match the expected FoundryVTT Timed URL format.

**Solution**: Make sure you:
- Selected "Node.js" as the operating system (NOT "Linux")
- Copied the complete URL including the `?verify=` part
- Didn't accidentally add extra characters

Expected format:
```
https://r2.foundryvtt.com/releases/XX.XXX/FoundryVTT-linux-XX.XXX.zip?verify=...
```

---

### "Container already exists"

**Cause**: You've run the setup before and a container named `foundryvtt` exists.

**Solution**: The script will ask if you want to:
1. **Reconfigure** - Remove the existing container and start fresh
2. **Abort** - Exit without making changes

If you want to keep your existing setup, choose Abort.

---

### "No internet connection detected"

**Cause**: The script cannot reach the FoundryVTT website.

**Solution**:
- Check your internet connection
- If using a VPN, try disconnecting it
- Make sure `https://foundryvtt.com` is accessible in your browser

---

### "Path cannot contain spaces"

**Cause**: You specified a data path with spaces, which can cause issues with Distrobox.

**Solution**: Choose a path without spaces. For example:
- `/home/user/FoundryVTT` (OK)
- `/home/user/Foundry VTT` (NOT OK)

---

### "You don't have write permission"

**Cause**: The chosen data directory isn't writable by your user.

**Solution**:
- Choose a different path (e.g., somewhere in your home directory)
- Or fix permissions: `chmod u+w /path/to/directory`

---

## Runtime Issues

### FoundryVTT won't start

**Check the service status** (if auto-start is enabled):
```bash
systemctl --user status foundryvtt.service
```

**Check the logs**:
```bash
journalctl --user -u foundryvtt.service -f
```

**Try starting manually**:
```bash
distrobox enter foundryvtt -- node ~/foundryvtt/main.js --dataPath=~/FoundryVTT
```

---

### Can't access http://localhost:30000

**Check if FoundryVTT is running**:
```bash
ss -tlnp | grep 30000
```

**Check if the container is running**:
```bash
podman ps | grep foundryvtt
```

**Check firewall**:
```bash
sudo firewall-cmd --list-ports
```

If port 30000 isn't listed, you may need to allow it:
```bash
sudo firewall-cmd --add-port=30000/tcp --permanent
sudo firewall-cmd --reload
```

---

### Auto-start not working after reboot

**Check if user lingering is enabled**:
```bash
loginctl show-user $USER | grep Linger
```

If `Linger=no`, enable it:
```bash
loginctl enable-linger $USER
```

**Check if the service is enabled**:
```bash
systemctl --user is-enabled foundryvtt.service
```

If not enabled:
```bash
systemctl --user enable foundryvtt.service
```

---

### Container won't start

**Check Podman status**:
```bash
podman ps -a | grep foundryvtt
```

**Try recreating the container**:
```bash
distrobox rm -f foundryvtt
# Then run the setup script again
```

---

## Data & Backup Issues

### Where is my data stored?

By default, FoundryVTT data is stored in `~/FoundryVTT/`. Check your configuration:
```bash
cat ~/.config/foundryvtt-bazzite/config
```

The `DATA_PATH` variable shows your data location.

---

### Recovering from a failed setup

If setup failed partway through:

1. Remove the container:
   ```bash
   distrobox rm -f foundryvtt
   ```

2. Remove the configuration:
   ```bash
   rm -rf ~/.config/foundryvtt-bazzite
   ```

3. Run the setup script again

Your data in `~/FoundryVTT/` (or your custom path) is preserved.

---

## Getting More Help

- **FoundryVTT Discord**: [discord.gg/foundryvtt](https://discord.gg/foundryvtt)
- **Bazzite Discord**: [discord.bazzite.gg](https://discord.bazzite.gg)
- **GitHub Issues**: Report bugs at the project repository

When asking for help, include:
- The error message you're seeing
- Output of `distrobox list`
- Output of `cat ~/.config/foundryvtt-bazzite/config`
- Your Bazzite version (`cat /etc/os-release | grep VERSION`)
