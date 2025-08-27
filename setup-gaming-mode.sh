#!/bin/bash

# Omarchy Steam Gaming Mode Setup Script
# This script sets up a Steam Deck-like gaming mode toggle for Omarchy systems

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on Omarchy/Arch with Hyprland
check_system() {
  log_info "Checking system compatibility..."
  
  # Check if we're on Arch Linux
  if ! command -v pacman &> /dev/null; then
    log_error "This script requires Arch Linux (pacman not found)"
    exit 1
  fi
  
  # Check if Hyprland is installed
  if ! command -v hyprctl &> /dev/null; then
    log_error "Hyprland is not installed or not in PATH"
    exit 1
  fi
  
  # Check if Hyprland config exists
  if [ ! -f "$HOME/.config/hypr/hyprland.conf" ]; then
    log_error "Hyprland configuration file not found at ~/.config/hypr/hyprland.conf"
    exit 1
  fi
  
  log_success "System compatibility verified"
}

# Install dependencies
install_dependencies() {
  log_info "Installing gaming dependencies..."
  
  # Install gamescope if not already installed
  if ! command -v gamescope &> /dev/null; then
    log_info "Installing gamescope..."
    sudo pacman -S --needed --noconfirm gamescope
    log_success "Gamescope installed"
  else
    log_info "Gamescope already installed"
  fi
  
  # Check if Steam is installed
  if ! command -v steam &> /dev/null; then
    log_warning "Steam is not installed!"
    log_info "Please install Steam via Omarchy menu (Super + Alt + Space -> Install -> Gaming -> Steam)"
    log_info "Then re-run this script for full functionality."
    echo -n "Do you want to continue anyway? (y/N): "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
      log_info "Exiting. Install Steam first, then re-run this script."
      exit 1
    fi
    return 1
  else
    log_success "Steam is already installed"
    return 0
  fi

  # Install mangohud
  if ! command -v mangohud &> /dev/null; then
    log_info "Installing mangohud..."
    sudo pacman -S --needed --noconfirm mangohud
    log_success "Mangohud installed"
  else
    log_info "Mangohud already installed"
  fi
}

