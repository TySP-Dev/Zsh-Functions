# Zsh-Functions

A collection of useful custom Zsh functions for everyday development, networking, and system tasks.  
These can be easily installed/uninstalled into your `~/.zshrc` using the provided scripts.

---

> [!IMPORTANT]
> Both the installer and uninstaller where made for Arch<br>
> For other distros just add the functions you want to the end of `~/.zshrc`<br>
> You can use the installer with any distro but put `N` when it asks to install missing dependents and install them manually

## Features

- Curated set of zsh functions for Linux
- Easy installer (`install.sh`) with fzf-based multi-select
- Uninstaller (`uninstall.sh`)
- Automatic `.zshrc` backup before modifications

---

## Requirements

- [Zsh](https://www.zsh.org/) (this repo is built for Zsh, not Bash/Fish)
- [fzf](https://github.com/junegunn/fzf) (for nice selection menus; falls back to manual mode if missing)
- Standard GNU utilities (`awk`, `sed`, `cp`, etc.)

---

## Installation

Clone this repo:

```bash
git clone https://github.com/TySP-Dev/Zsh-Functions.git
cd Zsh-Functions
```

Make installer and uninstaller executable:

```bash
chmod +x install.sh
chmod +x uninstall.sh
```

Run the installer:

```bash
./install.sh
```

- You’ll be presented with a list of available functions from the `functions/` folder.  
- Select the ones you want (use **Tab/Space** to multi-select, **Enter** to confirm).  
- They’ll be appended to the end of your `~/.zshrc` (with clear markers).  
- Your `~/.zshrc` is always backed up (e.g. `.zshrc.bak.YYYYMMDD-HHMMSS`).  

Reload your shell:

```bash
source ~/.zshrc
```

---

## Uninstallation

To remove previously installed functions:

```bash
./uninstall.sh
```

- You’ll be shown a list of installed function blocks (discovered via the markers in your `~/.zshrc`).  
- Select the ones to remove (with preview of their contents).  
- A backup of your `.zshrc` is made before changes.  

To remove **all installed functions** at once:

```bash
./uninstall.sh --all
```

To just list what’s installed:

```bash
./uninstall.sh --list
```

Reload your shell:

```bash
source ~/.zshrc
```

---

## Function Reference

### 🔄 `update-system`
Updates system packages, AUR, Flatpak, and Rust crates.

### 🌐 `ipinfo`
Displays local IP addresses and your current public IP.

### 🔍 `find-port <port>`
Lists processes listening on a specific port.

### 🧹 `clean-cache`
Cleans pacman, yay, and Flatpak caches.

### 📜 `hist`
Interactive fuzzy-search of shell history with `fzf`. Run a command directly from history.

### 📲 `phone-wired [full]`
Launches [scrcpy](https://github.com/Genymobile/scrcpy) over USB.  
Use `--full` for fullscreen, higher bitrate, and audio buffer.

### 📶 `phone-wireless [full]`
Connects to your phone via ADB Wi-Fi, then launches scrcpy.  
Supports same `--full` option.

### ⛅ `weather [location]`
Shows the current weather. If no location given, tries to auto-detect.

### 🕸 `net-scan [subnet]`
Scans the LAN for active devices. Defaults to your current subnet.

### 🛑 `killport <port>`
Kills the process listening on the specified port.

### 🎨 `change-fastfetch`
Manage Fastfetch ASCII logos. Supports listing, showing, and setting custom art.

### 📌 `helpme`
Pretty-printed overview of all installed functions, with usage and details.

---

## Custom Function

- Create a new .zsh file in the functions folder
- Add a Name, Description, Usage and any Dependencies to the top like this:

```zsh
## Name: clean-cache
## Desc: Clean pacman, yay, and Flatpak caches
## Usage: clean-cache
## Requires: paccache, yay, flatpak
```

- Once you complete your function you can install it using `./install.sh`
- Or by adding your function to the bottom of `~/.zshrc`

---

## Notes

- Functions are installed as blocks in your `.zshrc` between:

  ```zsh
  # >>> TySP-Dev/Zsh-Functions: <name>
  ...
  # <<< TySP-Dev/Zsh-Functions
  ```

- This makes them easy to manage with the included installer/uninstaller.

- You can also just source `functions/*.zsh` manually if you prefer.
