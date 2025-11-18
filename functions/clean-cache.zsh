## Name: clean-cache
## Desc: Clean package manager caches across different distros
## Usage: clean-cache
## Requires: (auto-detects available package managers)
function clean-cache() {
  local cleaned=0

  # Detect and clean pacman cache (Arch)
  if command -v paccache >/dev/null 2>&1; then
    echo "🧹 Cleaning pacman cache..."
    sudo paccache -r
    ((cleaned++))
  elif command -v pacman >/dev/null 2>&1; then
    echo "🧹 Cleaning pacman cache..."
    sudo pacman -Sc --noconfirm
    ((cleaned++))
  fi

  # Clean yay cache (Arch AUR)
  if command -v yay >/dev/null 2>&1; then
    echo "🧹 Cleaning yay cache..."
    yay -Sc --noconfirm
    ((cleaned++))
  fi

  # Clean apt cache (Debian/Ubuntu)
  if command -v apt >/dev/null 2>&1; then
    echo "🧹 Cleaning apt cache..."
    sudo apt clean
    sudo apt autoclean
    sudo apt autoremove -y
    ((cleaned++))
  fi

  # Clean dnf cache (Fedora/RHEL)
  if command -v dnf >/dev/null 2>&1; then
    echo "🧹 Cleaning dnf cache..."
    sudo dnf clean all
    sudo dnf autoremove -y
    ((cleaned++))
  fi

  # Clean Flatpak cache
  if command -v flatpak >/dev/null 2>&1; then
    echo "🧹 Cleaning Flatpak cache..."
    flatpak uninstall --unused -y
    ((cleaned++))
  fi

  # Clean Snap cache
  if command -v snap >/dev/null 2>&1; then
    echo "🧹 Cleaning Snap cache..."
    sudo snap set system refresh.retain=2
    # Remove old snap revisions
    local snap_list=$(snap list --all | awk '/disabled/{print $1, $3}')
    if [[ -n "$snap_list" ]]; then
      echo "$snap_list" | while read snapname revision; do
        sudo snap remove "$snapname" --revision="$revision" 2>/dev/null
      done
    fi
    ((cleaned++))
  fi

  # Clean Homebrew cache
  if command -v brew >/dev/null 2>&1; then
    echo "🧹 Cleaning Homebrew cache..."
    brew cleanup -s
    brew autoremove
    ((cleaned++))
  fi

  # Clean cargo cache
  if command -v cargo >/dev/null 2>&1; then
    if [[ -d "$HOME/.cargo/registry" ]]; then
      echo "🧹 Cleaning cargo registry cache..."
      du -sh "$HOME/.cargo/registry" 2>/dev/null
      rm -rf "$HOME/.cargo/registry/index/"*
      rm -rf "$HOME/.cargo/registry/cache/"*
      ((cleaned++))
    fi
  fi

  # Clean npm cache
  if command -v npm >/dev/null 2>&1; then
    echo "🧹 Cleaning npm cache..."
    npm cache clean --force
    ((cleaned++))
  fi

  # Clean pip cache
  if command -v pip3 >/dev/null 2>&1; then
    echo "🧹 Cleaning pip cache..."
    pip3 cache purge 2>/dev/null || pip3 cache remove '*' 2>/dev/null
    ((cleaned++))
  elif command -v pip >/dev/null 2>&1; then
    echo "🧹 Cleaning pip cache..."
    pip cache purge 2>/dev/null || pip cache remove '*' 2>/dev/null
    ((cleaned++))
  fi

  if (( cleaned == 0 )); then
    echo "ℹ️  No package managers found to clean."
    return 1
  fi

  echo ""
  echo "✅ Cache cleaning complete! ($cleaned package manager(s) cleaned)"
}
