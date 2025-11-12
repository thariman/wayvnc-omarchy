#!/bin/bash
#
# WayVNC Dual Display Setup Script for Hyprland/Omarchy
# Automated setup for physical + headless VNC displays with Tailscale
#
# Author: Generated from multiple configuration sessions
# Version: 1.0
# Date: 2025-11-12
#
# This script automates the complete setup documented in wayvnc-setup-guide.md
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  $1${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check if running on Arch-based system
check_system() {
    print_header "Checking System Requirements"
    
    if ! command -v pacman &> /dev/null; then
        print_error "This script requires an Arch-based system with pacman"
        exit 1
    fi
    
    if ! pgrep -x Hyprland > /dev/null; then
        print_warning "Hyprland is not currently running"
        print_info "The script will continue, but services won't start until Hyprland is running"
    fi
    
    print_success "System check passed"
}

# Get Tailscale IP address
get_tailscale_ip() {
    print_header "Getting Tailscale IP Address"
    
    if ! command -v tailscale &> /dev/null; then
        print_error "Tailscale is not installed"
        print_info "Please install Tailscale first: https://tailscale.com/download"
        exit 1
    fi
    
    TAILSCALE_IP=$(ip addr show tailscale0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)
    
    if [ -z "$TAILSCALE_IP" ]; then
        print_error "Could not determine Tailscale IP address"
        print_info "Make sure Tailscale is running and connected"
        exit 1
    fi
    
    print_success "Tailscale IP: $TAILSCALE_IP"
}

# Install WayVNC
install_wayvnc() {
    print_header "Installing WayVNC"
    
    if pacman -Q wayvnc &> /dev/null; then
        print_success "WayVNC already installed"
    else
        print_info "Installing WayVNC..."
        sudo pacman -S --noconfirm wayvnc
        print_success "WayVNC installed"
    fi
}

# Create directory structure
create_directories() {
    print_header "Creating Directory Structure"
    
    mkdir -p ~/.config/wayvnc
    mkdir -p ~/.config/systemd/user
    mkdir -p ~/.local/bin
    
    print_success "Directories created"
}

# Create physical display VNC config
create_physical_vnc_config() {
    print_header "Creating Physical Display VNC Configuration"
    
    cat > ~/.config/wayvnc/config << EOF
address=$TAILSCALE_IP
port=5900
enable_auth=false

# Keyboard layout configuration for better VNC compatibility
xkb_layout=us
xkb_rules=evdev
EOF
    
    print_success "Physical VNC config created at ~/.config/wayvnc/config"
}

# Create headless display VNC config
create_headless_vnc_config() {
    print_header "Creating Headless Display VNC Configuration"
    
    cat > ~/.config/wayvnc/config-headless << EOF
address=$TAILSCALE_IP
port=5910
enable_auth=false

# Keyboard layout configuration for better VNC compatibility
xkb_layout=us
xkb_rules=evdev
EOF
    
    print_success "Headless VNC config created at ~/.config/wayvnc/config-headless"
}

# Create headless setup script
create_headless_setup_script() {
    print_header "Creating Headless Display Setup Script"
    
    cat > ~/.local/bin/wayvnc-headless-setup.sh << 'EOF'
#!/bin/bash
# Startup script for WayVNC headless display
# Creates a virtual headless output and starts WayVNC on it

# Wait for Hyprland to be fully ready
sleep 3

# Create headless output
hyprctl output create headless

# Configure headless output to 2732x2048@60Hz (iPad Pro 12.9" landscape resolution)
# The first headless output is named HEADLESS-2
# Scale 2.0 makes text and UI 2x larger (effective resolution 1366x1024)
hyprctl keyword monitor HEADLESS-2,2732x2048@60,auto,2

# Wait a moment for output to be configured
sleep 1

# Assign workspaces 1-5 to the physical display (HDMI-A-1)
hyprctl keyword workspace 1,monitor:HDMI-A-1
hyprctl keyword workspace 2,monitor:HDMI-A-1
hyprctl keyword workspace 3,monitor:HDMI-A-1
hyprctl keyword workspace 4,monitor:HDMI-A-1
hyprctl keyword workspace 5,monitor:HDMI-A-1

# Assign workspaces 6, 7, 8, 9 to the headless display
hyprctl keyword workspace 6,monitor:HEADLESS-2
hyprctl keyword workspace 7,monitor:HEADLESS-2
hyprctl keyword workspace 8,monitor:HEADLESS-2
hyprctl keyword workspace 9,monitor:HEADLESS-2

# Move workspaces to the correct monitors if they're on the wrong one
hyprctl dispatch moveworkspacetomonitor 1 HDMI-A-1 2>/dev/null
hyprctl dispatch moveworkspacetomonitor 2 HDMI-A-1 2>/dev/null
hyprctl dispatch moveworkspacetomonitor 3 HDMI-A-1 2>/dev/null
hyprctl dispatch moveworkspacetomonitor 4 HDMI-A-1 2>/dev/null
hyprctl dispatch moveworkspacetomonitor 5 HDMI-A-1 2>/dev/null
hyprctl dispatch moveworkspacetomonitor 6 HEADLESS-2 2>/dev/null
hyprctl dispatch moveworkspacetomonitor 7 HEADLESS-2 2>/dev/null
hyprctl dispatch moveworkspacetomonitor 8 HEADLESS-2 2>/dev/null
hyprctl dispatch moveworkspacetomonitor 9 HEADLESS-2 2>/dev/null

# Wait a moment for workspace assignment
sleep 1

# Start WayVNC on the headless output
# Use separate socket to avoid conflicts with physical display VNC
wayvnc --config=$HOME/.config/wayvnc/config-headless \
       --socket=/run/user/1000/wayvnc-headless.sock \
       --output=HEADLESS-2
EOF
    
    chmod +x ~/.local/bin/wayvnc-headless-setup.sh
    print_success "Headless setup script created at ~/.local/bin/wayvnc-headless-setup.sh"
}

# Create physical VNC systemd service
create_physical_vnc_service() {
    print_header "Creating Physical VNC Systemd Service"
    
    cat > ~/.config/systemd/user/wayvnc.service << EOF
[Unit]
Description=WayVNC Remote Desktop Server for Wayland
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/wayvnc --config=/home/YOUR_USERNAME/.config/wayvnc/config --socket=/run/user/1000/wayvncctl --output=HDMI-A-1
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
EOF
    
    print_success "Physical VNC service created at ~/.config/systemd/user/wayvnc.service"
}

# Create headless VNC systemd service
create_headless_vnc_service() {
    print_header "Creating Headless VNC Systemd Service"
    
    cat > ~/.config/systemd/user/wayvnc-headless.service << EOF
[Unit]
Description=WayVNC Headless Display Server
After=graphical-session.target wayvnc.service
Requires=graphical-session.target

[Service]
Type=simple
ExecStart=$HOME/.local/bin/wayvnc-headless-setup.sh
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
EOF
    
    print_success "Headless VNC service created at ~/.config/systemd/user/wayvnc-headless.service"
}

# Create window movement helper script
create_helper_script() {
    print_header "Creating Window Movement Helper Script"
    
    cat > ~/.local/bin/move-window-workspace.sh << 'EOF'
#!/bin/bash
# Quick helper script to move active window to a workspace
# Usage: move-window-workspace.sh [workspace_number]
# If no number provided, prompts interactively

if [ $# -eq 1 ]; then
    # Workspace number provided as argument
    workspace=$1
else
    # Interactive mode
    echo "Move active window to workspace:"
    echo "  1-5: Physical display (HDMI-A-1)"
    echo "  6-9: Headless display (HEADLESS-2)"
    echo ""
    read -p "Enter workspace number (1-9): " workspace
fi

# Validate input
if [[ "$workspace" =~ ^[1-9]$ ]]; then
    hyprctl dispatch movetoworkspace "$workspace"
    echo "Moved window to workspace $workspace"
else
    echo "Error: Please enter a number between 1 and 9"
    exit 1
fi
EOF
    
    chmod +x ~/.local/bin/move-window-workspace.sh
    print_success "Helper script created at ~/.local/bin/move-window-workspace.sh"
}

# Add VNC-friendly keybindings to Hyprland
add_keybindings() {
    print_header "Adding VNC-Friendly Keybindings"
    
    BINDINGS_FILE="$HOME/.config/hypr/bindings.conf"
    
    # Check if keybindings already exist
    if grep -q "Super+Alt.*VNC-friendly" "$BINDINGS_FILE" 2>/dev/null; then
        print_warning "VNC-friendly keybindings already exist in $BINDINGS_FILE"
        return
    fi
    
    # Create bindings.conf if it doesn't exist
    if [ ! -f "$BINDINGS_FILE" ]; then
        touch "$BINDINGS_FILE"
    fi
    
    # Add keybindings
    cat >> "$BINDINGS_FILE" << 'EOF'

# Alternative keybindings for VNC compatibility (Super+Alt works better than Super+Shift through VNC)
# These provide an alternative way to move windows to workspaces via VNC
bindd = SUPER ALT, 1, Move window to workspace 1 (VNC-friendly), movetoworkspace, 1
bindd = SUPER ALT, 2, Move window to workspace 2 (VNC-friendly), movetoworkspace, 2
bindd = SUPER ALT, 3, Move window to workspace 3 (VNC-friendly), movetoworkspace, 3
bindd = SUPER ALT, 4, Move window to workspace 4 (VNC-friendly), movetoworkspace, 4
bindd = SUPER ALT, 5, Move window to workspace 5 (VNC-friendly), movetoworkspace, 5
bindd = SUPER ALT, 6, Move window to workspace 6 (VNC-friendly), movetoworkspace, 6
bindd = SUPER ALT, 7, Move window to workspace 7 (VNC-friendly), movetoworkspace, 7
bindd = SUPER ALT, 8, Move window to workspace 8 (VNC-friendly), movetoworkspace, 8
bindd = SUPER ALT, 9, Move window to workspace 9 (VNC-friendly), movetoworkspace, 9
EOF
    
    print_success "VNC-friendly keybindings added to $BINDINGS_FILE"
}

# Update waybar configuration
update_waybar_config() {
    print_header "Updating Waybar Configuration"
    
    WAYBAR_CONFIG="$HOME/.config/waybar/config.jsonc"
    
    if [ ! -f "$WAYBAR_CONFIG" ]; then
        print_warning "Waybar config not found at $WAYBAR_CONFIG, skipping"
        return
    fi
    
    # Check if persistent-workspaces already configured
    if grep -q '"HDMI-A-1": \[1, 2, 3, 4, 5\]' "$WAYBAR_CONFIG" 2>/dev/null; then
        print_success "Waybar persistent-workspaces already configured"
        return
    fi
    
    print_info "Manual waybar configuration recommended"
    print_info "Add this to your waybar config under 'hyprland/workspaces':"
    echo ""
    echo '  "persistent-workspaces": {'
    echo '    "HDMI-A-1": [1, 2, 3, 4, 5],'
    echo '    "HEADLESS-2": [6, 7, 8, 9]'
    echo '  }'
    echo ""
}

# Disable DPMS off in hypridle
disable_dpms() {
    print_header "Disabling DPMS in Hypridle"
    
    HYPRIDLE_CONFIG="$HOME/.config/hypr/hypridle.conf"
    
    if [ ! -f "$HYPRIDLE_CONFIG" ]; then
        print_warning "Hypridle config not found, skipping"
        return
    fi
    
    # Check if already disabled
    if grep -q "#.*on-timeout = hyprctl dispatch dpms off" "$HYPRIDLE_CONFIG"; then
        print_success "DPMS already disabled in hypridle config"
        return
    fi
    
    # Backup original
    cp "$HYPRIDLE_CONFIG" "$HYPRIDLE_CONFIG.backup"
    
    # Comment out DPMS off listener
    sed -i '/on-timeout = hyprctl dispatch dpms off/s/^/# /' "$HYPRIDLE_CONFIG"
    sed -i '/on-resume = hyprctl dispatch dpms on/s/^/# /' "$HYPRIDLE_CONFIG"
    
    print_success "DPMS disabled in hypridle (backup at $HYPRIDLE_CONFIG.backup)"
}

# Enable and start services
enable_services() {
    print_header "Enabling and Starting VNC Services"
    
    systemctl --user daemon-reload
    
    systemctl --user enable wayvnc.service
    systemctl --user enable wayvnc-headless.service
    
    if pgrep -x Hyprland > /dev/null; then
        systemctl --user start wayvnc.service
        systemctl --user start wayvnc-headless.service
        
        sleep 5
        
        # Check if services started successfully
        if systemctl --user is-active --quiet wayvnc.service && \
           systemctl --user is-active --quiet wayvnc-headless.service; then
            print_success "VNC services started successfully"
        else
            print_warning "VNC services may not have started correctly"
            print_info "Check status with: systemctl --user status wayvnc.service"
        fi
    else
        print_warning "Hyprland not running - services enabled but not started"
        print_info "Services will start automatically when you log in to Hyprland"
    fi
}

# Verify setup
verify_setup() {
    print_header "Verifying Setup"
    
    if pgrep -x Hyprland > /dev/null; then
        # Check if ports are listening
        if ss -tlnp 2>/dev/null | grep -q "$TAILSCALE_IP:5900"; then
            print_success "Physical VNC listening on $TAILSCALE_IP:5900"
        else
            print_warning "Physical VNC not listening on port 5900"
        fi
        
        if ss -tlnp 2>/dev/null | grep -q "$TAILSCALE_IP:5910"; then
            print_success "Headless VNC listening on $TAILSCALE_IP:5910"
        else
            print_warning "Headless VNC not listening on port 5910 (may still be starting)"
        fi
    else
        print_info "Hyprland not running - cannot verify VNC ports"
    fi
}

# Print summary
print_summary() {
    print_header "Setup Complete!"
    
    echo ""
    echo -e "${GREEN}✓ WayVNC Dual Display Setup Completed Successfully${NC}"
    echo ""
    echo -e "${BLUE}Connection Details:${NC}"
    echo "  Physical Display:  $TAILSCALE_IP:5900 (workspaces 1-5)"
    echo "  Headless Display:  $TAILSCALE_IP:5910 (workspaces 6-9, iPad Pro optimized)"
    echo ""
    echo -e "${BLUE}Keybindings:${NC}"
    echo "  Switch to workspace:      Super+1 through Super+9"
    echo "  Move window (physical):   Super+Shift+1-9"
    echo "  Move window (VNC):        Super+Alt+1-9  ← Use this from VNC!"
    echo ""
    echo -e "${BLUE}Helper Commands:${NC}"
    echo "  Interactive window move:  move-window-workspace.sh"
    echo "  Direct window move:       move-window-workspace.sh 6"
    echo "  Manual command:           hyprctl dispatch movetoworkspace 6"
    echo ""
    echo -e "${BLUE}Service Management:${NC}"
    echo "  Check status:    systemctl --user status wayvnc.service"
    echo "  Check headless:  systemctl --user status wayvnc-headless.service"
    echo "  Restart:         systemctl --user restart wayvnc.service"
    echo "  View logs:       journalctl --user -u wayvnc.service -f"
    echo ""
    echo -e "${BLUE}Files Created:${NC}"
    echo "  ~/.config/wayvnc/config"
    echo "  ~/.config/wayvnc/config-headless"
    echo "  ~/.config/systemd/user/wayvnc.service"
    echo "  ~/.config/systemd/user/wayvnc-headless.service"
    echo "  ~/.local/bin/wayvnc-headless-setup.sh"
    echo "  ~/.local/bin/move-window-workspace.sh"
    echo "  ~/.config/hypr/bindings.conf (updated)"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "  1. If Hyprland was not running, log in to start the services"
    echo "  2. Connect from your iPad VNC client to test both displays"
    echo "  3. Try Super+Alt+6-9 keybindings from VNC"
    echo "  4. Check the full documentation: ~/remoteHyprland/wayvnc-setup-guide.md"
    echo ""
}

# Main execution
main() {
    echo ""
    print_header "WayVNC Dual Display Setup for Hyprland/Omarchy"
    echo ""
    
    check_system
    get_tailscale_ip
    install_wayvnc
    create_directories
    create_physical_vnc_config
    create_headless_vnc_config
    create_headless_setup_script
    create_physical_vnc_service
    create_headless_vnc_service
    create_helper_script
    add_keybindings
    update_waybar_config
    disable_dpms
    enable_services
    verify_setup
    print_summary
}

# Run main function
main
