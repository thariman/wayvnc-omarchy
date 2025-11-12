# Security Considerations

## ⚠️ Important Security Warnings

This setup is designed for **personal use within a trusted Tailscale network**. Please carefully review the following security considerations before deploying:

### 1. VNC Protocol Security

**CRITICAL**: This configuration **disables VNC authentication** (`enable_auth=false`)

- ✅ **Acceptable when**: VNC is bound to Tailscale IP only (not accessible outside your private network)
- ❌ **NOT SAFE when**: VNC is exposed to local network, internet, or untrusted networks
- 🔐 **Recommendation**: Always verify VNC is bound to your Tailscale IP, never `0.0.0.0` or `127.0.0.1`

```bash
# Verify VNC is only listening on Tailscale IP
ss -tlnp | grep -E "5900|5910"
# Should show YOUR_TAILSCALE_IP:5900 and YOUR_TAILSCALE_IP:5910
# Should NOT show 0.0.0.0:5900 or similar
```

### 2. Tailscale Dependency

**This setup relies entirely on Tailscale for security:**

- VNC traffic is encrypted by Tailscale's WireGuard VPN
- Access is limited to devices on your Tailscale network (tailnet)
- **If Tailscale is compromised or misconfigured, your VNC is exposed**

**Verify Tailscale security:**
```bash
# Check Tailscale is running and connected
tailscale status

# Verify your Tailscale IP hasn't changed
tailscale ip -4

# Review which devices can access your machine
tailscale status | grep -v "^#"
```

### 3. No Screen Lock Protection

**CRITICAL**: VNC sessions survive screen lock (by design)

- This configuration **disables DPMS** (Display Power Management)
- Remote users can view and control your desktop even when locked
- ✅ **Acceptable for**: Personal machines, trusted remote access scenarios
- ❌ **NOT SAFE for**: Shared workstations, corporate environments, untrusted networks

**If you need lock screen protection:**
- Do NOT use this configuration as-is
- Re-enable DPMS in `~/.config/hypr/hypridle.conf`
- Accept that VNC will disconnect when screen locks

### 4. Systemd Auto-Start

**Services start automatically on login:**

- VNC servers run as soon as you log in
- They restart automatically if they crash
- They start before you can review or disable them

**To disable auto-start:**
```bash
systemctl --user disable wayvnc.service wayvnc-headless.service
```

### 5. Headless Display Considerations

**The headless display (HEADLESS-2) is always active:**

- Creates a virtual monitor that's always "on"
- Any application can render to this monitor
- Remote users with VNC access can see everything on this display
- Consider what sensitive information might appear on workspaces 6-9

### 6. No Logging or Access Control

**This setup does NOT include:**

- ❌ VNC access logging
- ❌ Failed connection attempt tracking
- ❌ Rate limiting or brute-force protection
- ❌ Per-user access control
- ❌ Session recording or audit trails

**Mitigation**: These protections are provided by Tailscale ACLs and audit logs

### 7. Clipboard Sharing

**VNC shares clipboard between client and server:**

- Sensitive data in clipboard is transmitted over VNC
- Data passes through Tailscale (encrypted) but is visible to VNC client
- Consider what passwords, API keys, or secrets you copy/paste

### 8. Keyboard Input Exposure

**All keyboard input is transmitted over VNC:**

- Passwords typed in VNC sessions travel over the network
- Encrypted by Tailscale, but vulnerable if Tailscale is compromised
- Use password managers with auto-fill when possible

## Security Best Practices

### ✅ Do This:

1. **Verify Tailscale binding** every time you run the setup script
2. **Review Tailscale ACLs** to control which devices can access your machine
3. **Keep Tailscale updated** for latest security patches
4. **Use strong authentication** for your Linux user account
5. **Enable full disk encryption** (LUKS) to protect data at rest
6. **Review logs regularly**: `journalctl --user -u wayvnc.service -f`
7. **Understand what's on workspaces 6-9** (headless display) before connecting

