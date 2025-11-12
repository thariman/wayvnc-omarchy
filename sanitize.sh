#!/bin/bash
# Sanitize files by removing identifiable information

# Replace patterns
sed -i 's/100\.96\.206\.82/YOUR_TAILSCALE_IP/g' "$1"
sed -i 's/TSH-Omarchy/YOUR_HOSTNAME/g' "$1"
sed -i 's/thariman/YOUR_USERNAME/g' "$1"
sed -i 's/\/home\/thariman/\/home\/YOUR_USERNAME/g' "$1"
sed -i 's/%h/\/home\/YOUR_USERNAME/g' "$1"
sed -i 's/user-1000/user-YOUR_UID/g' "$1"

echo "Sanitized: $1"
