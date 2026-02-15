# Quick Start: FoundryVTT on Bazzite

**Time required**: ~10 minutes  
**Difficulty**: Beginner-friendly

---

## Before You Start

You'll need:

1. A computer running **Bazzite** (Steam Deck or desktop)
2. A **FoundryVTT license** (purchase at [foundryvtt.com](https://foundryvtt.com))
3. An internet connection (for initial setup only)

---

## Step 1: Download the Setup Script

Open a terminal (press `Ctrl+Alt+T` on desktop, or use Konsole on Steam Deck) and run:

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/FoundryVTT-Bazzite/main/scripts/setup-foundryvtt.sh -o setup-foundryvtt.sh
chmod +x setup-foundryvtt.sh
```

---

## Step 2: Get Your FoundryVTT Download Link

1. Go to [foundryvtt.com](https://foundryvtt.com) and log in
2. Navigate to your **Purchased Licenses** page
3. Select **"Node.js"** as the operating system
4. Click the **"Timed URL"** button
5. **Copy the link** (it's valid for 5 minutes)

> **Tip**: Don't close your browser yet—you'll paste the link in the next step.

---

## Step 3: Run the Setup Script

```bash
./setup-foundryvtt.sh
```

The script will ask you a few questions:

### Question 1: Timed URL
Paste the download link you copied from the FoundryVTT website.

### Question 2: Data Location
Where should your worlds, modules, and game data be stored?

- **Default**: `~/FoundryVTT` (recommended for most users)
- **Custom**: Choose your own path (useful for external drives)

### Question 3: Auto-Start
Should FoundryVTT start automatically when you turn on your computer?

- **Yes**: Great for dedicated game servers
- **No**: Start manually when you want to play (saves resources)

---

## Step 4: Wait for Setup

The script will:
1. Create an isolated container for FoundryVTT
2. Install the correct Node.js version
3. Download and extract FoundryVTT
4. Configure your data directory
5. (Optionally) Set up auto-start

This takes about 5-10 minutes depending on your internet speed.

---

## Step 5: Launch FoundryVTT

When setup completes, start FoundryVTT with:

```bash
distrobox enter foundryvtt -- node ~/foundryvtt/main.js --dataPath=~/FoundryVTT
```

Then open your browser to: **http://localhost:30000**

> **First run**: You'll need to enter your FoundryVTT license key in the browser.

---

## Stopping FoundryVTT

Press `Ctrl+C` in the terminal where FoundryVTT is running.

If you enabled auto-start, you can also use:

```bash
systemctl --user stop foundryvtt.service
```

---

## Starting FoundryVTT Later

**If auto-start is disabled:**
```bash
distrobox enter foundryvtt -- node ~/foundryvtt/main.js --dataPath=~/FoundryVTT
```

**If auto-start is enabled:**
It starts automatically! Check status with:
```bash
systemctl --user status foundryvtt.service
```

---

## Troubleshooting

### "This script requires Bazzite"
You're running the script on a non-Bazzite system. This tool is specifically designed for Bazzite Linux.

### "Timed URL has expired"
The download link is only valid for 5 minutes. Go back to foundryvtt.com, click "Timed URL" again, and paste the new link.

### "Container already exists"
You've run the setup before. The script will ask if you want to reconfigure or skip.

### FoundryVTT won't start
Check the logs:
```bash
journalctl --user -u foundryvtt.service -f
```

### Can't access http://localhost:30000
Make sure FoundryVTT is running and check for firewall issues:
```bash
# Check if the port is listening
ss -tlnp | grep 30000
```

---

## Next Steps

- **Invite players**: Set up remote access (see Feature 004)
- **Back up your data**: Configure automated backups (see Feature 002)
- **Update FoundryVTT**: Keep your server current (see Feature 003)

---

## Getting Help

- **FoundryVTT Discord**: [discord.gg/foundryvtt](https://discord.gg/foundryvtt)
- **Bazzite Discord**: [discord.bazzite.gg](https://discord.bazzite.gg)
- **This project**: [GitHub Issues](https://github.com/YOUR_USERNAME/FoundryVTT-Bazzite/issues)
