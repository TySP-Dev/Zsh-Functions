## Name: killport
## Desc: Kill the process listening on a given port
## Usage: killport <port>
## Requires: (lsof, ss, or netstat)
function killport() {
  if [[ -z "$1" ]]; then
    echo "Usage: killport <port>"
    return 1
  fi

  local port="$1"
  local pids=()

  # Try lsof first (most common)
  if command -v lsof >/dev/null 2>&1; then
    pids=(${(f)"$(sudo lsof -t -i tcp:"$port" 2>/dev/null)"})
  # Try ss (modern Linux)
  elif command -v ss >/dev/null 2>&1; then
    pids=(${(f)"$(sudo ss -lptn "sport = :$port" 2>/dev/null | awk 'NR>1 {match($0, /pid=([0-9]+)/, arr); if(arr[1]) print arr[1]}')"})
  # Try netstat (fallback)
  elif command -v netstat >/dev/null 2>&1; then
    pids=(${(f)"$(sudo netstat -tulpn 2>/dev/null | grep ":$port " | awk '{match($0, /([0-9]+)\//, arr); if(arr[1]) print arr[1]}')"})
  else
    echo "❌ No suitable tool found (lsof, ss, or netstat required)"
    return 1
  fi

  if (( ${#pids} == 0 )); then
    echo "ℹ️  No process found on port $port"
    return 0
  fi

  # Remove duplicates
  pids=(${(u)pids})

  echo "🛑 Killing ${#pids} process(es) on port $port..."
  for pid in "${pids[@]}"; do
    sudo kill -9 "$pid" 2>/dev/null && echo "   ✓ Killed PID $pid"
  done
}
