## Name: weather
## Desc: Show current weather for a location (defaults to auto-detect)
## Usage: weather [location]
## Requires: curl
function weather() {
  local location="${1:-}"
  curl -s "wttr.in/${location}?format=3"
}