### ❌ Don't Do This:

1. **Never bind VNC to `0.0.0.0`** or your LAN IP address
2. **Never expose ports 5900/5910** to the internet directly
3. **Never use this on untrusted networks** without reviewing security
4. **Never assume Tailscale alone is sufficient** for highly sensitive environments
5. **Never run this on multi-user systems** without additional access controls
6. **Don't leave VNC running** if you're not actively using it

## Network Architecture

```
[iPad/Mac Client]
       ↓
   Tailscale VPN (WireGuard encrypted)
       ↓
[Linux Machine: YOUR_TAILSCALE_IP]
       ↓
  WayVNC (no auth, bound to Tailscale IP only)
       ↓
[Hyprland Compositor]
       ↓
[Physical Display (HDMI-A-1) + Headless Display (HEADLESS-2)]
```

## Threat Model

### Protected Against:
- ✅ External attackers (not on your tailnet)
- ✅ Local network snooping (traffic encrypted by Tailscale)
- ✅ Casual eavesdropping (requires Tailscale authentication)

### NOT Protected Against:
- ❌ Compromised Tailscale account
- ❌ Malicious devices on your tailnet
- ❌ Physical access to your machine
- ❌ Compromised Tailscale infrastructure
- ❌ Root/sudo access on your Linux machine
- ❌ Malware running as your user

## Compliance Considerations

**This setup is likely NOT suitable for:**
- Corporate environments with security policies
- HIPAA/PCI/SOC2 compliance requirements
- Multi-tenant environments
- Systems handling sensitive customer data
- Environments requiring audit trails

**This setup MAY be suitable for:**
- Personal home labs
- Development/testing environments
- Trusted single-user systems
- Non-production workstations

## Incident Response

**If you suspect unauthorized VNC access:**

1. **Immediately stop VNC services:**
   ```bash
   systemctl --user stop wayvnc.service wayvnc-headless.service
   ```

2. **Check for active VNC connections:**
   ```bash
   ss -tnp | grep -E "5900|5910"
   ```

3. **Review Tailscale audit logs:**
   ```bash
   tailscale status
   # Check web admin at https://login.tailscale.com/admin/machines
   ```

4. **Review system logs for suspicious activity:**
   ```bash
   journalctl --user -u wayvnc.service --since "1 hour ago"
   ```

5. **Rotate Tailscale keys:**
   ```bash
   tailscale logout
   tailscale login
   ```

## Updates and Maintenance

**Security maintenance checklist:**

- [ ] Update Tailscale regularly: `sudo pacman -Syu tailscale`
- [ ] Update WayVNC regularly: `sudo pacman -Syu wayvnc`
- [ ] Update Hyprland regularly: `sudo pacman -Syu hyprland`
- [ ] Review Tailscale device list monthly
- [ ] Review VNC logs for anomalies
- [ ] Test emergency stop procedure quarterly

## Reporting Security Issues

If you discover a security vulnerability in this configuration:

1. **Do NOT** open a public GitHub issue
2. Email the repository maintainer privately
3. Include steps to reproduce and potential impact
4. Allow reasonable time for fix before public disclosure

## Additional Resources

- [Tailscale Security](https://tailscale.com/security/)
- [WayVNC Documentation](https://github.com/any1/wayvnc)
- [Hyprland Security](https://wiki.hyprland.org/)
- [VNC Security Best Practices](https://en.wikipedia.org/wiki/Virtual_Network_Computing#Security)

---

**Last Updated**: 2025-11-12
**Security Review**: This is a personal configuration. Professional security audit recommended for production use.

## Disclaimer

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND. Use at your own risk.
The authors assume no liability for security breaches, data loss, or unauthorized access
resulting from the use of this configuration.

**By using this setup, you acknowledge that:**
- You understand the security implications
- You accept full responsibility for your system's security
- You will implement additional controls as needed for your environment
- You will not hold the authors liable for any security incidents
