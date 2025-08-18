## Name: killport
## Desc: Kill the process listening on a given port
## Usage: killport <port>
## Requires: lsof, xargs
function killport() {
  if [[ -z "$1" ]]; then
    echo "Usage: killport <port>"
    return 1
  fi
  sudo lsof -t -i tcp:"$1" | xargs -r sudo kill -9
  echo "🛑 Killed process on port $1"
}
