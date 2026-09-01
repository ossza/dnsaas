# DNSaaS Installer for Ubuntu

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%20%7C%2024.04-orange.svg)](https://ubuntu.com/)
[![GitHub](https://img.shields.io/badge/GitHub-ossza%2Fdnsaas-blue.svg)](https://github.com/ossza/dnsaas)

One-click installer for DNS-over-HTTPS (DoH) with token-based authentication using `https_dns_proxy`. This guide will help you configure your Ubuntu system to use secure, encrypted DNS with token-based authentication.

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

## Overview

Our DNSaaS service uses **DNS-over-HTTPS (DoH)** with **token-based authentication** for maximum privacy and security. This guide will help you configure your Ubuntu system to use this service for **all DNS resolution** system-wide.

| Service | Endpoint | Authentication |
|---------|----------|----------------|
| **Primary DNS** | `https://dns1.oss.co.za/token_xxxxx` | Token in URL path |
| **Protocol** | DNS-over-HTTPS (DoH) • Port 443 • TLS 1.3 | |
| **Proxy** | `https_dns_proxy` listening on `127.0.0.1:53` | |
| **Fallback** | ✅ 1.1.1.1 • ✅ 8.8.8.8 (if service unreachable) | |

✅ **Verified Working**: This configuration has been tested and confirmed working on Ubuntu 22.04 LTS and 24.04 LTS with `https_dns_proxy`.

---

## Prerequisites

- **Ubuntu 22.04 LTS** or **24.04 LTS**
- **Your token:** `token_xxxxxxxxxx` (provided by DNSaaS administrator)
- Administrative (sudo) access
- Internet connectivity
- About **20 MB** of free disk space

> 💡 **Token Format**: Your token is provided by the DNSaaS administrator. It looks like: `token_xxxxxxxxxx`. Keep it secure!

---

## One-Click Install

> 🚀 **Recommended Method**

The quickest way to get started. Copy and paste these commands to install and configure everything automatically.

### What This Does
- Installs build dependencies and `https_dns_proxy`
- Configures the proxy with your token
- Sets up a systemd service for persistence
- Configures system DNS to use the proxy
- Tests the installation

### Installation Commands

```bash
# Download and run the installer from GitHub
# Replace TOKEN with your actual token
TOKEN="token_testclient123"  # ⚠️ Change this!

wget https://raw.githubusercontent.com/ossza/dnsaas/main/install_dnsaas.sh
sudo TOKEN=$TOKEN bash install_dnsaas.sh
