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
  
  # Install python and pip for VDF manipulation
  if ! command -v python &> /dev/null; then
    log_info "Installing python..."
    sudo pacman -S --needed --noconfirm python
    log_success "Python installed"
  else
    log_info "Python already installed"
  fi
  
  # Install python-vdf for Steam shortcuts manipulation
  log_info "Installing python-vdf library..."
  sudo pacman -S --needed --noconfirm python-vdf || {
    log_error "Could not install python-vdf. Non-Steam game auto-addition will be skipped."
    return 1
  }
  log_success "Python VDF library installed"
  
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

# Create desktop shortcut for manual switching
create_desktop_shortcut() {
  log_info "Creating desktop shortcut for gaming mode..."
  
  mkdir -p "$HOME/.local/share/applications"
  
  cat > "$HOME/.local/share/applications/gaming-mode.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Gaming Mode
Comment=Switch to Steam Big Picture gaming mode
Exec=/usr/local/bin/switch-to-gaming
Icon=steam
Terminal=false
Categories=Game;
Keywords=steam;gaming;big picture;
EOF
  
  log_success "Desktop shortcut created"
}

# Create Python script to add Non-Steam game
create_steam_shortcut_script() {
  log_info "Creating Steam shortcut automation script..."
  
  cat > /tmp/add_steam_shortcut.py << 'EOF'
#!/usr/bin/env python3
"""
Script to automatically add 'Return to Desktop' Non-Steam game to Steam
"""
import vdf
import os
import glob
import struct
import binascii
from pathlib import Path

def find_steam_userdata_path():
  """Find Steam userdata directory"""
  possible_paths = [
    Path.home() / ".steam" / "steam" / "userdata",
    Path.home() / ".steam" / "root" / "userdata", 
    Path.home() / ".local" / "share" / "Steam" / "userdata"
  ]
  
  for path in possible_paths:
    if path.exists():
      # Find user directories (numeric folders)
      user_dirs = [d for d in path.iterdir() if d.is_dir() and d.name.isdigit()]
      if user_dirs:
        # Use the first user directory found
        return user_dirs[0] / "config" / "shortcuts.vdf"
  return None

def calculate_shortcut_id(exe_path, app_name):
  """Calculate shortcut ID for Steam (simplified version)"""
  # This is a simplified approach - Steam's actual algorithm is more complex
  import hashlib
  combined = f"{exe_path}{app_name}"
  hash_obj = hashlib.crc32(combined.encode())
  return hash_obj & 0xffffffff

def add_non_steam_game():
  """Add Return to Desktop as a Non-Steam game"""
  shortcuts_path = find_steam_userdata_path()
  
  if not shortcuts_path:
    print("❌ Could not find Steam shortcuts.vdf file")
    print("   Make sure Steam is installed and you've added at least one Non-Steam game manually")
    return False
  
  if not shortcuts_path.exists():
    print("❌ shortcuts.vdf file doesn't exist")
    print("   Please add at least one Non-Steam game manually through Steam first")
    return False
  
  try:
    # Read existing shortcuts
    with open(shortcuts_path, 'rb') as f:
      shortcuts_data = vdf.binary_load(f)
    
    # Check if our shortcut already exists
    shortcuts = shortcuts_data.get('shortcuts', {})
    for key, shortcut in shortcuts.items():
      if shortcut.get('AppName') == 'Return to Desktop':
        print("✅ 'Return to Desktop' shortcut already exists")
        return True
    
    # Find next available key
    existing_keys = [int(k) for k in shortcuts.keys() if k.isdigit()]
    next_key = str(max(existing_keys) + 1 if existing_keys else 0)
    
    # Create new shortcut entry
    new_shortcut = {
      'AppName': 'Return to Desktop',
      'Exe': '/usr/local/bin/return-to-desktop',
      'StartDir': '/usr/local/bin/',
      'icon': '',
      'ShortcutPath': '',
      'LaunchOptions': '',
      'IsHidden': 0,
      'AllowDesktopConfig': 1,
      'AllowOverlay': 1,
      'OpenVR': 0,
      'Devkit': 0,
      'DevkitGameID': '',
      'DevkitOverrideAppID': 0,
      'LastPlayTime': 0,
      'FlatpakAppID': '',
      'tags': {}
    }
    
    # Calculate appid (this is simplified - Steam's algorithm is complex)
    new_shortcut['appid'] = calculate_shortcut_id('/usr/local/bin/return-to-desktop', 'Return to Desktop')
    
    # Add shortcut to collection
    shortcuts[next_key] = new_shortcut
    shortcuts_data['shortcuts'] = shortcuts
    
    # Backup original file
    backup_path = str(shortcuts_path) + '.backup'
    os.rename(shortcuts_path, backup_path)
    print(f"📁 Backup created: {backup_path}")
    
    # Write updated shortcuts
    with open(shortcuts_path, 'wb') as f:
      vdf.binary_dump(shortcuts_data, f)
    
    print("✅ Successfully added 'Return to Desktop' to Steam Non-Steam games")
    print("   Restart Steam to see the new shortcut")
    return True
    
  except Exception as e:
    print(f"❌ Error adding shortcut: {e}")
    return False

if __name__ == "__main__":
  add_non_steam_game()
EOF
  
  chmod +x /tmp/add_steam_shortcut.py
  log_success "Steam shortcut automation script created"
}

