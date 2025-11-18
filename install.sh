#!/usr/bin/env zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL

trap 'echo "💥 Error on line $LINENO"; exit 1' ZERR

# ===== config =====
ZSHRC_DEFAULT="${ZSHRC:-$HOME/.zshrc}"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
FUNCTIONS_DIR="$REPO_DIR/functions"
MARK_PREFIX="# >>> TySP-Dev/Zsh-Functions:"
MARK_SUFFIX="# <<< TySP-Dev/Zsh-Functions"
DEBUG=0
[[ "$1" == "debug" ]] && DEBUG=1
# ==================

# --- guards ---
# Check if .zshrc exists
[[ -f "$HOME/.zshrc" ]] || { echo "❌ .zshrc not found at $HOME/.zshrc - zsh must be configured first." >&2; exit 1; }

if ! command -v zsh >/dev/null 2>&1; then
  echo "❌ zsh not found. Install zsh first." >&2; exit 1
fi
if [[ "${SHELL##*/}" != "zsh" ]]; then
  echo "⚠️  Current SHELL is '${SHELL}'. Target is zsh."
  read "yn?Proceed and install into ~/.zshrc? [y/N] "
  [[ "${yn:-n}" =~ ^[Yy]$ ]] || exit 1
fi
[[ -d "$FUNCTIONS_DIR" ]] || { echo "❌ Missing: $FUNCTIONS_DIR"; exit 1; }

ZSHRC="${1:-$ZSHRC_DEFAULT}"
touch "$ZSHRC" 2>/dev/null || { echo "❌ Cannot write $ZSHRC"; exit 1; }

# --- discover function files ---
ALL_FILES=()
while IFS= read -r line; do
  ALL_FILES+=("$line")
