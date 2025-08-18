#!/usr/bin/env bash
set -euo pipefail
trap 'echo "💥 Error on line $LINENO running: \"$BASH_COMMAND\""; exit 1' ERR

# ===== config =====
ZSHRC_DEFAULT="${ZSHRC:-$HOME/.zshrc}"
ZSHRC="${1:-$ZSHRC_DEFAULT}"
MARK_PREFIX="# >>> TySP-Dev/Zsh-Functions:"
MARK_SUFFIX="# <<< TySP-Dev/Zsh-Functions"
# ==================

PROG="$(basename "$0")"

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

# ---- discover installed blocks ----
mapfile -t INSTALLED < <(
  awk -v pre="$MARK_PREFIX" '
    index($0, pre) {
      rest = substr($0, index($0, pre) + length(pre))
      sub(/^[ \t]+/, "", rest)
      if (match(rest, /^[^ \t(]+/)) {
        print substr(rest, RSTART, RLENGTH)
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
  if (!show && index($0, pre) && index($0, nm)) { show=1 }
  if (show) print
  if (show && index($0, suf)) { show=0 }
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
    echo "🔎 fzf: Space/Tab to select, Enter to confirm."
    mapfile -t PICKED < <(
      printf '%s\n' "${INSTALLED[@]}" |
        fzf -m \
            --prompt="Select blocks to remove: " \
            --header="Space/Tab = select • Enter = confirm • Esc = cancel" \
            --bind 'space:toggle' \
            --bind 'tab:toggle' \
            --preview "awk -v pre=$(printf '%q' "$MARK_PREFIX") -v suf=$(printf '%q' "$MARK_SUFFIX") -v nm={} -f $(printf '%q' "$PREVIEW_AWK") $(printf '%q' "$ZSHRC")" \
            --preview-window=right:70%:wrap
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
    read -rp "> " -a tokens

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
  awk -v pre="$MARK_PREFIX" -v suf="$MARK_SUFFIX" -v nm="$name" '
    BEGIN {del=0}
    {
      if (!del && index($0, pre) && index($0, nm)) { del=1; next }
      if (del && index($0, suf)) { del=0; next }
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
