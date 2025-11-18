## Name: manage-backups
## Desc: Manage .zshrc backup files with preview and deletion
## Usage: manage-backups
## Requires: fzf, awk
function manage-backups() {
  local ZSHRC="${ZSHRC:-$HOME/.zshrc}"
  local ZSHRC_DIR="$(dirname "$ZSHRC")"
  local MARK_PREFIX="# >>> TySP-Dev/Zsh-Functions:"
  local MARK_SUFFIX="# <<< TySP-Dev/Zsh-Functions"

  # Check requirements
  for cmd in fzf awk; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "❌ Missing required command: $cmd"; return 1; }
  done

  echo "🔍 Searching for .zshrc backup files..."

  # Find all backup files
  local -a backup_files=()
  backup_files=(${(f)"$(
    find "$ZSHRC_DIR" -maxdepth 1 -type f -name ".zshrc.bak.*" 2>/dev/null | sort -r
  )"})

  if (( ${#backup_files} == 0 )); then
    echo "ℹ️  No backup files found in $ZSHRC_DIR"
    return 0
  fi

  echo "📦 Found ${#backup_files[@]} backup file(s)"
  echo ""

  # Helper: Extract functions from a backup file
  _extract_functions() {
    local file="$1"
    awk -v pre="$MARK_PREFIX" -v suf="$MARK_SUFFIX" '
      BEGIN { count=0 }
      index($0, pre) {
        rest = substr($0, index($0, pre) + length(pre))
        sub(/^[ \t]+/, "", rest)
        if (match(rest, /^[^ \t(]+/)) {
          funcs[count++] = substr(rest, RSTART, RLENGTH)
        }
      }
      END {
        if (count > 0) {
          for (i=0; i<count; i++) {
            printf "%s", funcs[i]
            if (i < count-1) printf ", "
          }
        } else {
          printf "none"
        }
      }
    ' "$file"
  }

  # Helper: Get file size
  _get_size() {
    local file="$1"
    if command -v du >/dev/null 2>&1; then
      du -h "$file" 2>/dev/null | awk '{print $1}'
    else
      echo "?"
    fi
  }

  # Helper: Get file timestamp from filename or modification time
  _get_timestamp() {
    local file="$1"
    local basename="${file##*/}"

    # Try to extract from filename: .zshrc.bak.YYYYMMDD-HHMMSS
    if [[ "$basename" =~ \.zshrc\.bak\.([0-9]{8}-[0-9]{6}) ]]; then
      local ts="${match[1]}"
      # Format: YYYYMMDD-HHMMSS -> YYYY-MM-DD HH:MM:SS
      echo "${ts:0:4}-${ts:4:2}-${ts:6:2} ${ts:9:2}:${ts:11:2}:${ts:13:2}"
    else
      # Fallback to modification time
      if command -v stat >/dev/null 2>&1; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
          stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$file" 2>/dev/null
        else
          stat -c "%y" "$file" 2>/dev/null | cut -d'.' -f1
        fi
      else
        echo "unknown"
      fi
    fi
  }

  # Create preview script
  local TEMP_DIR="/tmp/zsh-manage-backups-$$"
  mkdir -p "$TEMP_DIR"
  trap "rm -rf '$TEMP_DIR'" EXIT INT TERM

  local preview_script="$TEMP_DIR/preview.sh"
  cat > "$preview_script" << 'PREVIEW_EOF'
#!/usr/bin/env zsh
file="$1"
MARK_PREFIX="# >>> TySP-Dev/Zsh-Functions:"
MARK_SUFFIX="# <<< TySP-Dev/Zsh-Functions"

if [[ ! -f "$file" ]]; then
  echo "❌ File not found: $file"
  exit 1
fi

basename="${file##*/}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📄 BACKUP FILE: $basename"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Show file info
if command -v stat >/dev/null 2>&1; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "📅 Created: $(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$file" 2>/dev/null || echo "unknown")"
    echo "📊 Size: $(stat -f "%z bytes" "$file" 2>/dev/null || echo "unknown")"
  else
    echo "📅 Modified: $(stat -c "%y" "$file" 2>/dev/null | cut -d'.' -f1 || echo "unknown")"
    echo "📊 Size: $(stat -c "%s bytes" "$file" 2>/dev/null || echo "unknown")"
  fi
fi

echo ""
echo "📦 Installed Functions:"
echo "━━━━━━━━━━━━━━━━━━━━━━"

# List functions
awk -v pre="$MARK_PREFIX" '
  index($0, pre) {
    rest = substr($0, index($0, pre) + length(pre))
    sub(/^[ \t]+/, "", rest)
    if (match(rest, /^[^ \t(]+/)) {
      fname = substr(rest, RSTART, RLENGTH)
      # Extract timestamp if present
      if (match(rest, /\(.*\)/)) {
        tstamp = substr(rest, RSTART+1, RLENGTH-2)
        printf "  • %s (%s)\n", fname, tstamp
      } else {
        printf "  • %s\n", fname
      }
    }
  }
' "$file"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 PREVIEW (first 30 lines):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command -v bat >/dev/null 2>&1; then
  bat --style=numbers,changes --color=always --language=zsh --line-range=:30 "$file" 2>/dev/null
elif command -v cat >/dev/null 2>&1; then
  cat -n "$file" | head -30
else
  head -30 "$file"
fi
PREVIEW_EOF
  chmod +x "$preview_script"

  # Build menu items with info
  local -a menu_items=()
  local file size timestamp funcs

  for file in "${backup_files[@]}"; do
    size="$(_get_size "$file")"
    timestamp="$(_get_timestamp "$file")"
    funcs="$(_extract_functions "$file")"

    local basename="${file##*/}"
    menu_items+=("$basename|$timestamp|$size|$funcs|$file")
  done

  # Main loop - allow multiple operations
  while true; do
    echo "🔎 Select backup files to delete (or ESC to exit):"
    echo ""

    local -a selected=()
    selected=(${(f)"$(
      printf '%s\n' "${menu_items[@]}" | \
        awk -F'|' '{printf "📦 %-35s  📅 %-19s  💾 %-8s  📋 %s\n", $1, $2, $3, $4}' | \
        fzf -m \
            --prompt="Select backups to delete: " \
            --header="⬆️⬇️ navigate • Space/Tab = select • Enter = delete • ESC = exit" \
            --bind 'space:toggle' \
            --bind 'tab:toggle' \
            --bind 'ctrl-a:select-all' \
            --bind 'ctrl-d:deselect-all' \
            --preview "zsh '$preview_script' {-1}" \
            --preview-window=right:65%:wrap \
            --height=90% \
            --border \
            --info=inline \
            --ansi
    )"})

    if (( ${#selected} == 0 )); then
      echo ""
      echo "👋 No backups selected. Exiting."
      return 0
    fi

    # Extract file paths from selections
    local -a to_delete=()
    for item in "${menu_items[@]}"; do
      local display_line=$(echo "$item" | awk -F'|' '{printf "📦 %-35s  📅 %-19s  💾 %-8s  📋 %s\n", $1, $2, $3, $4}')
      for sel in "${selected[@]}"; do
        if [[ "$display_line" == "$sel"* ]]; then
          local filepath=$(echo "$item" | awk -F'|' '{print $5}')
          to_delete+=("$filepath")
        fi
      done
    done

    # Remove duplicates
    to_delete=(${(u)to_delete})

    echo ""
    echo "🗑️  Selected ${#to_delete[@]} backup(s) for deletion:"
    for file in "${to_delete[@]}"; do
      echo "   • ${file##*/}"
    done
    echo ""

    # Confirm deletion
    read "confirm?⚠️  Delete these backups? This cannot be undone! [y/N] "
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      echo "❌ Deletion cancelled"
      continue
    fi

    # Delete files
    local -i deleted=0
    local -i failed=0

    for file in "${to_delete[@]}"; do
      if rm -f "$file" 2>/dev/null; then
        echo "   ✅ Deleted: ${file##*/}"
        ((deleted++))

        # Remove from menu_items
        menu_items=(${menu_items:#*|$file})
      else
        echo "   ❌ Failed to delete: ${file##*/}"
        ((failed++))
      fi
    done

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ Deleted: $deleted"
    [[ $failed -gt 0 ]] && echo "❌ Failed: $failed"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Check if any backups remain
    if (( ${#menu_items} == 0 )); then
      echo "✅ All backups deleted!"
      return 0
    fi

    # Ask if user wants to continue
    read "continue?Continue managing backups? [Y/n] "
    if [[ "$continue" =~ ^[Nn]$ ]]; then
      echo ""
      echo "👋 Exiting. ${#menu_items[@]} backup(s) remaining."
      return 0
    fi

    echo ""
  done
}
