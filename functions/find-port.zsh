## Name: find-port
## Desc: Find processes using a specific port
## Usage: find-port <port>
## Requires: lsof
function find-port() {
  if [ -z "$1" ]; then
    echo "Usage: find-port <port>"
    return 1
  fi
  sudo lsof -i :"$1"
}
