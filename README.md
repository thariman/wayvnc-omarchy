# WayVNC Dual Display Setup for Hyprland

Complete remote desktop solution for Hyprland/Omarchy with dual VNC displays optimized for iPad Pro access via Tailscale.

## Quick Start

### Automated Setup (Recommended)

```bash
cd ~/remoteHyprland
./setup-wayvnc-dual-display.sh
```

This script will:
- Install WayVNC
- Configure dual VNC displays (physical + headless)
- Set up systemd services
- Add VNC-friendly keybindings
- Create helper scripts
- Enable auto-start on login

### Manual Setup

See [wayvnc-setup-guide.md](wayvnc-setup-guide.md) for detailed step-by-step instructions.

## Features

✅ **Dual VNC Setup**
- Port 5900: Physical display (4K, workspaces 1-5)
- Port 5910: Headless display (iPad Pro 12.9" optimized, workspaces 6-9)

✅ **VNC-Friendly Keybindings**
- `Super+Alt+1-9`: Move windows (works from VNC)
- `Super+Shift+1-9`: Move windows (physical keyboard only)
- `Super+1-9`: Switch workspaces (works everywhere)

✅ **Security**
- Tailscale-only access (bound to Tailscale IP)
- No authentication needed (secured by Tailscale)
- Not exposed to local network or internet

✅ **Optimized for iPad Pro 12.9"**
- Native resolution: 2732x2048 (landscape)
- 2x scaling for readable text (effective 1366x1024)
- Perfect pixel-perfect display

✅ **Production Ready**
- Auto-starts on login (systemd services)
- Survives screen lock
- Restarts on failure
- Workspace persistence

## Connection Details

| Display | Address | Resolution | Workspaces |
|---------|---------|------------|------------|
| Physical | `tailscale-ip:5900` | 3840x2160 | 1-5 |
| Headless | `tailscale-ip:5910` | 2732x2048@2x | 6-9 |

Replace `tailscale-ip` with your actual Tailscale IP (found with `tailscale ip`).

## Usage

### Connecting from iPad/Mac

**VNC Viewer (RealVNC)**
1. Add connection: `YOUR_TAILSCALE_IP:5900` (physical) or `:5910` (headless)
2. No password required
3. Connect and enjoy!

### Keybindings

**From VNC (iPad/Mac):**
- `Super+6-9`: Switch to workspaces 6-9 on headless display
- `Super+Alt+6-9`: Move active window to workspaces 6-9

**From Physical Keyboard:**
- Both `Super+Shift` and `Super+Alt` work for moving windows

### Helper Scripts

```bash
# Interactive window movement
move-window-workspace.sh

# Direct window movement
move-window-workspace.sh 6

# Manual command
hyprctl dispatch movetoworkspace 6
```

## Service Management

```bash
# Check status
systemctl --user status wayvnc.service
systemctl --user status wayvnc-headless.service

# Restart services
systemctl --user restart wayvnc.service
systemctl --user restart wayvnc-headless.service

# View logs
journalctl --user -u wayvnc.service -f
journalctl --user -u wayvnc-headless.service -f

# Stop services
systemctl --user stop wayvnc.service wayvnc-headless.service

# Disable auto-start
systemctl --user disable wayvnc.service wayvnc-headless.service
```

## Files Created

```
~/.config/wayvnc/
├── config                          # Physical display VNC config
└── config-headless                 # Headless display VNC config

~/.config/systemd/user/
├── wayvnc.service                  # Physical VNC service
└── wayvnc-headless.service         # Headless VNC service

~/.local/bin/
├── wayvnc-headless-setup.sh       # Headless display setup script
└── move-window-workspace.sh        # Window movement helper

~/.config/hypr/
├── bindings.conf                   # Custom keybindings (updated)
└── hyprland.conf                   # Main config (workspace rules commented)

~/remoteHyprland/
├── README.md                       # This file
├── wayvnc-setup-guide.md          # Complete documentation
└── setup-wayvnc-dual-display.sh   # Automated setup script
```

## Troubleshooting

### VNC Not Connecting

```bash
# Check if services are running
systemctl --user status wayvnc.service wayvnc-headless.service

# Check if ports are listening
ss -tlnp | grep -E "5900|5910"

# Check Tailscale connection
tailscale status

# Restart services
systemctl --user restart wayvnc.service wayvnc-headless.service
```

### Physical Display Won't Turn On

Check if static workspace assignments are commented in `~/.config/hypr/hyprland.conf`:

```bash
grep "^workspace" ~/.config/hypr/hyprland.conf
```

Should return nothing or all lines starting with `#`. If not:
```bash
# Comment out workspace assignments
sed -i '/^workspace/s/^/#/' ~/.config/hypr/hyprland.conf

# Reboot
sudo reboot
```

### Keybindings Not Working from VNC

**Problem**: `Super+Shift+6-9` doesn't work from VNC

**Solution**: Use `Super+Alt+6-9` instead (VNC-friendly alternative)

If `Super+Alt` also doesn't work:
1. Check keybindings were added: `grep "SUPER ALT" ~/.config/hypr/bindings.conf`
2. Log out and log back in to reload keybindings
3. Use helper script: `move-window-workspace.sh 6`

### Workspace Numbering Issues

Workspaces are assigned dynamically by the headless setup script. If you see wrong numbers:

```bash
# Restart headless service
systemctl --user restart wayvnc-headless.service

# Check workspace assignments
hyprctl workspaces | grep -E "workspace ID|Monitor"
```

## Development Sessions Summary

This setup is the result of 6 debugging and configuration sessions:

1. **Session 1**: Initial WayVNC setup, fixed authentication issues
2. **Session 2**: Fixed VNC disconnection on screen lock (DPMS issue)
3. **Session 3**: Added headless display with iPad Pro resolution
4. **Session 4**: Configured workspace organization and waybar
5. **Session 5**: Fixed critical Hyprland startup failure (static workspace assignments)
6. **Session 6**: **SOLVED VNC keyboard issue** - discovered `Super+Alt` works while `Super+Shift` doesn't

## Key Discoveries

### VNC Keyboard Limitation
- **Issue**: `Super+Shift+Number` doesn't work through VNC
- **Cause**: VNC protocol's Shift modifier translation limitation
- **Solution**: Use `Super+Alt+Number` instead (works perfectly!)
- **Research**: Comprehensive investigation using debugging tools and documentation

### Hyprland Workspace Assignment
- **Issue**: Static workspace assignments prevented Hyprland startup
- **Cause**: Workspaces assigned to HEADLESS-2 before monitor existed
- **Solution**: Dynamic assignment only (in headless setup script)

### XKB Keyboard Configuration
- **Discovery**: Explicit keyboard layout improves VNC compatibility
- **Implementation**: Added `xkb_layout=us` and `xkb_rules=evdev` to WayVNC configs

## Credits

- WayVNC: https://github.com/any1/wayvnc
- Hyprland: https://hyprland.org/
- Omarchy: https://github.com/basecamp/omarchy
- Tailscale: https://tailscale.com/

### Development Attribution

This project was co-created with **Claude Code** by Anthropic.

- **AI Assistant**: Claude (Sonnet 4.5 model: `claude-sonnet-4-5-20250929`)
- **Tool**: [Claude Code](https://docs.claude.com/claude-code) v2.0.37 - AI-powered CLI for software development
- **Development Period**: November 11-12, 2025
- **Sessions**: 6 debugging and configuration sessions over 2 days
- **Active Interaction Time**: ~170-190 minutes (~3 hours total)
- **Contribution**: Research, debugging, configuration, documentation, and automation

All code, configurations, and documentation were developed collaboratively through iterative problem-solving and testing.

## License

Configuration files and scripts in this directory are provided as-is for personal use.

## Support

For issues or questions:
1. Check [wayvnc-setup-guide.md](wayvnc-setup-guide.md) troubleshooting section
2. Review service logs: `journalctl --user -u wayvnc.service -f`
3. Check Hyprland logs: `cat $XDG_RUNTIME_DIR/hypr/*/hyprland.log`

---

**Last Updated**: 2025-11-12  
**Status**: ✅ Fully Working - All Features Operational
