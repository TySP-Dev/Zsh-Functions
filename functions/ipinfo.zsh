## Name: ipinfo
## Desc: Show local IP addresses and public IP
## Usage: ipinfo
## Requires: ip, awk, curl
function ipinfo() {
  echo "🔒 Local IPs:"
  ip -o -4 addr show | awk '{print $2": "$4}'
  echo ""
  echo "🌍 Public IP:"
  curl -s https://api.ipify.org
}
