# FoundryVTT-Bazzite

Easy FoundryVTT setup for Bazzite Linux (Steam Deck and desktop).

> **Note**: This project was built with AI assistance. See our [constitution](.specify/memory/constitution.md) for transparency commitments.

## What is this?

A single script that sets up [FoundryVTT](https://foundryvtt.com) in an isolated container on [Bazzite](https://bazzite.gg). Perfect for gamers who want to self-host their virtual tabletop without Linux expertise.

## Features

- **One-command setup**: Download and run a single script
- **Isolated environment**: FoundryVTT runs in a Distrobox container, keeping your system clean
- **Custom data location**: Store your worlds on internal, external, or network drives
- **Auto-start option**: Have FoundryVTT start automatically when you boot your computer
- **Beginner-friendly**: Clear prompts guide you through every step
- **Safe for immutable systems**: Guides you to store data in locations that persist across Bazzite updates
- **Re-runnable**: Run the script again to reconfigure settings or reinstall

## Requirements

- **Bazzite Linux** (Steam Deck or desktop variant)
- **FoundryVTT license** (purchase at [foundryvtt.com](https://foundryvtt.com))
- **Internet connection** (for initial setup only)

## Quick Start

### 1. Download the setup script

```bash
curl -fsSL https://raw.githubusercontent.com/BrewerSeth/FoundryVTT-Bazzite/main/scripts/setup-foundryvtt.sh -o setup-foundryvtt.sh
chmod +x setup-foundryvtt.sh
```

### 2. Get your FoundryVTT download link

1. Go to [foundryvtt.com](https://foundryvtt.com) and log in
2. Navigate to **Purchased Licenses**
3. Select **"Node.js"** as the operating system
4. Click **"Timed URL"** and copy the link (valid for 5 minutes)

### 3. Run the setup script

```bash
./setup-foundryvtt.sh
```

The script will ask for:
- Your Timed URL
- Where to store your data (default: `~/FoundryVTT`)
- Whether to enable auto-start

### 4. Access FoundryVTT

Open your browser to: **http://localhost:30000**

## Re-running the Script

Already have FoundryVTT installed? Run the script again to:

- **Reconfigure**: Change your data location or auto-start settings (no new download needed)
- **Reinstall**: Remove and reinstall FoundryVTT completely (requires a new Timed URL)

```bash
./setup-foundryvtt.sh
```

## Managing FoundryVTT

If you enabled auto-start, use these commands:

```bash
# Check if FoundryVTT is running
systemctl --user status foundryvtt.service

# View logs
journalctl --user -u foundryvtt.service -f

# Stop/Start/Restart
systemctl --user stop foundryvtt.service
systemctl --user start foundryvtt.service
systemctl --user restart foundryvtt.service
```

## Documentation

- [Quick Start Guide](specs/001-distrobox-setup-script/quickstart.md)
- [Troubleshooting](docs/troubleshooting.md)

## How It Works

The setup script:
1. Creates an Ubuntu container using Distrobox (isolated from your Bazzite system)
2. Installs the correct Node.js version for your FoundryVTT release
3. Downloads and extracts FoundryVTT using your Timed URL
4. Configures your data storage location
5. (Optionally) Sets up a systemd service for auto-start

Your FoundryVTT data is stored on your host system, so it persists even if you recreate the container.

## Contributing

Contributions are welcome! See our [specifications](specs/) for technical details and planned features.

## License

MIT

## Acknowledgments

- [FoundryVTT](https://foundryvtt.com) - The amazing virtual tabletop
- [Bazzite](https://bazzite.gg) - Gaming-focused immutable Linux
- [Distrobox](https://github.com/89luca89/distrobox) - Container magic
- Built with AI assistance using [OpenCode](https://github.com/anomalyco/opencode)
