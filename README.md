# DNSaaS Installer for Ubuntu

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%20%7C%2024.04-orange.svg)](https://ubuntu.com/)
[![GitHub](https://img.shields.io/badge/GitHub-ossza%2Fdnsaas-blue.svg)](https://github.com/ossza/dnsaas)

One-click installer for DNS-over-HTTPS (DoH) with token-based authentication using `https_dns_proxy`. http_dns_proxy can be found here: https://github.com/aarond10/https_dns_proxy
This guide will help you configure your Ubuntu system to use secure, encrypted DNS with token-based authentication.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [One-Click Install](#one-click-install)
- [Clean Install](#clean-install)
- [Manual Installation](#manual-installation)
- [Uninstall / Cleanup](#uninstall--cleanup)
- [Service Management](#service-management)
- [Testing Your Configuration](#testing-your-configuration)
- [Troubleshooting](#troubleshooting)
- [GitHub Resources](#github-resources)
- [License](#license)
- [Third-Party Software](#third-party-software)

---
# 🐧 Configure Ubuntu for Secure DNSaaS

Complete guide to configure your Ubuntu system to use DNS-over-HTTPS (DoH) with token-based authentication using **https_dns_proxy**.

**Ubuntu 22.04 LTS / 24.04 LTS** · ✅ Verified Working · 🔒 DoH + Token Auth · 🐙 [github.com/ossza/dnsaas](https://github.com/ossza/dnsaas)

---

## 📋 Overview

Our DNSaaS service uses **DNS-over-HTTPS (DoH)** with **token-based authentication** for maximum privacy and security. This guide will help you configure your Ubuntu system to use this service for **all DNS resolution** system-wide.

| Service | Endpoint | Authentication |
|---------|----------|----------------|
| **Primary DNS** | `https://dns1.oss.co.za/token_xxxxx` | Token in URL path |
| **Protocol** | DNS-over-HTTPS (DoH) · Port 443 · TLS 1.3 | |
| **Proxy** | `https_dns_proxy` listening on `127.0.0.1:53` | |
| **Fallback** | ✅ 1.1.1.1 · ✅ 8.8.8.8 (if service unreachable) | |

> ✅ **Verified Working**  
> This configuration has been tested and confirmed working on Ubuntu 22.04 LTS and 24.04 LTS with **https_dns_proxy**.

---

## ✅ Prerequisites

- **Ubuntu 22.04 LTS** or **24.04 LTS**
- **Your token:** `token_xxxxxxxxxx` (provided by DNSaaS administrator)
- Administrative (sudo) access
- Internet connectivity
- About **20 MB** of free disk space

> 💡 **Token Format**  
> Your token is provided by the DNSaaS administrator. It looks like: `token_xxxxxxxxxx`. Keep it secure!

---

## 🚀 One-Click Install (Recommended)

The quickest way to get started. Copy and paste these commands to install and configure everything automatically.

> ✨ **What This Does**
> - Installs build dependencies and `https_dns_proxy`
> - Configures the proxy with your token
> - Sets up a systemd service for persistence
> - Configures system DNS to use the proxy
> - Tests the installation

```bash
# Download and run the installer from GitHub
# Replace TOKEN with your actual token
TOKEN="token_testclient123"  # ⚠️ Change this!

wget https://raw.githubusercontent.com/ossza/dnsaas/main/install_dnsaas.sh
sudo TOKEN=$TOKEN bash install_dnsaas.sh
```

> ⚠️ **Important**  
> Replace `token_testclient123` with **your actual token** before running the command.

> 🐙 **GitHub Repository**  
> The installer script is hosted at:  
> `https://raw.githubusercontent.com/ossza/dnsaas/main/install_dnsaas.sh`

---

## 🔄 Clean Install (Reset First)

If you have an existing installation or want to start fresh, use this method to uninstall first, then install.

```bash
# Complete reset and fresh install
# Replace TOKEN with your actual token
TOKEN="token_testclient123"  # ⚠️ Change this!

# Step 1: Uninstall any existing setup
wget -qO- https://raw.githubusercontent.com/ossza/dnsaas/main/uninstall_dnsaas.sh | sudo bash

# Step 2: Fresh install
wget https://raw.githubusercontent.com/ossza/dnsaas/main/install_dnsaas.sh
sudo TOKEN=$TOKEN bash install_dnsaas.sh
```

> ⚠️ **Note**  
> The uninstall step will remove any existing DNSaaS configuration and restore your original DNS settings.

---

## 🔧 Manual Installation (Step-by-Step)

If you prefer to install manually or want to understand each step, follow this guide.

### 1. Install Build Dependencies

```bash
# Install required packages
sudo apt update
sudo apt install -y cmake libc-ares-dev libcurl4-openssl-dev \
    libev-dev libsystemd-dev build-essential git
```

### 2. Build and Install https_dns_proxy

```bash
# Clone and build
git clone https://github.com/aarond10/https_dns_proxy
cd https_dns_proxy
cmake .
make
sudo make install
```

### 3. Configure the Proxy

Create the configuration with your token. **Replace `token_testclient123` with your actual token.**

```bash
# Create the service file
sudo tee /etc/systemd/system/https_dns_proxy.service << 'EOF'
[Unit]
Description=DNSaaS HTTPS DNS Proxy
After=network-online.target
Wants=network-online.target
Before=nss-lookup.target

[Service]
Type=simple
# ⚠️ Replace token_testclient123 with YOUR token
ExecStart=/usr/local/bin/https_dns_proxy -a 127.0.0.1 -p 53 \
    -r https://dns1.oss.co.za/token_testclient123 \
    -b 1.1.1.1,8.8.8.8
Restart=always
RestartSec=10
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF
```

> ⚠️ **Important**  
> Replace `token_testclient123` with **your actual token** in the configuration above.

### 4. Start the Service

```bash
# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable https_dns_proxy
sudo systemctl start https_dns_proxy

# Verify it's running
sudo systemctl status https_dns_proxy --no-pager
```

### 5. Configure System DNS

```bash
# Set system DNS to use the proxy
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
sudo resolvectl dns $INTERFACE 127.0.0.1
sudo resolvectl domain $INTERFACE ~.

# Alternative: Edit /etc/resolv.conf directly
sudo tee /etc/resolv.conf << 'EOF'
nameserver 127.0.0.1
options edns0 trust-ad
search .
EOF
```

> 💡 **Make resolv.conf Permanent**  
> To prevent `/etc/resolv.conf` from being overwritten:
>
> ```bash
> sudo chattr +i /etc/resolv.conf
> ```

### 6. Test Your Configuration

```bash
# Test normal resolution
dig example.com A +short

# Test IPv6
dig google.com AAAA +short

# Test blocked domain (should return NXDOMAIN)
dig adult.filterdns.net A +short

# Check service logs
sudo journalctl -u https_dns_proxy -n 20 --no-pager
```

> ✅ **Success Indicators**
> - `dig example.com` returns A records
> - `dig adult.filterdns.net` returns **NXDOMAIN** (blocked)
> - `resolvectl status` shows `127.0.0.1` as DNS server

---

## 🗑️ Uninstall / Cleanup

To completely remove DNSaaS and restore your original DNS settings, run the uninstaller.

> ⚠️ **What This Does**
> - Stops and removes the systemd service
> - Removes the `https_dns_proxy` binary
> - Removes configuration files
> - Restores your original `/etc/resolv.conf`
> - Restarts systemd-resolved
> - Flushes DNS cache

```bash
# Download and run the uninstaller
wget -qO- https://raw.githubusercontent.com/ossza/dnsaas/main/uninstall_dnsaas.sh | sudo bash
```

> ✅ **After Uninstall**  
> Your system will use your ISP's default DNS or 1.1.1.1/8.8.8.8 as fallback.

---

## 🎛️ Service Management

Easily enable, disable, or check the status of your DNS proxy.

| Action | Command |
|--------|---------|
| **Start** | `sudo systemctl start https_dns_proxy` |
| **Stop** | `sudo systemctl stop https_dns_proxy` |
| **Restart** | `sudo systemctl restart https_dns_proxy` |
| **Enable on boot** | `sudo systemctl enable https_dns_proxy` |
| **Disable on boot** | `sudo systemctl disable https_dns_proxy` |
| **Check status** | `sudo systemctl status https_dns_proxy --no-pager` |
| **View logs** | `sudo journalctl -u https_dns_proxy -f` |

---

## 🧪 Test Your Configuration

### Quick Test Script

```bash
#!/bin/bash
# DNSaaS Test Suite

echo "=== DNSaaS Test Suite ==="
echo ""

echo "1. Service Status:"
sudo systemctl is-active https_dns_proxy && echo "   ✅ Running" || echo "   ❌ Stopped"
echo ""

echo "2. DNS Resolution:"
echo "   example.com: $(dig example.com A +short | head -1)"
echo "   google.com:  $(dig google.com A +short | head -1)"
echo ""

echo "3. Blocking Test:"
BLOCKED=$(dig adult.filterdns.net A +short)
if [ -z "$BLOCKED" ]; then
    echo "   ✅ adult.filterdns.net is blocked"
else
    echo "   ❌ adult.filterdns.net resolved to $BLOCKED"
fi
echo ""

echo "4. DNS Server:"
resolvectl status 2>/dev/null | grep "DNS Servers" || cat /etc/resolv.conf | grep nameserver
echo ""
echo "=== Test Complete ==="
```

### Individual Test Commands

| Test | Command | Expected Result |
|------|---------|-----------------|
| **Basic Resolution** | `dig example.com A +short` | Returns IP address(es) |
| **IPv6 Resolution** | `dig google.com AAAA +short` | Returns IPv6 address |
| **Blocking** | `dig adult.filterdns.net A +short` | Returns nothing (NXDOMAIN) |
| **MX Record** | `dig gmail.com MX +short` | Returns mail servers |
| **DNS Leak Test** | `nslookup example.com` | Shows `127.0.0.1#53` as server |

---

## 🔧 Troubleshooting

> ❌ **Service fails to start**
> - Check logs: `sudo journalctl -u https_dns_proxy -n 50 --no-pager`
> - Port 53 may be in use: `sudo ss -tlnp | grep :53`
> - If systemd-resolved is using port 53: `sudo systemctl stop systemd-resolved`
> - Verify token is correct in the service file

> ❌ **DNS resolution returns REFUSED**
> - Check if the proxy is running: `ps aux | grep https_dns_proxy`
> - Verify the endpoint is reachable: `curl -sk https://dns1.oss.co.za/token_testclient123`
> - Check your token is valid and active
> - Run with verbose logging: `-vvv` flag

> ❌ **/etc/resolv.conf keeps getting overwritten**
> - Make it immutable: `sudo chattr +i /etc/resolv.conf`
> - Or use systemd-resolved: `sudo resolvectl dns INTERFACE 127.0.0.1`
> - Check if NetworkManager is overwriting it

> ✅ **Quick Fix Commands**

```bash
# Restart the service
sudo systemctl restart https_dns_proxy

# Reset DNS configuration
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
sudo resolvectl dns $INTERFACE 127.0.0.1
sudo resolvectl flush-caches

# Test directly
dig @127.0.0.1 example.com A
```

---

## 🐙 GitHub Resources

The installer and uninstaller scripts are available on GitHub for easy access and version control.

| Resource | URL |
|----------|-----|
| **Installer Script** | `https://raw.githubusercontent.com/ossza/dnsaas/main/install_dnsaas.sh` |
| **Uninstaller Script** | `https://raw.githubusercontent.com/ossza/dnsaas/main/uninstall_dnsaas.sh` |
| **Repository** | `https://github.com/ossza/dnsaas` |

> 💡 **Using the Scripts**
> - **Install:** `wget https://raw.githubusercontent.com/ossza/dnsaas/main/install_dnsaas.sh && sudo TOKEN=your_token bash install_dnsaas.sh`
> - **Uninstall:** `wget -qO- https://raw.githubusercontent.com/ossza/dnsaas/main/uninstall_dnsaas.sh | sudo bash`
> - **Clean Install:** Uninstall first, then install fresh

> ⚠️ **Important**  
> Always use the **raw** URL (`raw.githubusercontent.com`) when downloading scripts, not the GitHub web interface URL (`github.com/.../blob/...`).

---

## 🎯 Summary

- 🐧 **https_dns_proxy** provides system-wide DoH with token authentication
- ✅ Working endpoint: `https://dns1.oss.co.za/token_xxxxx`
- 🔒 All DNS queries are encrypted via DoH (port 443) with TLS 1.3
- ⚡ The proxy listens on `127.0.0.1:53` for system DNS
- 🔄 Easily toggle on/off with systemd commands
- 🛡️ Fallback to 1.1.1.1 and 8.8.8.8 if the service is unreachable
- 🐙 Scripts available at `github.com/ossza/dnsaas`
- 🗑️ Uninstaller included for easy cleanup

### 🚀 Quick Reference

**Endpoint:**  
`https://dns1.oss.co.za/token_testclient123`

**Ubuntu Commands:**

```text
Start:    sudo systemctl start https_dns_proxy
Stop:     sudo systemctl stop https_dns_proxy
Status:   sudo systemctl status https_dns_proxy
Logs:     sudo journalctl -u https_dns_proxy -f
Config:   /etc/systemd/system/https_dns_proxy.service
```

**Install from GitHub:**

```bash
wget https://raw.githubusercontent.com/ossza/dnsaas/main/install_dnsaas.sh
sudo TOKEN=your_token bash install_dnsaas.sh
```

**Uninstall:**

```bash
wget -qO- https://raw.githubusercontent.com/ossza/dnsaas/main/uninstall_dnsaas.sh | sudo bash
```

---

**DNSaaS** · Secure DNS-over-HTTPS with Token Authentication  
Endpoint: `https://dns1.oss.co.za/token_xxxxx` · Port: `443`

🐧 Ubuntu · 📅 Last updated: September 2026 · 📧 Support: support@oss.co.za  
🐙 Installer: [github.com/ossza/dnsaas](https://github.com/ossza/dnsaas)

