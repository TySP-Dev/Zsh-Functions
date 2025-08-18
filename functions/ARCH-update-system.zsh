## Name: update-system
## Desc: Updates system packages (pacman), AUR (yay), Flatpak, and Rust crates
## Requires: pacman, yay, flatpak, cargo
function update-system() {
  echo "🔄 Updating system packages (pacman)..."
  sudo pacman -Syu

  echo "📦 Updating AUR packages (yay)..."
  yay -Syu

  echo "📦 Updating Flatpak packages..."
  flatpak update -y

  cargo install-update -a

  echo "✅ System fully updated."
}
