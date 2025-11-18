# Zsh-Functions

A collection of powerful, cross-distro compatible Zsh functions for everyday development, networking, and system management tasks.
Easily install/uninstall functions into your `~/.zshrc` using the provided interactive scripts with fzf integration.

---

## ✨ What's New

- 🌍 **Full Cross-Distro Support**: All functions now work on Arch, Debian/Ubuntu, Fedora/RHEL, and macOS
- ⚙️ **Smart Package Manager Detection**: Automatically detects and uses available package managers
- 🔄 **Enhanced Update System**: Customizable settings menu to choose which package managers to use
- ⬆️ **Auto-Update from GitHub**: Check for and apply function updates directly from the repository
- 🗂️ **Backup Management**: Easily manage and clean up old .zshrc backup files
- 📦 **Auto-Install fzf**: Installer now automatically detects and offers to install fzf on major distros

---

## Features

- 🎯 **13 curated functions** for Linux/macOS development and system management
- 🚀 **Interactive installer** (`install.sh`) with fzf-based multi-select and preview
- 🗑️ **Smart uninstaller** (`uninstall.sh`) with preview of what will be removed
- 💾 **Automatic backups** before any modifications to `.zshrc`
- 🔍 **fzf auto-detection** with automatic installation on Arch, Debian, Fedora, and macOS
- 🌐 **Cross-distro compatible** - works on multiple Linux distributions and macOS
- ⬆️ **GitHub integration** for easy function updates

---

## Requirements