# Create gaming mode switch script
create_gaming_script() {
  log_info "Creating gaming mode switch script..."
  
  sudo tee /usr/local/bin/switch-to-gaming > /dev/null << 'EOF'
#!/bin/bash
# Launch gaming mode with current display resolution and refresh rate

# Get current display info from Hyprland
get_display_info() {
  local monitors_info
  monitors_info=$(hyprctl monitors -j 2>/dev/null)
  
  if [ -z "$monitors_info" ]; then
    echo "Warning: Could not get monitor info from Hyprland, using defaults" >&2
    echo "1920 1080 60"
    return
  fi
  
  # Parse JSON to get the focused/primary monitor info
  # Get width, height, and refresh rate from the first active monitor
  local width height refresh
  width=$(echo "$monitors_info" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    if data and len(data) > 0:
        print(int(data[0]['width']))
    else:
        print(1920)
except:
    print(1920)
" 2>/dev/null || echo "1920")
  
  height=$(echo "$monitors_info" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    if data and len(data) > 0:
        print(int(data[0]['height']))
    else:
        print(1080)
except:
    print(1080)
" 2>/dev/null || echo "1080")
  
  refresh=$(echo "$monitors_info" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    if data and len(data) > 0:
        # Round refresh rate to nearest integer
        print(int(round(data[0]['refreshRate'])))
    else:
        print(60)
except:
    print(60)
" 2>/dev/null || echo "60")
  
  echo "$width $height $refresh"
}

# Get current display configuration
read -r WIDTH HEIGHT REFRESH <<< "$(get_display_info)"

echo "Using display configuration: ${WIDTH}x${HEIGHT}@${REFRESH}Hz"

# Launch gamescope as nested session with current display settings
exec /usr/bin/gamescope --mangoapp -f -W "$WIDTH" -H "$HEIGHT" -r "$REFRESH" -e -- /usr/bin/steam -tenfoot
EOF
  
  sudo chmod +x /usr/local/bin/switch-to-gaming
  log_success "Gaming mode switch script created at /usr/local/bin/switch-to-gaming"
}

# Create return to desktop script
create_return_script() {
  log_info "Creating return to desktop script..."
  
  sudo tee /usr/local/bin/return-to-desktop > /dev/null << 'EOF'
#!/bin/bash
# Kill gamescope/steam and return to Hyprland
pkill -9 gamescope
EOF
  
  sudo chmod +x /usr/local/bin/return-to-desktop
  log_success "Return to desktop script created at /usr/local/bin/return-to-desktop"
}

# Add keybind to Hyprland config
add_hyprland_keybind() {
  log_info "Adding gaming mode keybind to Hyprland config..."
  
  local config_file="$HOME/.config/hypr/bindings.conf"
  local keybind="bind = SUPER, F12, exec, /usr/local/bin/switch-to-gaming"

  # check if the file exists
  if [ ! -f "$config_file" ]; then
    log_error "Hyprland config file not found at $config_file"
    log_info "Trying $HOME/.config/hypr/hyprland.conf"
    config_file="$HOME/.config/hypr/hyprland.conf"
    if [ ! -f "$config_file" ]; then
      log_error "Hyprland config file not found at $config_file"
      exit 1
    fi
  fi
  
  # Check if keybind already exists
  if grep -q "switch-to-gaming" "$config_file"; then
    log_info "Gaming mode keybind already exists in Hyprland config"
  else
    # Add keybind to config file
    echo "" >> "$config_file"
    echo "# Gaming mode toggle keybind (added by setup script)" >> "$config_file"
    echo "$keybind" >> "$config_file"
    log_success "Gaming mode keybind added (Super + F12)"
  fi
}

# Display setup instructions
show_instructions() {
  echo ""
  log_success "Gaming mode setup complete!"
  echo ""
  echo -e "${BLUE}How to use:${NC}"
  echo "1. Press Super + F12 to switch to gaming mode"
  echo "2. Press Super + w to return to desktop"
  echo "Or, add the return shortcut to Steam Big Picture as a Non-Steam game"
  echo "   - Go to Library"
  echo "   - Click 'Add a Game' → 'Add a Non-Steam Game'"
  echo "   - Click 'Browse' and select: /usr/local/bin/return-to-desktop"
  echo "   - Name it 'Return to Desktop'"
  echo "   - Launch 'Return to Desktop' from Steam to return to Hyprland"

  echo ""
  echo -e "${YELLOW}Alternative methods:${NC}"
  echo "- From terminal: /usr/local/bin/switch-to-gaming"
  echo "- Emergency exit: Ctrl+Alt+F2, then run: pkill -9 gamescope"
  echo ""
  echo -e "${GREEN}Enjoy your enhanced gaming experience!${NC}"
}

# Test scripts
test_scripts() {
  log_info "Testing script permissions and executability..."

  if [ -x "/usr/local/bin/switch-to-gaming" ]; then
    log_success "Gaming mode script is executable"
  else
    log_error "Gaming mode script is not executable"
    exit 1
  fi

  if [ -x "/usr/local/bin/return-to-desktop" ]; then
    log_success "Return to desktop script is executable"
  else
    log_error "Return to desktop script is not executable"
    exit 1
  fi
}

# Main execution
main() {
  echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║               Omarchy Gaming Mode Setup Script            ║${NC}"
  echo -e "${BLUE}║            Gaming mode toggle for enhanced gaming         ║${NC}"
  echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
  echo ""

  # Check if user wants to proceed
  echo -e "${YELLOW}This script will:${NC}"
  echo "• Install gamescope (if not installed)"
  echo "• Create gaming mode switch scripts"
  echo "• Add Super + F12 keybind to Hyprland"
  echo ""
  echo -n "Do you want to proceed? (Y/n): "
  read -r response
  if [[ "$response" =~ ^[Nn]$ ]]; then
    log_info "Setup cancelled by user"
    exit 0
  fi
  
  # Run setup steps
  check_system
  
  # Try to install dependencies, track Steam availability
  steam_available=false
  if install_dependencies; then
    steam_available=true
  fi
  
  create_gaming_script
  create_return_script
  add_hyprland_keybind
  test_scripts

  show_instructions
}

# Run main function
main "$@"