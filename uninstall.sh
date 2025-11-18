#!/usr/bin/env zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL
trap 'echo "💥 Error on line $LINENO"; exit 1' ZERR

# ===== config =====
ZSHRC_DEFAULT="${ZSHRC:-$HOME/.zshrc}"
ZSHRC="${1:-$ZSHRC_DEFAULT}"
MARK_PREFIX="# >>> TySP-Dev/Zsh-Functions:"
MARK_SUFFIX="# <<< TySP-Dev/Zsh-Functions"
# ==================

PROG="$(basename "$0")"

# --- guards ---
# Check if .zshrc exists
[[ -f "$HOME/.zshrc" ]] || { echo "❌ .zshrc not found at $HOME/.zshrc - zsh must be configured first." >&2; exit 1; }

# Zsh version check
if [[ -z "${ZSH_VERSION:-}" ]]; then
  echo "❌ This script must be run with zsh, not bash or other shells." >&2
  exit 1
fi

if ! command -v zsh >/dev/null 2>&1; then
  echo "❌ zsh not found. Install zsh first." >&2; exit 1
fi

usage() {
  cat <<EOF
Usage: $PROG [path to .zshrc] [--all|--list|--dry-run]

  --list     List installed blocks and exit
  --all      Remove all installed blocks without selection prompt
  --dry-run  Show what would be removed, but don't modify the file

Interactive (no fzf): enter numbers, ranges (e.g. 2-5), or 'a' for all.
EOF
}

[[ -f "$ZSHRC" ]] || { echo "❌ zshrc not found: $ZSHRC"; exit 1; }

# ---- flags ----
flag_all=0
flag_list=0
flag_dry=0
for arg in "${@:2}"; do
  case "$arg" in
    --all)     flag_all=1 ;;
    --list)    flag_list=1 ;;
    --dry-run) flag_dry=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "❌ Unknown arg: $arg"; usage; exit 1 ;;
  esac
done

# --- package manager detection ---
detect_pm() {
  if command -v pacman >/dev/null 2>&1; then echo pacman; return; fi
  if command -v apt    >/dev/null 2>&1; then echo apt;    return; fi
  if command -v dnf    >/dev/null 2>&1; then echo dnf;    return; fi
  if command -v brew   >/dev/null 2>&1; then echo brew;   return; fi
  echo unknown
}

# --- check and install fzf if needed ---
install_fzf_if_missing() {
  command -v fzf >/dev/null 2>&1 && return 0

  echo "⚠️  fzf is not installed but recommended for better interactive selection."
  pm="$(detect_pm)"

  case "$pm" in
    pacman)
      echo "🛠  Detected Arch Linux (pacman)"
      read "yn?Install fzf via 'sudo pacman -S fzf'? [Y/n] "
      if [[ ! "${yn:-Y}" =~ ^[Nn]$ ]]; then
        sudo pacman -S --needed fzf
      fi
      ;;
    apt)
      echo "🛠  Detected Debian/Ubuntu (apt)"
      read "yn?Install fzf via 'sudo apt install fzf'? [Y/n] "
      if [[ ! "${yn:-Y}" =~ ^[Nn]$ ]]; then
        sudo apt update && sudo apt install -y fzf
      fi
      ;;
    dnf)
      echo "🛠  Detected Fedora/RHEL (dnf)"
      read "yn?Install fzf via 'sudo dnf install fzf'? [Y/n] "
      if [[ ! "${yn:-Y}" =~ ^[Nn]$ ]]; then
        sudo dnf install -y fzf
      fi
      ;;
    brew)
      echo "🛠  Detected Homebrew (macOS/Linux)"
      read "yn?Install fzf via 'brew install fzf'? [Y/n] "
      if [[ ! "${yn:-Y}" =~ ^[Nn]$ ]]; then
        brew install fzf
      fi
      ;;
    *)
      echo "ℹ️  Could not detect package manager. Please install fzf manually."
      echo "   Visit: https://github.com/junegunn/fzf#installation"
      return 1
      ;;
  esac
}

install_fzf_if_missing

# ---- discover installed blocks ----
INSTALLED=()
while IFS= read -r line; do
  INSTALLED+=("$line")
