## Name: find-port
## Desc: Find processes using a specific port
## Usage: find-port <port>
## Requires: (lsof, ss, or netstat)
function find-port() {
  if [[ -z "$1" ]]; then
    echo "Usage: find-port <port>"
    return 1
  fi

  local port="$1"

  # Try lsof first (most detailed)
  if command -v lsof >/dev/null 2>&1; then
    sudo lsof -i :"$port"
  # Try ss (modern Linux)
  elif command -v ss >/dev/null 2>&1; then
    echo "🔍 Processes using port $port:"
    sudo ss -lptn "sport = :$port"
  # Try netstat (fallback)
  elif command -v netstat >/dev/null 2>&1; then
    echo "🔍 Processes using port $port:"
    sudo netstat -tulpn | grep ":$port "
  else
    echo "❌ No suitable tool found (lsof, ss, or netstat required)"
    return 1
  fi
}