done < <(find "$FUNCTIONS_DIR" -maxdepth 1 -type f -name "*.zsh" | sort)
((${#ALL_FILES[@]})) || { echo "❌ No .zsh files in $FUNCTIONS_DIR"; exit 1; }

echo "📦 Found ${#ALL_FILES[@]} function file(s)."

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

# --- select files ---
declare -a PICKED
if command -v fzf >/dev/null 2>&1; then
  echo "🔎 Using fzf for interactive selection"
  echo "   Controls: Space/Tab=toggle • Enter=confirm • Esc/Ctrl+C=cancel"
  # Use Space and Tab to toggle selection; show a small preview of each file
  PICKED=()
  while IFS= read -r line; do
    PICKED+=("$line")
  done < <(
    printf '%s\n' "${ALL_FILES[@]##*/}" |
      fzf -m \
          --prompt="Select functions to install: " \
          --header="⬆️⬇️ navigate • Space/Tab = toggle selection • Enter = confirm" \
          --bind 'space:toggle' \
          --bind 'tab:toggle' \
          --bind 'ctrl-a:select-all' \
          --bind 'ctrl-d:deselect-all' \
          --preview "bat --style=numbers,changes --color=always \"$FUNCTIONS_DIR/{1}\" 2>/dev/null || cat -n \"$FUNCTIONS_DIR/{1}\" 2>/dev/null || sed -n '1,40p' \"$FUNCTIONS_DIR/{1}\"" \
          --preview-window=right:65%:wrap \
          --height=90% \
          --border \
          --info=inline
  ) || true
else
  echo "Select functions to install."
  echo "  • Enter numbers, ranges, or both (e.g. '1 3-5 8')."
  echo "  • Enter 'a' for all."
  i=1; declare -A IDX2BASE
  for f in "${ALL_FILES[@]}"; do
    base="${f##*/}"
    printf "  %2d) %s\n" "$i" "$base"
    IDX2BASE["$i"]="$base"
    ((i++))
  done
  echo -n "> "
  read -r -A tokens

  # expand tokens into PICKED (supports 'a' and ranges like 2-5)
  if [[ "${tokens[*]}" =~ (^|[[:space:]])a([[:space:]]|$) ]]; then
    for f in "${ALL_FILES[@]}"; do PICKED+=("${f##*/}"); done
  else
    for t in "${tokens[@]:-}"; do
      if [[ "$t" =~ ^[0-9]+-[0-9]+$ ]]; then
        lo="${t%-*}"; hi="${t#*-}"
        [[ "$lo" -le "$hi" ]] || { tmp="$lo"; lo="$hi"; hi="$tmp"; }
        for ((k=lo; k<=hi; k++)); do
          [[ -n "${IDX2BASE[$k]:-}" ]] && PICKED+=("${IDX2BASE[$k]}")
        done
      elif [[ "$t" =~ ^[0-9]+$ ]]; then
        [[ -n "${IDX2BASE[$t]:-}" ]] && PICKED+=("${IDX2BASE[$t]}")
      fi
    done
  fi
fi

# nothing chosen (cancel or blank)
(( DEBUG )) && echo "DEBUG: PICKED array has ${#PICKED[@]} items: ${PICKED[@]}"
((${#PICKED[@]})) || { echo "ℹ️  Nothing selected."; exit 0; }

# to full paths (zsh array syntax)
PICKED_FULL=()
for base in "${PICKED[@]}"; do
  PICKED_FULL+=("$FUNCTIONS_DIR/$base")
done
PICKED=("${PICKED_FULL[@]}")
(( DEBUG )) && echo "DEBUG: After converting to full paths: ${PICKED[@]}"

# --- backup zshrc ---
ts="$(date +%Y%m%d-%H%M%S)"
cp -f -- "$ZSHRC" "$ZSHRC.bak.$ts"
echo "🧷 Backup: $ZSHRC.bak.$ts"

# --- helpers ---
extract_func_names() {
  # print function names defined in a file
  awk '
    /^[[:space:]]*function[[:space:]]+[A-Za-z0-9_:-]+[[:space:]]*\(\)[[:space:]]*\{/ {
      sub(/^[[:space:]]*function[[:space:]]+/,"",$0); sub(/\(\).*/,"",$0); print; next
    }
    /^[[:space:]]*[A-Za-z0-9_:-]+[[:space:]]*\(\)[[:space:]]*\{/ {
      s=$0; sub(/^[[:space:]]*/,"",s); sub(/\(\).*/,"",s); print s
    }
  ' "$1" | sed 's/[[:space:]]*$//'
}

already_installed() {
  local file="$1" base="${file##*/}"
  grep -Fq "$MARK_PREFIX $base" "$ZSHRC" && return 0
  while IFS= read -r fname; do
    [[ -z "$fname" ]] && continue
    grep -Eq "^[[:space:]]*(function[[:space:]]+)?${fname}[[:space:]]*\(\)" "$ZSHRC" && return 0
  done < <(extract_func_names "$file")
  return 1
}

# --- dependency DB (fallback if file lacks header) ---
declare -A CMD2PKG_PACMAN=(
  [fzf]="fzf"
  [adb]="android-tools"
  [scrcpy]="scrcpy"
  [nmap]="nmap"
  [paccache]="pacman-contrib"
  [yay]="yay"
  [flatpak]="flatpak"
  [cargo]="cargo"
  [curl]="curl"
  [awk]="gawk"
  [ip]="iproute2"
  [lsof]="lsof"
  [xargs]="findutils"
  [nano]="nano"
  [sed]="sed"
  [jq]="jq"
)

declare -A CMD2PKG_APT=(
  [fzf]="fzf"
  [adb]="adb"
  [scrcpy]="scrcpy"
  [nmap]="nmap"
  [curl]="curl"
  [awk]="gawk"
  [ip]="iproute2"
  [lsof]="lsof"
  [xargs]="findutils"
  [nano]="nano"
  [sed]="sed"
  [jq]="jq"
  [flatpak]="flatpak"
  [cargo]="cargo"
)

declare -A CMD2PKG_DNF=(
  [fzf]="fzf"
  [adb]="android-tools"
  [scrcpy]="scrcpy"
  [nmap]="nmap"
  [curl]="curl"
  [awk]="gawk"
  [ip]="iproute2"
  [lsof]="lsof"
  [xargs]="findutils"
  [nano]="nano"
  [sed]="sed"
  [jq]="jq"
  [flatpak]="flatpak"
  [cargo]="cargo"
)

# --- gather deps for selection ---
declare -A NEEDS=()         # command -> 1 (missing)
declare -A DEPS_FOR_FILE=() # file    -> "cmd1 cmd2 ..."

for file in "${PICKED[@]}"; do
  # header:  ## Requires: a, b, c
  header="$(awk -F: '/^[[:space:]]*##[[:space:]]*Requires[[:space:]]*:/{
    sub(/^[[:space:]]*##[[:space:]]*Requires[[:space:]]*:[[:space:]]*/,"");
    gsub(/,/," "); print
  }' "$file" | xargs -r)"

  # naive guess if header missing
  if [[ -z "$header" ]]; then
    guess=()
    grep -q '\bfzf\b'        "$file" && guess+=(fzf)
    grep -q '\badb\b'        "$file" && guess+=(adb)
    grep -q '\bscrcpy\b'     "$file" && guess+=(scrcpy)
    grep -q '\bnmap\b'       "$file" && guess+=(nmap)
    grep -q '\bpaccache\b'   "$file" && guess+=(paccache)
    grep -q '\byay\b'        "$file" && guess+=(yay)
    grep -q '\bflatpak\b'    "$file" && guess+=(flatpak)
    grep -q '\bcargo\b'      "$file" && guess+=(cargo)
    grep -q '\bcurl\b'       "$file" && guess+=(curl)
    grep -q '\bawk\b'        "$file" && guess+=(awk)
    grep -q '\bip\b'         "$file" && guess+=(ip)
    grep -q '\blsof\b'       "$file" && guess+=(lsof)
    grep -q '\bxargs\b'      "$file" && guess+=(xargs)
    grep -q '\bnano\b'       "$file" && guess+=(nano)
    header="${guess[*]}"
  fi

  header="$(echo "$header" | xargs -r)"  # trim
  DEPS_FOR_FILE["$file"]="$header"

  for cmd in $header; do
    command -v "$cmd" >/dev/null 2>&1 || NEEDS["$cmd"]=1
  done
done

# --- offer to install deps ---
missing_cmds=()
for cmd in "${(@k)NEEDS}"; do missing_cmds+=("$cmd"); done

if ((${#missing_cmds[@]} > 0)); then
  echo "🧩 Missing dependencies detected:"
  printf '  - %s\n' "${missing_cmds[@]}"
  pm="$(detect_pm)"

  want_pkgs=()
  case "$pm" in
    pacman)
      for cmd in "${missing_cmds[@]}"; do
        pkg="${CMD2PKG_PACMAN[$cmd]:-}"
        [[ -n "$pkg" ]] && want_pkgs+=("$pkg") || echo "   • (no package map for '$cmd' — install manually)"
      done
      # Remove duplicates
      want_pkgs=($(printf '%s\n' "${want_pkgs[@]}" | awk '!seen[$0]++'))
      if ((${#want_pkgs[@]} > 0)); then
        echo "🛠  Detected Arch Linux (pacman)"
        printf '   Packages: %s\n' "${want_pkgs[*]}"
        read "yn?Install now? [Y/n] "
        if [[ ! "${yn:-Y}" =~ ^[Nn]$ ]]; then
          sudo pacman -S --needed "${want_pkgs[@]}"
        fi
      fi
      ;;
    apt)
      for cmd in "${missing_cmds[@]}"; do
        pkg="${CMD2PKG_APT[$cmd]:-}"
        [[ -n "$pkg" ]] && want_pkgs+=("$pkg") || echo "   • (no package map for '$cmd' — install manually)"
      done
      want_pkgs=($(printf '%s\n' "${want_pkgs[@]}" | awk '!seen[$0]++'))
      if ((${#want_pkgs[@]} > 0)); then
        echo "🛠  Detected Debian/Ubuntu (apt)"
        printf '   Packages: %s\n' "${want_pkgs[*]}"
        read "yn?Install now? [Y/n] "
        if [[ ! "${yn:-Y}" =~ ^[Nn]$ ]]; then
          sudo apt update && sudo apt install -y "${want_pkgs[@]}"
        fi
      fi
      ;;
    dnf)
      for cmd in "${missing_cmds[@]}"; do
        pkg="${CMD2PKG_DNF[$cmd]:-}"
        [[ -n "$pkg" ]] && want_pkgs+=("$pkg") || echo "   • (no package map for '$cmd' — install manually)"
      done
      want_pkgs=($(printf '%s\n' "${want_pkgs[@]}" | awk '!seen[$0]++'))
      if ((${#want_pkgs[@]} > 0)); then
        echo "🛠  Detected Fedora/RHEL (dnf)"
        printf '   Packages: %s\n' "${want_pkgs[*]}"
        read "yn?Install now? [Y/n] "
        if [[ ! "${yn:-Y}" =~ ^[Nn]$ ]]; then
          sudo dnf install -y "${want_pkgs[@]}"
        fi
      fi
      ;;
    *)
      echo "ℹ️  Auto-install not supported for package manager: $pm"
      echo "   Please install the above commands manually."
      ;;
  esac
else
  echo "✅ No missing dependencies."
fi

# --- append selected files (skip if already installed) ---
declare -i installed=0
declare -i skipped=0
: "${installed:=0}"
: "${skipped:=0}"

(( DEBUG )) && echo "DEBUG: About to process ${#PICKED[@]} files for installation"
for file in "${PICKED[@]}"; do
  (( DEBUG )) && echo "DEBUG: Processing file: $file"
  base="${file##*/}"
  if already_installed "$file"; then
    echo "⏭️  $base (already present)"
    skipped=$((skipped + 1))
    continue
  fi
  echo "➕ Installing $base → $ZSHRC"
  {
    echo ""
    echo "$MARK_PREFIX $base (installed $(date -Iseconds))"
    cat "$file"
    echo "$MARK_SUFFIX"
  } >> "$ZSHRC"
  installed=$((installed + 1))
done

echo ""
echo "✅ Done. Installed: $installed  •  Skipped: $skipped"
echo "👉 Run:   source \"$ZSHRC\""
