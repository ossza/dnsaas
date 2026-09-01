#!/bin/bash
# =====================================================
# DNSaaS Complete Reset & Install
# =====================================================
# This script uninstalls any existing DNSaaS setup
# and performs a fresh installation.
# =====================================================

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   DNSaaS Complete Reset & Install     ${NC}"
echo -e "${BLUE}========================================${NC}"

# Check for token
if [ -z "$TOKEN" ]; then
    echo -e "${YELLOW}Enter your DNSaaS token:${NC}"
    read -r TOKEN
fi

if [ -z "$TOKEN" ]; then
    echo "Error: No token provided"
    echo "Usage: TOKEN=your_token sudo ./reset-and-install.sh"
    exit 1
fi

# Step 1: Uninstall
echo ""
echo -e "${BLUE}Step 1: Cleaning up existing installation...${NC}"
wget -qO- https://github.com/ossza/dnsaas/raw/main/uninstall_dnsaas.sh | sudo bash

# Step 2: Install
echo ""
echo -e "${BLUE}Step 2: Installing fresh...${NC}"
wget -q https://github.com/ossza/dnsaas/raw/main/install_dnsaas.sh
sudo TOKEN="$TOKEN" bash install_dnsaas.sh

# Clean up installer script
rm -f install_dnsaas.sh

echo ""
echo -e "${GREEN}✅ Complete Reset & Install Done!${NC}"