done < <(
  awk '
    /^[[:space:]]*#[[:space:]]*>>>[[:space:]]*TySP-Dev\/Zsh-Functions:/ {
      # Extract everything after the marker
      rest = $0
      sub(/^[[:space:]]*#[[:space:]]*>>>[[:space:]]*TySP-Dev\/Zsh-Functions:[[:space:]]*/, "", rest)
      if (match(rest, /^[^ \t(]+/)) {
        fname = substr(rest, RSTART, RLENGTH)
        # Strip .zsh extension if present
        sub(/\.zsh$/, "", fname)
        if (length(fname) > 0) print fname
      }
    }
  ' "$ZSHRC" | sort -u
)

if ((${#INSTALLED[@]} == 0)); then
  echo "ℹ️  No installed blocks found in $ZSHRC"
  exit 0
fi

if (( flag_list )); then
  echo "📚 Installed blocks in $ZSHRC:"
  printf '  - %s\n' "${INSTALLED[@]}"
  exit 0
fi

# ---- build tiny awk file for preview ----
PREVIEW_AWK="$(mktemp -t zfun-preview.XXXXXX.awk)"
cat >"$PREVIEW_AWK" <<'AWK'
BEGIN { show=0 }
{
  if (!show && /^[[:space:]]*#[[:space:]]*>>>[[:space:]]*TySP-Dev\/Zsh-Functions:/ && index($0, nm)) { show=1 }
  if (show) print
  if (show && /^[[:space:]]*#[[:space:]]*<<<[[:space:]]*TySP-Dev\/Zsh-Functions/) { show=0 }
}
AWK

cleanup() { rm -f -- "$PREVIEW_AWK" 2>/dev/null || true; }
trap cleanup EXIT

# ---- selection (fzf with preview; fallback to manual ranges) ----
declare -a PICKED=()
if (( flag_all )); then
  PICKED=("${INSTALLED[@]}")
else
  if command -v fzf >/dev/null 2>&1; then
    echo "🔎 Using fzf for interactive selection"
    echo "   Controls: Space/Tab=toggle • Enter=confirm • Esc/Ctrl+C=cancel"
    PICKED=()
    while IFS= read -r line; do
      PICKED+=("$line")
    done < <(
      printf '%s\n' "${INSTALLED[@]}" |
        fzf -m \
            --prompt="Select blocks to uninstall: " \
            --header="⬆️⬇️ navigate • Space/Tab = toggle selection • Enter = confirm" \
            --bind 'space:toggle' \
            --bind 'tab:toggle' \
            --bind 'ctrl-a:select-all' \
            --bind 'ctrl-d:deselect-all' \
            --preview "awk -v pre=$(printf '%q' "$MARK_PREFIX") -v suf=$(printf '%q' "$MARK_SUFFIX") -v nm={} -f $(printf '%q' "$PREVIEW_AWK") $(printf '%q' "$ZSHRC") | bat --style=numbers,changes --color=always --language=zsh 2>/dev/null || cat -n" \
            --preview-window=right:65%:wrap \
            --height=90% \
            --border \
            --info=inline
    ) || true
  else
    echo "Select blocks to remove."
    echo "  • Enter numbers, ranges, or both (e.g. '1 3-5 8')."
    echo "  • Enter 'a' for all."
    i=1; declare -A IDX2NAME=()
    for name in "${INSTALLED[@]}"; do
      printf "  %2d) %s\n" "$i" "$name"
      IDX2NAME["$i"]="$name"
      ((i++))
    done
    echo -n "> "
    read -r -A tokens

    if [[ "${tokens[*]:-}" =~ (^|[[:space:]])a([[:space:]]|$) ]]; then
      PICKED=("${INSTALLED[@]}")
    else
      for t in "${tokens[@]:-}"; do
        if [[ "$t" =~ ^[0-9]+-[0-9]+$ ]]; then
          lo="${t%-*}"; hi="${t#*-}"
          [[ "$lo" -le "$hi" ]] || { tmp="$lo"; lo="$hi"; hi="$tmp"; }
          for ((k=lo; k<=hi; k++)); do
            [[ -n "${IDX2NAME[$k]:-}" ]] && PICKED+=("${IDX2NAME[$k]}")
          done
        elif [[ "$t" =~ ^[0-9]+$ ]]; then
          [[ -n "${IDX2NAME[$t]:-}" ]] && PICKED+=("${IDX2NAME[$t]}")
        fi
      done
    fi
  fi
fi

((${#PICKED[@]})) || { echo "ℹ️  Nothing selected. Exiting."; exit 0; }

# ---- backup ----
ts="$(date +%Y%m%d-%H%M%S)"
cp -f -- "$ZSHRC" "$ZSHRC.bak.$ts"
echo "🧷 Backup: $ZSHRC.bak.$ts"

# ---- removal helper ----
remove_block() {
  local name="$1" infile="$2" outfile="$3"
  awk -v nm="$name" '
    BEGIN {del=0}
    {
      if (!del && /^[[:space:]]*#[[:space:]]*>>>[[:space:]]*TySP-Dev\/Zsh-Functions:/ && index($0, nm)) { del=1; next }
      if (del && /^[[:space:]]*#[[:space:]]*<<<[[:space:]]*TySP-Dev\/Zsh-Functions/) { del=0; next }
      if (!del) print
    }
  ' "$infile" > "$outfile"
}

# ---- do removals ----
tmp="${ZSHRC}.tmp.$$"
cp -f -- "$ZSHRC" "$tmp"

declare -i removed=0 skipped=0
for name in "${PICKED[@]}"; do
  before_hash="$(sha256sum "$tmp" | awk '{print $1}')"
  remove_block "$name" "$tmp" "${tmp}.next"
  after_hash="$(sha256sum "${tmp}.next" | awk '{print $1}')"

  if [[ "$before_hash" != "$after_hash" ]]; then
    if (( flag_dry )); then
      echo "🧪 (dry-run) Would remove: $name"
      rm -f -- "${tmp}.next"
    else
      mv -f -- "${tmp}.next" "$tmp"
      echo "🗑️  Removed: $name"
      removed=$((removed + 1))
    fi
  else
    rm -f -- "${tmp}.next" || true
    echo "⏭️  Not found (skipped): $name"
    skipped=$((skipped + 1))
  fi
done

if (( ! flag_dry )); then
  mv -f -- "$tmp" "$ZSHRC"
else
  rm -f -- "$tmp"
fi

echo
if (( flag_dry )); then
  echo "✅ Dry run complete."
else
  echo "✅ Done. Removed: $removed  •  Skipped: $skipped"
  echo "👉 Run:   source \"$ZSHRC\""
fi