- **[Zsh](https://www.zsh.org/)** - This repo is built for Zsh (not Bash/Fish)
- **[fzf](https://github.com/junegunn/fzf)** - Interactive selection menus (will be auto-installed if missing)
- Standard utilities (awk, sed, cp, etc.) - Usually pre-installed

### Supported Platforms

- ✅ Arch Linux (pacman, yay)
- ✅ Debian/Ubuntu (apt)
- ✅ Fedora/RHEL (dnf)
- ✅ macOS (Homebrew)

---

## Installation

### Quick Start

Clone this repo:

```bash
git clone https://github.com/TySP-Dev/Zsh-Functions.git
cd Zsh-Functions
```

Make scripts executable:

```bash
chmod +x install.sh uninstall.sh
```

Run the installer:

```bash
./install.sh
```

### What the installer does:

1. ✅ Checks if zsh and .zshrc are properly configured
2. 🔍 Auto-detects if fzf is installed (offers to install if missing)
3. 📦 Scans for available function files in `functions/` directory
4. 🎨 Shows interactive menu with file preview (using bat or cat)
5. ✨ Detects missing dependencies and offers to install them
6. 📝 Appends selected functions to your `~/.zshrc` with clear markers
7. 💾 Creates timestamped backup (e.g. `.zshrc.bak.20250117-123456`)

### Installation Features

- **Multi-select**: Use Space/Tab to toggle, Enter to confirm, Esc to cancel
- **Preview**: See function contents before installing
- **Keybindings**:
  - `Ctrl+A` - Select all
  - `Ctrl+D` - Deselect all
  - `Space/Tab` - Toggle selection
  - `Enter` - Confirm
- **Smart dependencies**: Auto-detects missing packages and offers installation

Reload your shell:

```bash
source ~/.zshrc
```

---

## Updating Functions

Keep your functions up to date with the latest improvements:

```bash
# Interactive mode (select which functions to update)
update-functions

# Auto-update mode (update all available updates)
update-functions all
```

**Interactive mode** will:
1. Scan your installed functions
2. Check GitHub for updates
3. Show what's changed with diff preview
4. Let you select which functions to update
5. Automatically backup and update selected functions

**Auto-update mode (`all`)** will:
1. Scan your installed functions
2. Check GitHub for updates
3. Automatically update ALL functions that have updates
4. Create backup before updating
5. No user interaction required (great for scripts!)

You can also configure `update-system` to automatically run `update-functions all` during system updates - just enable it in the settings menu!

---

## Managing Backups

Clean up old .zshrc backup files:

```bash
manage-backups
```

Features:
- 📋 Lists all backup files with timestamps and sizes
- 👀 Preview backup contents and installed functions
- 🗑️ Multi-select deletion with confirmation
- 🔄 Continuous operation mode

---

## Uninstallation

To remove previously installed functions:

```bash
./uninstall.sh
```

Features:
- Shows list of installed functions with preview
- Multi-select removal
- Creates backup before removing
- Option to remove all at once with `--all`
- List installed functions with `--list`
- Dry-run mode with `--dry-run`

Example commands:

```bash
# Interactive removal
./uninstall.sh

# Remove all installed functions
./uninstall.sh --all

# List what's installed
./uninstall.sh --list

# Preview what would be removed
./uninstall.sh --dry-run
```

Reload your shell after uninstalling:

```bash
source ~/.zshrc
```

---

## Function Reference

### System Management

#### 🔄 `update-system [settings]`
**Universal system updater with customizable package managers**

Supports 11 package managers + function updates with auto-detection:
- System: pacman, apt, dnf
- AUR/extras: yay
- Universal: flatpak, snap, brew
- Language: cargo, pip, npm
- Functions: update-functions (updates your installed zsh functions from GitHub)

Features:
- First-run configuration menu
- Auto-detect mode or manual selection
- Optional function updates from GitHub
- Settings saved to `~/.config/zsh-functions/update-system.conf`
- Run `update-system settings` to reconfigure

```bash
# Update with current settings
update-system

# Open settings menu (enable/disable update-functions here!)
update-system settings
```

#### 🧹 `clean-cache`
**Clean package manager caches (auto-detects distro)**

Supports: pacman, yay, apt, dnf, flatpak, snap, brew, cargo, npm, pip

Automatically detects and cleans all available package managers on your system.

```bash
clean-cache
```

---

### Updates & Maintenance

#### ⬆️ `update-functions [all]`
**Check GitHub for function updates and apply them**

- Scans installed functions in your .zshrc
- Fetches latest versions from GitHub
- Shows diff preview of changes (interactive mode)
- Multi-select which functions to update (interactive mode)
- Automatic backup before updating

**Usage:**
```bash
# Interactive mode - select which functions to update
update-functions

# Auto mode - update all available updates (no prompts)
update-functions all
```

**Tip:** Enable `update_functions` in `update-system settings` to automatically update your functions during system updates!

#### 🗂️ `manage-backups`
**Manage and delete .zshrc backup files**

- Lists all .zshrc.bak.* files
- Shows file info and installed functions
- Preview backup contents
- Multi-select deletion with confirmation

```bash
manage-backups
```

---

### Networking

#### 🌐 `ipinfo`
**Show local IP addresses and public IP**

Cross-platform support:
- Linux: Uses `ip` command
- macOS/BSD: Uses `ifconfig`
- WSL: Uses `ipconfig.exe`
- Tries multiple public IP services with fallback

```bash
ipinfo
```

#### 🔍 `find-port <port>`
**Find processes using a specific port**

Tries multiple tools for cross-distro compatibility:
- `lsof` (most detailed)
- `ss` (modern Linux)
- `netstat` (fallback)

```bash
find-port 8080
```

#### 🛑 `killport <port>`
**Kill the process listening on a given port**

Smart process detection with multiple fallbacks, shows PIDs being killed.

```bash
killport 3000
```

#### 🕸️ `net-scan [subnet]`
**Scan LAN for active devices (uses nmap)**

Auto-detects your subnet or specify custom range.

```bash
net-scan              # Auto-detect subnet
net-scan 192.168.1.0/24  # Custom subnet
```

---

### Development Tools

#### 📜 `hist`
**Fuzzy-search command history with fzf and execute selection**

Interactive history search with preview and direct execution.

```bash
hist
```

#### 📌 `helpme [function-name]`
**Pretty-printed overview of all installed functions**

```bash
helpme              # List all functions
helpme update-system  # Show detailed help for specific function
```

---

### Android Development

#### 📲 `phone-wired [full]`
**Connect phone via USB and launch scrcpy**

```bash
phone-wired      # Normal mode
phone-wired full # Fullscreen with high bitrate
```

#### 📶 `phone-wireless [full]`
**Connect phone via Wi-Fi (ADB tcpip) and launch scrcpy**

Automatically sets up wireless ADB connection and launches scrcpy.

```bash
phone-wireless      # Normal mode
phone-wireless full # Fullscreen mode
```

---

### Utilities

#### ⛅ `weather [location]`
**Show current weather (auto-detect by default)**

```bash
weather           # Auto-detect location
weather London    # Specific location
```

#### 🎨 `change-fastfetch`
**Manage Fastfetch ASCII logos**

List, show, create, and set custom ASCII art for Fastfetch.

```bash
change-fastfetch --list              # List available logos
change-fastfetch --show logo.txt     # Preview a logo
change-fastfetch --create            # Create new logo
change-fastfetch logo.txt            # Set as active logo
```

---

## Creating Custom Functions

1. Create a new `.zsh` file in the `functions/` folder
2. Add metadata header at the top:

```zsh
## Name: my-function
## Desc: Description of what it does
## Usage: my-function [options]
## Requires: curl, jq
```

3. Write your function:

```zsh
function my-function() {
  echo "Hello from my custom function!"
  # Your code here
}
```

4. Install it using `./install.sh` or manually add to `~/.zshrc`

### Function Metadata

- `## Name:` - Function name (should match the function definition)
- `## Desc:` - Short description
- `## Usage:` - Usage syntax with examples
- `## Requires:` - Comma-separated list of required commands

The installer will automatically detect dependencies and offer to install them!

---

## How It Works

### Function Markers

Functions are installed as blocks in your `.zshrc` between markers:

```zsh
# >>> TySP-Dev/Zsh-Functions: function-name (installed 2025-01-17T12:34:56-08:00)
function function-name() {
  # function code here
}
# <<< TySP-Dev/Zsh-Functions
```

This makes them easy to:
- Identify in your .zshrc
- Update individually
- Remove cleanly
- Preview before deletion

### Cross-Distro Compatibility

All functions automatically detect available tools:
- Package managers (pacman, apt, dnf, brew, etc.)
- Network tools (ip, ifconfig, lsof, ss, netstat)
- Utilities (curl, wget, bat, cat)

No manual configuration needed - everything adapts to your system!

---

## Troubleshooting

### fzf not installed?

The installer will automatically detect and offer to install fzf on:
- Arch: `sudo pacman -S fzf`
- Debian/Ubuntu: `sudo apt install fzf`
- Fedora/RHEL: `sudo dnf install fzf`
- macOS: `brew install fzf`

### Scripts won't run?

Make sure they're executable and run with zsh:

```bash
chmod +x install.sh uninstall.sh
zsh install.sh
```

### Functions not working after install?

Reload your shell:

```bash
source ~/.zshrc
# or
exec zsh
```

### Want to restore from backup?

All backups are timestamped:

```bash
# List backups
ls -lh ~/.zshrc.bak.*

# Restore from backup
cp ~/.zshrc.bak.20250117-123456 ~/.zshrc
source ~/.zshrc
```

Or use the built-in backup manager:

```bash
manage-backups
```

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Guidelines

1. Follow the existing function structure with metadata headers
2. Make functions cross-distro compatible when possible
3. Test on multiple platforms if available
4. Update the README with your new function
5. Use clear, descriptive variable names
6. Add error handling and helpful messages

---

## License

This project is open source and available under the MIT License.

---

## Credits

Created and maintained by [TySP-Dev](https://github.com/TySP-Dev)

Special thanks to:
- [fzf](https://github.com/junegunn/fzf) for the amazing fuzzy finder
- [scrcpy](https://github.com/Genymobile/scrcpy) for Android screen mirroring
- The Zsh community for inspiration and best practices
