## Name: update-functions
## Desc: Check GitHub for function updates and selectively update them
## Usage: update-functions [all]
## Requires: curl, awk (fzf optional for interactive mode)
function update-functions() {
  local ZSHRC="${ZSHRC:-$HOME/.zshrc}"
  local MARK_PREFIX="# >>> TySP-Dev/Zsh-Functions:"
  local MARK_SUFFIX="# <<< TySP-Dev/Zsh-Functions"
  local GITHUB_RAW="https://raw.githubusercontent.com/TySP-Dev/Zsh-Functions/main/functions"
  local TEMP_DIR="/tmp/zsh-functions-update-$$"
  local AUTO_UPDATE=0

  # Check if 'all' parameter was passed
  if [[ "$1" == "all" ]]; then
    AUTO_UPDATE=1
  fi

  # Check requirements (fzf only needed for interactive mode)
  for cmd in curl awk; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "❌ Missing required command: $cmd"; return 1; }
  done

  # Check fzf only if not in auto mode
  if (( AUTO_UPDATE == 0 )) && ! command -v fzf >/dev/null 2>&1; then
    echo "❌ fzf is required for interactive mode"
    echo "   Use 'update-functions all' to update all available updates automatically"
    return 1
  fi

  [[ -f "$ZSHRC" ]] || { echo "❌ .zshrc not found: $ZSHRC"; return 1; }

  echo "🔍 Scanning installed functions..."

  # Extract installed function names from .zshrc
  local -a installed_functions=()
  installed_functions=(${(f)"$(
    awk -v pre="$MARK_PREFIX" '
      index($0, pre) {
        rest = substr($0, index($0, pre) + length(pre))
        sub(/^[ \t]+/, "", rest)
        if (match(rest, /^[^ \t(]+/)) {
          print substr(rest, RSTART, RLENGTH)
        }
      }
    ' "$ZSHRC" | sort -u
  )"})

  if (( ${#installed_functions} == 0 )); then
    echo "ℹ️  No installed functions found in $ZSHRC"
    echo "   Functions should be marked with:"
    echo "   $MARK_PREFIX <name>"
    echo "   $MARK_SUFFIX"
    return 0
  fi

  echo "📦 Found ${#installed_functions[@]} installed function(s): ${(j:, :)installed_functions}"
  echo ""

  # Create temp directory
  mkdir -p "$TEMP_DIR"
  trap "rm -rf '$TEMP_DIR'" EXIT INT TERM

  # Helper: Extract function from .zshrc
  _extract_installed() {
    local fname="$1"
    awk -v pre="$MARK_PREFIX" -v suf="$MARK_SUFFIX" -v nm="$fname" '
      BEGIN {found=0; inside=0}
      {
        if (!found && index($0, pre) && index($0, nm)) {
          found=1
          inside=1
          next
        }
        if (inside && index($0, suf)) {
          inside=0
          exit
        }
        if (inside) print
      }
    ' "$ZSHRC"
  }

  # Helper: Fetch function from GitHub
  _fetch_github() {
    local fname="$1"
    local url="$GITHUB_RAW/${fname}.zsh"
    curl -sf --max-time 10 "$url" 2>/dev/null
  }

  # Helper: Normalize function content (remove comments, blank lines, trailing whitespace)
  _normalize() {
    awk '
      /^[[:space:]]*##/ { next }
      /^[[:space:]]*$/ { next }
      { gsub(/[[:space:]]+$/, ""); print }
    '
  }

  echo "🌐 Checking GitHub for updates..."
  local -a updates_available=()
  local -A update_status=()

  for fname in "${installed_functions[@]}"; do
    echo -n "   Checking $fname... "

    # Fetch from GitHub
    local github_content="$(_fetch_github "$fname")"
    if [[ -z "$github_content" ]]; then
      echo "❌ Not found on GitHub"
      update_status[$fname]="not_found"
      continue
    fi

    # Extract installed version
    local installed_content="$(_extract_installed "$fname")"
    if [[ -z "$installed_content" ]]; then
      echo "⚠️  Could not extract from .zshrc"
      update_status[$fname]="error"
      continue
    fi

    # Save both versions to temp files
    echo "$installed_content" | _normalize > "$TEMP_DIR/${fname}.installed"
    echo "$github_content" | _normalize > "$TEMP_DIR/${fname}.github"

    # Compare normalized versions
    if diff -q "$TEMP_DIR/${fname}.installed" "$TEMP_DIR/${fname}.github" >/dev/null 2>&1; then
      echo "✅ Up to date"
      update_status[$fname]="up_to_date"
    else
      echo "🆕 Update available"
      update_status[$fname]="update_available"
      updates_available+=("$fname")

      # Save full GitHub version for later
      echo "$github_content" > "$TEMP_DIR/${fname}.new"
    fi
  done

  echo ""

  if (( ${#updates_available} == 0 )); then
    echo "✅ All functions are up to date!"
    return 0
  fi

  echo "📋 ${#updates_available[@]} update(s) available: ${(j:, :)updates_available}"
  echo ""

  # Handle auto-update mode (update all)
  local -a to_update=()
  if (( AUTO_UPDATE == 1 )); then
    echo "🤖 Auto-update mode: Updating all available functions..."
    to_update=("${updates_available[@]}")
  else
    # Build fzf menu for interactive selection
    if ! command -v fzf >/dev/null 2>&1; then
      echo "❌ fzf is required for interactive selection"
      echo "   Available updates: ${(j:, :)updates_available}"
      echo "   Use 'update-functions all' to update all automatically"
      return 1
    fi

  # Create preview helper script
  local preview_script="$TEMP_DIR/preview.sh"
  cat > "$preview_script" << 'PREVIEW_EOF'
#!/usr/bin/env zsh
fname="$1"
temp_dir="$2"

if [[ ! -f "$temp_dir/${fname}.installed" ]] || [[ ! -f "$temp_dir/${fname}.new" ]]; then
  echo "❌ Preview not available"
  exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 CHANGES FOR: $fname"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command -v diff >/dev/null 2>&1; then
  # Show unified diff with color if possible
  if diff --color=always -u "$temp_dir/${fname}.installed" "$temp_dir/${fname}.new" 2>/dev/null; then
    echo "No changes (identical)"
  fi
else
  echo "OLD VERSION:"
  echo "━━━━━━━━━━━━"
  head -20 "$temp_dir/${fname}.installed"
  echo ""
  echo "NEW VERSION:"
  echo "━━━━━━━━━━━━"
  head -20 "$temp_dir/${fname}.new"
fi
PREVIEW_EOF
    chmod +x "$preview_script"

    # Create menu items
    local -a menu_items=()
    for fname in "${updates_available[@]}"; do
      menu_items+=("🆕 $fname - Update available")
    done

    echo "🔎 Select functions to update (Space/Tab to toggle, Enter to confirm):"
    echo ""

    local -a selected=()
    selected=(${(f)"$(
      printf '%s\n' "${menu_items[@]}" | \
        fzf -m \
            --prompt="Select functions to update: " \
            --header="⬆️⬇️ navigate • Space/Tab = toggle • Enter = confirm • ESC = cancel" \
            --bind 'space:toggle' \
            --bind 'tab:toggle' \
            --bind 'ctrl-a:select-all' \
            --bind 'ctrl-d:deselect-all' \
            --preview "zsh '$preview_script' {2} '$TEMP_DIR'" \
            --preview-window=right:65%:wrap \
            --height=90% \
            --border \
            --info=inline
    )"})

    if (( ${#selected} == 0 )); then
      echo "ℹ️  No functions selected for update"
      return 0
    fi

    # Extract function names from selections
    for item in "${selected[@]}"; do
      # Extract function name (second field)
      local fname=$(echo "$item" | awk '{print $2}')
      to_update+=("$fname")
    done
  fi

  echo ""
  echo "📥 Updating ${#to_update[@]} function(s)..."
  echo ""

  # Backup .zshrc
  local backup_file="${ZSHRC}.bak.$(date +%Y%m%d-%H%M%S)"
  cp -f "$ZSHRC" "$backup_file"
  echo "🧷 Backup created: $backup_file"
  echo ""

  # Update each selected function
  local -i updated=0
  local -i failed=0

  for fname in "${to_update[@]}"; do
    echo "🔄 Updating $fname..."

    # Read the new content
    local new_content="$(<"$TEMP_DIR/${fname}.new")"
    if [[ -z "$new_content" ]]; then
      echo "   ❌ Failed to read new content"
      ((failed++))
      continue
    fi

    # Remove old version from .zshrc
    awk -v pre="$MARK_PREFIX" -v suf="$MARK_SUFFIX" -v nm="$fname" '
      BEGIN {del=0}
      {
        if (!del && index($0, pre) && index($0, nm)) { del=1; next }
        if (del && index($0, suf)) { del=0; next }
        if (!del) print
      }
    ' "$ZSHRC" > "${ZSHRC}.tmp"

    # Append new version
    {
      cat "${ZSHRC}.tmp"
      echo ""
      echo "$MARK_PREFIX $fname (updated $(date -Iseconds))"
      echo "$new_content"
      echo "$MARK_SUFFIX"
    } > "$ZSHRC"

    rm -f "${ZSHRC}.tmp"
    echo "   ✅ Updated successfully"
    ((updated++))
  done

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Update complete!"
  echo "   Updated: $updated"
  [[ $failed -gt 0 ]] && echo "   Failed: $failed"
  echo ""
  echo "👉 Run: source \"$ZSHRC\" to apply changes"
  echo "   Backup: $backup_file"
}
