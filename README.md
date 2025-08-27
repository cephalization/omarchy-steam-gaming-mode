# Omarchy Gaming Mode Toggle

A one-command setup script that strives to add a **Steam Deck-like gaming mode** to [Omarchy](https://omarchy.org/) (or any Arch Linux + Hyprland system). Switch seamlessly between your productive Hyprland desktop and an optimized Steam Big Picture gaming environment.

## 🎮 What This Does

- **Toggle between environments**: Press `Super + F12` to instantly switch from Hyprland to Steam Big Picture mode
- **Gaming-optimized**: Uses `gamescope` compositor for better gaming performance and compatibility
- **Zero configuration**: Everything works out of the box after running the script

## ✨ Features

- 🚀 **One-command setup** - Run the script and you're done
- ⌨️ **Keyboard shortcut** - `Super + F12` to switch to gaming mode
- 🔄 **Bi-directional switching** - Easy return to desktop from gaming mode
- 🖥️ **Automatic resolution detection** - Uses your current display resolution and refresh rate

## 📋 Requirements

- **Omarchy** (or Arch Linux + Hyprland)
- **Steam** installed via Omarchy menu (`Super + Alt + Space` → Install → Gaming → Steam)
- Internet connection for downloading dependencies

## 🚀 Installation

### Quick Install
```bash
# Download the script
curl -fsSL https://raw.githubusercontent.com/cephalization/omarchy-steam-gaming-mode/main/setup-gaming-mode.sh -o setup-gaming-mode.sh

# Make it executable and run
chmod +x setup-gaming-mode.sh
./setup-gaming-mode.sh
```

### Manual Install
```bash
git clone https://github.com/cephalization/omarchy-steam-gaming-mode.git
cd omarchy-steam-gaming-mode
chmod +x setup-gaming-mode.sh
./setup-gaming-mode.sh
```

## 🎯 Usage

### Switch to Gaming Mode
- **Keyboard**: Press `Super + F12`
- **Terminal**: Run `/usr/local/bin/switch-to-gaming`

### Return to Desktop
- **From Steam Big Picture**: Press `Super + w` or add the return shortcut to Steam Big Picture as a Non-Steam game
- **Emergency exit**: `Ctrl + Alt + F2`, then run `pkill -9 gamescope`

## 🔧 What Gets Installed

The script automatically:
- Installs `gamescope` (Steam's gaming compositor)
- Creates gaming mode switch scripts in `/usr/local/bin/`
- Adds `Super + F12` keybind to your Hyprland config

## 🛠️ Troubleshooting

### Gaming mode won't start
- Ensure Steam is installed: Install via Omarchy menu first
- Test manually: `gamescope -e -f -W 2880 -H 1920 -r 120 -- steam -tenfoot`
- Check logs: Gaming mode issues are usually gamescope-related

### Can't return to desktop
- Use the emergency exit: `Ctrl + Alt + F2`, then `pkill -9 gamescope`
- Check if the "Return to Desktop" shortcut exists in Steam

## 🎮 Why This Is Awesome

This setup gives you the **best of both worlds**:

- **Hyprland**: Tiling window manager productivity for development and daily tasks
- **Gaming Mode**: Optimized Steam Big Picture experience with better game compatibility

Perfect for developers who want a productive Linux desktop but also enjoy gaming without the hassle of troubleshooting Wayland compatibility issues or suboptimal performance.

## 🤝 Contributing

Issues and pull requests welcome! This script is designed to be simple and reliable.

## 📜 License

MIT License - feel free to use and modify as needed.

## 🙏 Credits

- Inspired by the Steam Deck's seamless desktop/gaming mode switching
- Built for the awesome [Omarchy](https://omarchy.org/) distribution by DHH
- Uses Valve's `gamescope` compositor for optimal gaming performance
