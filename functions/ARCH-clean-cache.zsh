## Name: clean-cache
## Desc: Clean pacman, yay, and Flatpak caches
## Usage: clean-cache
## Requires: paccache, yay, flatpak
function clean-cache() {
  echo "🧹 Cleaning pacman cache..."
  sudo paccache -r

  echo "🧹 Cleaning yay cache..."
  yay -Sc --noconfirm

  echo "🧹 Cleaning Flatpak cache..."
  flatpak uninstall --unused -y
}
