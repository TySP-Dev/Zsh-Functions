## Name: update-system
## Desc: Universal system updater with customizable package manager support
## Usage: update-system [settings]
## Requires: fzf
function update-system() {
  local SETTINGS_FILE="$HOME/.config/zsh-functions/update-system.conf"
  local SETTINGS_DIR="$(dirname "$SETTINGS_FILE")"

  # Default settings
  local -A DEFAULT_SETTINGS=(
    [auto_detect]="true"
    [update_functions]="false"
    [pacman]="false"
    [apt]="false"
    [dnf]="false"
    [yay]="false"
    [flatpak]="false"
    [snap]="false"
    [brew]="false"
    [cargo]="false"
    [pip]="false"
    [npm]="false"
  )

  # Create settings directory if needed
  [[ -d "$SETTINGS_DIR" ]] || mkdir -p "$SETTINGS_DIR"

  # Load or create settings
  _load_settings() {
    if [[ -f "$SETTINGS_FILE" ]]; then
      # Parse settings file and populate SETTINGS array
      while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue
        # Trim whitespace using parameter expansion
        key="${key#"${key%%[![:space:]]*}"}"    # remove leading whitespace
        key="${key%"${key##*[![:space:]]}"}"    # remove trailing whitespace
        value="${value#"${value%%[![:space:]]*}"}"  # remove leading whitespace
        value="${value%"${value##*[![:space:]]}"}"  # remove trailing whitespace
        # Store in SETTINGS array
        [[ -n "$key" ]] && SETTINGS[$key]="$value"
      done < "$SETTINGS_FILE"
    else
      # First run - save defaults
      _save_settings
      return 1  # signal first run
    fi
    return 0
  }

  _save_settings() {
    {
      echo "# update-system settings"
      echo "# Generated on $(date)"
      echo ""
      for key val in "${(@kv)SETTINGS}"; do
        echo "${key}=${val}"
      done
    } > "$SETTINGS_FILE"
  }

  # Initialize settings
  typeset -A SETTINGS
  for key val in "${(@kv)DEFAULT_SETTINGS}"; do
    SETTINGS[$key]="$val"
  done

  # Check if this is first run
  local first_run=0
  _load_settings || first_run=1

  # Detect available package managers
  _detect_pm() {
    local -A detected
    command -v pacman >/dev/null 2>&1 && detected[pacman]="true"
    command -v apt    >/dev/null 2>&1 && detected[apt]="true"
    command -v dnf    >/dev/null 2>&1 && detected[dnf]="true"
    command -v yay    >/dev/null 2>&1 && detected[yay]="true"
    command -v flatpak>/dev/null 2>&1 && detected[flatpak]="true"
    command -v snap   >/dev/null 2>&1 && detected[snap]="true"
    command -v brew   >/dev/null 2>&1 && detected[brew]="true"
    command -v cargo  >/dev/null 2>&1 && detected[cargo]="true"
    command -v pip    >/dev/null 2>&1 && detected[pip]="true"
    command -v npm    >/dev/null 2>&1 && detected[npm]="true"

    # Return detected list
    for key val in "${(@kv)detected}"; do
      echo "$key"
    done
  }

  # Settings menu
  _settings_menu() {
    if ! command -v fzf >/dev/null 2>&1; then
      echo "❌ fzf is required for the settings menu"
      echo "   Settings file: $SETTINGS_FILE"
      return 1
    fi

    local -a detected_pms=(${(f)"$(_detect_pm)"})
    local -a menu_items=()

    # Build menu with current status
    local pm pm_status icon
    for pm in auto_detect update_functions pacman apt dnf yay flatpak snap brew cargo pip npm; do
      pm_status="${SETTINGS[$pm]}"

      # Determine icon and availability
      if [[ "$pm" == "auto_detect" ]]; then
        icon="🔍"
        if [[ "$pm_status" == "true" ]]; then
          menu_items+=("$icon $pm [ENABLED] - Auto-detect and use all available package managers")
        else
          menu_items+=("$icon $pm [DISABLED] - Manually select package managers")
        fi
      elif [[ "$pm" == "update_functions" ]]; then
        icon="⬆️"
        if [[ "$pm_status" == "true" ]]; then
          menu_items+=("$icon $pm [ON] - Update installed zsh functions from GitHub")
        else
          menu_items+=("$icon $pm [OFF] - Skip function updates")
        fi
      else
        # Check if available
        if (( ${detected_pms[(Ie)$pm]} )); then
          icon="✅"
        else
          icon="❌"
        fi

        if [[ "$pm_status" == "true" ]]; then
          menu_items+=("$icon $pm [ON] - Available and enabled")
        else
          menu_items+=("$icon $pm [OFF] - $(if (( ${detected_pms[(Ie)$pm]} )); then echo "Available"; else echo "Not installed"; fi)")
        fi
      fi
    done

    menu_items+=("💾 Save and Exit")

    while true; do
      local selected
      selected=$(printf '%s\n' "${menu_items[@]}" | \
        fzf --prompt="⚙️  Update System Settings: " \
            --header="Press ENTER to toggle • ESC to cancel" \
            --height=90% \
            --border \
            --reverse \
            --info=inline)

      [[ -z "$selected" ]] && echo "❌ Cancelled" && return 1

      if [[ "$selected" == "💾 Save and Exit" ]]; then
        _save_settings
        echo "✅ Settings saved to $SETTINGS_FILE"
        return 0
      fi

      # Extract PM name from selection
      local pm_name=$(echo "$selected" | awk '{print $2}')

      # Toggle the setting
      if [[ "${SETTINGS[$pm_name]}" == "true" ]]; then
        SETTINGS[$pm_name]="false"
      else
        # Don't allow enabling if not installed (except auto_detect and update_functions)
        if [[ "$pm_name" != "auto_detect" ]] && [[ "$pm_name" != "update_functions" ]] && ! (( ${detected_pms[(Ie)$pm_name]} )); then
          echo "⚠️  $pm_name is not installed on this system"
          sleep 1
        else
          SETTINGS[$pm_name]="true"
        fi
      fi

      # Rebuild menu
      menu_items=()
      for pm in auto_detect update_functions pacman apt dnf yay flatpak snap brew cargo pip npm; do
        pm_status="${SETTINGS[$pm]}"

        if [[ "$pm" == "auto_detect" ]]; then
          icon="🔍"
          if [[ "$pm_status" == "true" ]]; then
            menu_items+=("$icon $pm [ENABLED] - Auto-detect and use all available package managers")
          else
            menu_items+=("$icon $pm [DISABLED] - Manually select package managers")
          fi
        elif [[ "$pm" == "update_functions" ]]; then
          icon="⬆️"
          if [[ "$pm_status" == "true" ]]; then
            menu_items+=("$icon $pm [ON] - Update installed zsh functions from GitHub")
          else
            menu_items+=("$icon $pm [OFF] - Skip function updates")
          fi
        else
          if (( ${detected_pms[(Ie)$pm]} )); then
            icon="✅"
          else
            icon="❌"
          fi

          if [[ "$pm_status" == "true" ]]; then
            menu_items+=("$icon $pm [ON] - Available and enabled")
          else
            menu_items+=("$icon $pm [OFF] - $(if (( ${detected_pms[(Ie)$pm]} )); then echo "Available"; else echo "Not installed"; fi)")
          fi
        fi
      done
      menu_items+=("💾 Save and Exit")
    done
  }

  # Update functions for each package manager
  _update_pacman() {
    echo "🔄 Updating system packages (pacman)..."
    sudo pacman -Syu --noconfirm
  }

  _update_apt() {
    echo "🔄 Updating system packages (apt)..."
    sudo apt update && sudo apt upgrade -y
  }

  _update_dnf() {
    echo "🔄 Updating system packages (dnf)..."
    sudo dnf upgrade -y
  }

  _update_yay() {
    echo "📦 Updating AUR packages (yay)..."
    yay -Syu --noconfirm
  }

  _update_flatpak() {
    echo "📦 Updating Flatpak packages..."
    flatpak update -y
  }

  _update_snap() {
    echo "📦 Updating Snap packages..."
    sudo snap refresh
  }

  _update_brew() {
    echo "🍺 Updating Homebrew packages..."
    brew update && brew upgrade
  }

  _update_cargo() {
    echo "🦀 Updating Rust crates..."

    # Check if cargo-install-update is available
    if command -v cargo-install-update >/dev/null 2>&1 || [[ -x "$HOME/.cargo/bin/cargo-install-update" ]]; then
      cargo install-update -a
    else
      echo "   📦 cargo-update not installed. Installing..."
      cargo install cargo-update

      # Check if it was installed successfully
      if [[ -x "$HOME/.cargo/bin/cargo-install-update" ]]; then
        echo "   ✅ cargo-update installed successfully"
        echo "   🔄 Running updates..."
        cargo install-update -a
      else
        echo "   ❌ Failed to install cargo-update"
        echo "   Binary not found at $HOME/.cargo/bin/cargo-install-update"
        return 1
      fi
    fi
  }

  _update_pip() {
    echo "🐍 Updating pip packages..."
    if command -v pip3 >/dev/null 2>&1; then
      pip3 list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -r -n1 pip3 install -U --user
    else
      pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -r -n1 pip install -U --user
    fi
  }

  _update_npm() {
    echo "📦 Updating global npm packages..."
    npm update -g
  }

  _update_update_functions() {
    echo "⬆️ Updating zsh functions from GitHub..."
    if command -v update-functions >/dev/null 2>&1; then
      update-functions all
    else
      echo "   ⚠️  update-functions command not found"
      echo "   Make sure the update-functions.zsh function is installed"
      return 1
    fi
  }

  # Main logic
  if [[ "$1" == "settings" ]]; then
    _settings_menu
    return $?
  fi

  # First run: show settings menu
  if (( first_run )); then
    echo "👋 Welcome! This is your first time running update-system."
    echo "   Let's configure which package managers to use."
    echo ""
    _settings_menu || return 1
    echo ""
  fi

  # Determine which package managers to update
  local -a to_update=()

  # Check if update_functions is enabled
  if [[ "${SETTINGS[update_functions]}" == "true" ]]; then
    to_update+=("update_functions")
  fi

  if [[ "${SETTINGS[auto_detect]}" == "true" ]]; then
    echo "🔍 Auto-detecting available package managers..."
    to_update+=(${(f)"$(_detect_pm)"})
  else
    # Use manual selections
    for pm in pacman apt dnf yay flatpak snap brew cargo pip npm; do
      if [[ "${SETTINGS[$pm]}" == "true" ]] && command -v "$pm" >/dev/null 2>&1; then
        to_update+=("$pm")
      fi
    done
  fi

  if (( ${#to_update} == 0 )); then
    echo "❌ No package managers or update options enabled."
    echo "   Run 'update-system settings' to configure."
    return 1
  fi

  echo "📋 Updating: ${(j:, :)to_update}"
  echo ""

  # Execute updates
  for pm in "${to_update[@]}"; do
    "_update_$pm" || echo "⚠️  Update failed for $pm"
    echo ""
  done

  echo "✅ System update complete!"
}
