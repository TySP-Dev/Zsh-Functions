## Name: net-scan
## Desc: Scan LAN for active devices (uses nmap)
## Usage: net-scan [subnet]
## Requires: ip, awk, nmap
function net-scan() {
  # Find default network interface
  local iface
  iface=$(ip route | awk '/^default/ {print $5; exit}')

  if [[ -z "$iface" ]]; then
    echo "❌ Could not detect default network interface."
    return 1
  fi

  # Get CIDR for that interface
  local subnet
  subnet=$(ip -o -f inet addr show "$iface" | awk '{print $4}' | head -n1)

  if [[ -z "$subnet" ]]; then
    echo "❌ Could not detect subnet for interface $iface."
    return 1
  fi

  echo "🔍 Scanning $subnet on interface $iface..."
  nmap -sn "$subnet"
}