# Try to automatically add the Non-Steam game
add_steam_shortcut_automatically() {
  log_info "Attempting to automatically add 'Return to Desktop' to Steam..."
  
  # Check if Steam is running (shouldn't be during setup)
  if pgrep -f "steam" > /dev/null; then
    log_warning "Steam is currently running. Please close Steam and re-run this script to auto-add the shortcut."
    return 1
  fi
  
  # Run the Python script to add the shortcut
  if python /tmp/add_steam_shortcut.py; then
    log_success "Successfully added 'Return to Desktop' to Steam Non-Steam games!"
    log_info "The shortcut will appear after you restart Steam"
    return 0
  else
    log_warning "Could not automatically add the shortcut. You'll need to add it manually."
    return 1
  fi
}

# Display setup instructions
show_instructions() {
  local auto_shortcut_success=$1
  
  echo ""
  log_success "Gaming mode setup complete!"
  echo ""
  echo -e "${BLUE}How to use:${NC}"
  echo "1. Press Super + F12 to switch to gaming mode"
  
  if [ "$auto_shortcut_success" = "true" ]; then
    echo "2. 'Return to Desktop' has been automatically added to your Steam library"
    echo "   - Restart Steam if it's running to see the new shortcut"
    echo "   - Launch 'Return to Desktop' from Steam Big Picture to return to Hyprland"
  else
    echo "2. In Steam Big Picture, manually add the return shortcut:"
    echo "   - Go to Library"
    echo "   - Click 'Add a Game' → 'Add a Non-Steam Game'"
    echo "   - Click 'Browse' and select: /usr/local/bin/return-to-desktop"
    echo "   - Name it 'Return to Desktop'"
    echo "   - Launch 'Return to Desktop' from Steam to return to Hyprland"
  fi

  echo ""
  echo -e "${YELLOW}Alternative methods:${NC}"
  echo "- Use the 'Gaming Mode' app launcher entry"
  echo "- From terminal: /usr/local/bin/switch-to-gaming"
  echo "- Emergency exit: Ctrl+Alt+F2, then run: pkill -9 gamescope"
  echo ""
  echo -e "${GREEN}Enjoy your Steam Deck-like gaming experience!${NC}"
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
  echo -e "${BLUE}║              Omarchy Gaming Mode Setup Script            ║${NC}"
  echo -e "${BLUE}║          Steam Deck-like gaming mode toggle              ║${NC}"
  echo -e "${BLUE}║        With automatic Non-Steam game integration         ║${NC}"
  echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
  echo ""

  # Check if user wants to proceed
  echo -e "${YELLOW}This script will:${NC}"
  echo "• Install gamescope (if not installed)"
  echo "• Install Python VDF library for Steam integration"
  echo "• Create gaming mode switch scripts"
  echo "• Add Super + F12 keybind to Hyprland"
  echo "• Create desktop shortcut"
  echo "• Automatically add 'Return to Desktop' to Steam (if possible)"
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
  create_desktop_shortcut
  test_scripts
  
  # Try to automatically add Steam shortcut if Steam is available
  auto_shortcut_success=false
  if [ "$steam_available" = "true" ]; then
    create_steam_shortcut_script
    if add_steam_shortcut_automatically; then
      auto_shortcut_success=true
    fi
  fi
  
  show_instructions "$auto_shortcut_success"
  
  # Cleanup temp files
  rm -f /tmp/add_steam_shortcut.py
}

# Run main function
main "$@"