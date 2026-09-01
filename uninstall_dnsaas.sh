#!/bin/bash
# =====================================================
# DNSaaS Uninstaller / Cleanup Script
# =====================================================
# This script removes all DNSaaS components and restores
# the system to its original DNS configuration.
# =====================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   DNSaaS Uninstaller / Cleanup       ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# ===== CHECK ROOT =====
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

# ===== STOP SERVICE =====
echo -e "${BLUE}==> Stopping https_dns_proxy service...${NC}"
if systemctl is-active --quiet https_dns_proxy; then
    systemctl stop https_dns_proxy
    echo -e "  ${GREEN}✅ Service stopped${NC}"
else
    echo -e "  ${YELLOW}⚠️ Service not running${NC}"
fi

# Disable service
if systemctl is-enabled --quiet https_dns_proxy 2>/dev/null; then
    systemctl disable https_dns_proxy
    echo -e "  ${GREEN}✅ Service disabled${NC}"
else
    echo -e "  ${YELLOW}⚠️ Service not enabled${NC}"
fi

# ===== REMOVE SERVICE FILE =====
echo -e "${BLUE}==> Removing service files...${NC}"
if [ -f /etc/systemd/system/https_dns_proxy.service ]; then
    rm -f /etc/systemd/system/https_dns_proxy.service
    echo -e "  ${GREEN}✅ Removed /etc/systemd/system/https_dns_proxy.service${NC}"
fi

# Remove any override files
if [ -d /etc/systemd/system/https_dns_proxy.service.d ]; then
    rm -rf /etc/systemd/system/https_dns_proxy.service.d
    echo -e "  ${GREEN}✅ Removed override directory${NC}"
fi

# Reload systemd
systemctl daemon-reload
echo -e "  ${GREEN}✅ Systemd reloaded${NC}"

# ===== REMOVE BINARY =====
echo -e "${BLUE}==> Removing https_dns_proxy binary...${NC}"
if [ -f /usr/local/bin/https_dns_proxy ]; then
    rm -f /usr/local/bin/https_dns_proxy
    echo -e "  ${GREEN}✅ Removed /usr/local/bin/https_dns_proxy${NC}"
fi

# Remove any wrapper scripts
if [ -f /usr/local/bin/https_dns_proxy_wrapper ]; then
    rm -f /usr/local/bin/https_dns_proxy_wrapper
    echo -e "  ${GREEN}✅ Removed wrapper script${NC}"
fi

# ===== REMOVE CONFIG FILES =====
echo -e "${BLUE}==> Removing configuration files...${NC}"
if [ -d /etc/https_dns_proxy ]; then
    rm -rf /etc/https_dns_proxy
    echo -e "  ${GREEN}✅ Removed /etc/https_dns_proxy${NC}"
fi

# ===== RESTORE DNS CONFIGURATION =====
echo -e "${BLUE}==> Restoring DNS configuration...${NC}"

# Remove immutable flag from resolv.conf
if [ -f /etc/resolv.conf ]; then
    chattr -i /etc/resolv.conf 2>/dev/null || true
    echo -e "  ${GREEN}✅ Removed immutable flag from /etc/resolv.conf${NC}"
fi

# Restore from backup if exists
if [ -f /etc/resolv.conf.bak ]; then
    cp /etc/resolv.conf.bak /etc/resolv.conf
    echo -e "  ${GREEN}✅ Restored /etc/resolv.conf from backup${NC}"
else
    # Create a default resolv.conf
    cat > /etc/resolv.conf << EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF
    echo -e "  ${GREEN}✅ Created default /etc/resolv.conf${NC}"
fi

# ===== RESTART SYSTEMD-RESOLVED =====
echo -e "${BLUE}==> Restarting systemd-resolved...${NC}"
if systemctl is-enabled --quiet systemd-resolved 2>/dev/null; then
    systemctl start systemd-resolved
    echo -e "  ${GREEN}✅ systemd-resolved started${NC}"
else
    systemctl enable systemd-resolved 2>/dev/null || true
    systemctl start systemd-resolved 2>/dev/null || true
    echo -e "  ${GREEN}✅ systemd-resolved enabled and started${NC}"
fi

# ===== FLUSH DNS CACHE =====
echo -e "${BLUE}==> Flushing DNS cache...${NC}"
resolvectl flush-caches 2>/dev/null || true
echo -e "  ${GREEN}✅ DNS cache flushed${NC}"

# ===== REMOVE BUILD DIRECTORY (Optional) =====
echo -e "${BLUE}==> Checking for build directory...${NC}"
if [ -d "$HOME/Documents/cloud_env/https_dns_proxy" ]; then
    echo -e "  ${YELLOW}⚠️ Build directory found: $HOME/Documents/cloud_env/https_dns_proxy${NC}"
    echo -n "  Remove it? [y/N]: "
    read -r REMOVE_BUILD
    if [[ "$REMOVE_BUILD" =~ ^[Yy]$ ]]; then
        rm -rf "$HOME/Documents/cloud_env/https_dns_proxy"
        echo -e "  ${GREEN}✅ Build directory removed${NC}"
    else
        echo -e "  ${YELLOW}⚠️ Build directory kept${NC}"
    fi
fi

# ===== SUMMARY =====
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ DNSaaS Uninstall Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "  Removed:"
echo "    ✅ https_dns_proxy binary"
echo "    ✅ systemd service"
echo "    ✅ Configuration files"
echo "    ✅ DNS settings restored"
echo ""
echo -e "${GREEN}To verify:${NC}"
echo "  dig example.com A +short  # Should use your ISP's DNS"
echo "  sudo systemctl status systemd-resolved"
echo ""
echo -e "${BLUE}========================================${NC}"
