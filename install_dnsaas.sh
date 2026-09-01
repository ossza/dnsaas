#!/bin/bash
# =====================================================
# DNSaaS Installer for Ubuntu
# https://github.com/yourusername/dnsaas-installer
# =====================================================
# This script installs and configures https_dns_proxy
# for DNS-over-HTTPS with token authentication.
# =====================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ===== CONFIGURATION =====
# Use TOKEN from environment or prompt
if [ -z "$TOKEN" ]; then
    echo -e "${YELLOW}Enter your DNSaaS token:${NC}"
    read -r TOKEN
fi

if [ -z "$TOKEN" ]; then
    echo -e "${RED}Error: No token provided${NC}"
    echo "Usage: TOKEN=your_token sudo ./install-dnsaas.sh"
    exit 1
fi

DOH_URL="https://dns1.oss.co.za/${TOKEN}"
FALLBACK_DNS="1.1.1.1,8.8.8.8"
LISTEN_ADDR="127.0.0.1"
LISTEN_PORT="53"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   DNSaaS Installer for Ubuntu        ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "  Token:    $TOKEN"
echo "  Endpoint: $DOH_URL"
echo "  Listen:   $LISTEN_ADDR:$LISTEN_PORT"
echo ""

# ===== CHECK ROOT =====
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

# ===== INSTALL DEPENDENCIES =====
echo -e "${BLUE}==> Installing dependencies...${NC}"
apt update
apt install -y cmake libc-ares-dev libcurl4-openssl-dev \
    libev-dev libsystemd-dev build-essential git

# ===== BUILD HTTPS_DNS_PROXY =====
echo -e "${BLUE}==> Building https_dns_proxy...${NC}"

# Check if we're in the right directory
if [ -d "https_dns_proxy" ]; then
    cd https_dns_proxy
else
    git clone https://github.com/aarond10/https_dns_proxy
    cd https_dns_proxy
fi

cmake .
make
make install

cd ..

echo -e "${GREEN}✅ https_dns_proxy installed${NC}"

# ===== CREATE SYSTEMD SERVICE =====
echo -e "${BLUE}==> Creating systemd service...${NC}"

# Stop any existing service
systemctl stop https_dns_proxy 2>/dev/null || true

# Create the service file
cat > /etc/systemd/system/https_dns_proxy.service << EOF
[Unit]
Description=DNSaaS HTTPS DNS Proxy
After=network-online.target
Wants=network-online.target
Before=nss-lookup.target

[Service]
Type=simple
ExecStart=/usr/local/bin/https_dns_proxy -a ${LISTEN_ADDR} -p ${LISTEN_PORT} -r ${DOH_URL} -b ${FALLBACK_DNS}
Restart=always
RestartSec=10
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
systemctl daemon-reload
systemctl enable https_dns_proxy

echo -e "${GREEN}✅ Service created${NC}"

# ===== STOP CONFLICTING SERVICES =====
echo -e "${BLUE}==> Stopping conflicting services...${NC}"

if systemctl is-active --quiet systemd-resolved; then
    echo "  Stopping systemd-resolved..."
    systemctl stop systemd-resolved
    systemctl disable systemd-resolved
fi

# ===== START SERVICE =====
echo -e "${BLUE}==> Starting service...${NC}"
systemctl start https_dns_proxy

if systemctl is-active --quiet https_dns_proxy; then
    echo -e "${GREEN}✅ Service is running${NC}"
else
    echo -e "${RED}❌ Service failed to start${NC}"
    journalctl -u https_dns_proxy -n 20 --no-pager
    exit 1
fi

# ===== CONFIGURE SYSTEM DNS =====
echo -e "${BLUE}==> Configuring system DNS...${NC}"

INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
if [ -n "$INTERFACE" ]; then
    resolvectl dns "$INTERFACE" 127.0.0.1 2>/dev/null || true
    resolvectl domain "$INTERFACE" ~. 2>/dev/null || true
    echo "  ✅ DNS set to 127.0.0.1 on $INTERFACE"
fi

# Backup and set /etc/resolv.conf
cp /etc/resolv.conf /etc/resolv.conf.bak 2>/dev/null || true
cat > /etc/resolv.conf << EOF
nameserver 127.0.0.1
options edns0 trust-ad
search .
EOF

# Make resolv.conf immutable (prevents overwriting)
chattr +i /etc/resolv.conf 2>/dev/null || true

echo -e "${GREEN}✅ System DNS configured${NC}"

# ===== TEST =====
echo -e "${BLUE}==> Testing DNS resolution...${NC}"
sleep 2

if command -v dig &>/dev/null; then
    RESULT=$(dig example.com A +short 2>/dev/null | head -1)
    if [ -n "$RESULT" ]; then
        echo -e "  ${GREEN}✅ example.com → $RESULT${NC}"
    else
        echo -e "  ${YELLOW}⚠️ DNS test failed. Check manually: dig example.com${NC}"
    fi
    
    # Test blocking
    BLOCKED=$(dig adult.filterdns.net A +short 2>/dev/null)
    if [ -z "$BLOCKED" ]; then
        echo -e "  ${GREEN}✅ adult.filterdns.net is blocked${NC}"
    else
        echo -e "  ${YELLOW}⚠️ adult.filterdns.net resolved to $BLOCKED${NC}"
    fi
else
    echo -e "  ${YELLOW}⚠️ dig not installed, skipping tests${NC}"
fi

# ===== SUMMARY =====
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ DNSaaS Installation Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "  Service: https_dns_proxy (systemd)"
echo "  Listen:  $LISTEN_ADDR:$LISTEN_PORT"
echo "  Endpoint: $DOH_URL"
echo ""
echo -e "${GREEN}Commands:${NC}"
echo "  sudo systemctl status https_dns_proxy   - Check service status"
echo "  sudo systemctl restart https_dns_proxy   - Restart service"
echo "  sudo journalctl -u https_dns_proxy -f    - View logs"
echo ""
echo -e "${GREEN}Test:${NC}"
echo "  dig example.com A"
echo "  dig adult.filterdns.net A  # Should be blocked"
echo ""
echo -e "${GREEN}To roll back:${NC}"
echo "  sudo systemctl stop https_dns_proxy"
echo "  sudo chattr -i /etc/resolv.conf"
echo "  sudo cp /etc/resolv.conf.bak /etc/resolv.conf"
echo ""
echo -e "${BLUE}========================================${NC}"
