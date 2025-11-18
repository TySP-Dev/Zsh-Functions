## Name: ipinfo
## Desc: Show local IP addresses and public IP
## Usage: ipinfo
## Requires: (ip, ifconfig, or ipconfig), curl
function ipinfo() {
  echo "🔒 Local IPs:"

  # Try ip command (modern Linux)
  if command -v ip >/dev/null 2>&1; then
    ip -o -4 addr show | awk '{print $2": "$4}'
  # Try ifconfig (macOS, BSD, older Linux)
  elif command -v ifconfig >/dev/null 2>&1; then
    ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'
  # Try ipconfig (Windows via WSL)
  elif command -v ipconfig.exe >/dev/null 2>&1; then
    ipconfig.exe | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'
  else
    echo "   ❌ No suitable tool found (ip, ifconfig, or ipconfig required)"
  fi

  echo ""
  echo "🌍 Public IP:"

  # Try multiple services in case one is down
  if command -v curl >/dev/null 2>&1; then
    curl -s --max-time 5 https://api.ipify.org || \
    curl -s --max-time 5 https://ifconfig.me || \
    curl -s --max-time 5 https://icanhazip.com || \
    echo "❌ Could not fetch public IP"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- --timeout=5 https://api.ipify.org || \
    wget -qO- --timeout=5 https://ifconfig.me || \
    wget -qO- --timeout=5 https://icanhazip.com || \
    echo "❌ Could not fetch public IP"
  else
    echo "❌ curl or wget required to fetch public IP"
  fi
  echo ""
}
