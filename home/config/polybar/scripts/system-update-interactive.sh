#!/bin/bash

# Colors for output (Nord theme)
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

clear

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║           ARCH LINUX SYSTEM UPDATE CHECK                  ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check for official repo updates
echo -e "${BLUE}[*]${NC} Checking official repositories..."
pacman_updates=$(checkupdates 2>/dev/null)
pacman_count=$(echo "$pacman_updates" | grep -v "^$" | wc -l)

if [ $pacman_count -gt 0 ]; then
    echo -e "${YELLOW}[!]${NC} Found ${GREEN}$pacman_count${NC} official package update(s):"
    echo ""
    echo -e "${CYAN}Package                          Current → New${NC}"
    echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"
    echo "$pacman_updates" | awk '{printf "%-30s %s → %s\n", $1, $2, $4}'
    echo ""
else
    echo -e "${GREEN}[✓]${NC} Official packages are up to date!"
    echo ""
fi

# Check for AUR updates
echo -e "${BLUE}[*]${NC} Checking AUR packages..."
aur_updates=$(yay -Qua 2>/dev/null)
aur_count=$(echo "$aur_updates" | grep -v "^$" | wc -l)

if [ $aur_count -gt 0 ]; then
    echo -e "${YELLOW}[!]${NC} Found ${GREEN}$aur_count${NC} AUR package update(s):"
    echo ""
    echo -e "${CYAN}Package                          Current → New${NC}"
    echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"
    echo "$aur_updates" | awk '{printf "%-30s %s → %s\n", $1, $2, $4}'
    echo ""
else
    echo -e "${GREEN}[✓]${NC} AUR packages are up to date!"
    echo ""
fi

# Calculate total
total_updates=$((pacman_count + aur_count))

if [ $total_updates -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Your system is fully up to date! Nothing to do here.     ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    read -p "Press Enter to close..."
    exit 0
fi

# Summary
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "Total updates available: ${GREEN}$total_updates${NC} ($pacman_count official, $aur_count AUR)"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""

# Ask user what to do
echo -e "${YELLOW}What would you like to do?${NC}"
echo ""
echo "  1) Update all packages (pacman + AUR)"
echo "  2) Update only official packages (pacman)"
echo "  3) Update only AUR packages"
echo "  4) Exit without updating"
echo ""
read -p "Enter your choice [1-4]: " choice

case $choice in
    1)
        echo ""
        echo -e "${BLUE}[*]${NC} Updating all packages..."
        echo ""
        yay -Syu
        ;;
    2)
        if [ $pacman_count -gt 0 ]; then
            echo ""
            echo -e "${BLUE}[*]${NC} Updating official packages..."
            echo ""
            sudo pacman -Syu
        else
            echo -e "${GREEN}[✓]${NC} No official packages to update."
        fi
        ;;
    3)
        if [ $aur_count -gt 0 ]; then
            echo ""
            echo -e "${BLUE}[*]${NC} Updating AUR packages..."
            echo ""
            yay -Sua
        else
            echo -e "${GREEN}[✓]${NC} No AUR packages to update."
        fi
        ;;
    4)
        echo -e "${YELLOW}[*]${NC} Exiting without updating."
        exit 0
        ;;
    *)
        echo -e "${RED}[!]${NC} Invalid choice. Exiting."
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}[✓]${NC} Update process completed!"
echo ""
read -p "Press Enter to close..."
