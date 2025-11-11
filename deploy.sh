#!/bin/bash
#
# deploy.sh
#
# Smart dotfiles deployment with automatic path inference
#
# Author: Michael Gilchrist (michaelgilch@gmail.com) 

set -e
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$DOTFILES_DIR/home"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Deployment mode
FORCE_MODE=false
NEW_ONLY_MODE=false

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

deploy_all() {
	log_info "Starting deployment for host: $HOSTNAME"
	echo ""

	find "$HOME_DIR" -mindepth 1 -maxdepth 1 | while read -r src; do
		filename="$(basename "$src")"

		if [ "$filename" = "config" ]; then
		        # Special handling for config/ - symlink each subdirectory
		        find "$src" -mindepth 1 -maxdepth 1 -type d | while read -r config_dir; do
		        	app_name="$(basename "$config_dir")"
				dest="$HOME/.config/$app_name"

				# Skip if destination already exists
			        if [ -e "$dest" ] || [ -L "$dest" ]; then
			                echo "Skipped (exists): $dest"
			                continue
		            fi
            
		            # Create .config if it doesn't exist
		            mkdir -p "$HOME/.config"
            
		            # Create symlink
		            ln -sf "$config_dir" "$dest"
		            echo "Linked: $dest -> $config_dir"
		        done
		else
        		# Regular files/directories in home/ -> ~/.filename
		        dest="$HOME/.$filename"
	        
		        # Skip if destination already exists
		        if [ -e "$dest" ] || [ -L "$dest" ]; then
		                echo "Skipped (exists): $dest"
		                continue
		        fi
		        
		        # Only create parent directory if src is a FILE
		        # If src is a directory, we're symlinking the whole directory
		        if [ -f "$src" ]; then
		            mkdir -p "$(dirname "$dest")"
		        fi
        
		        # Create symlink
		        ln -sf "$src" "$dest"
		        echo "Linked: $dest -> $src"
		fi
	done

	echo ""
	log_success "Deployment complete!"
}

# Usage information
usage() {
	cat << EOF
Usage: $(basename "$0") [OPTIONS]

Deploy dotfiles with automatic path inference and hostname-specific overrides.

OPTIONS:
	-h, --help	Show this help message
	-f, --force	Force deployment (backup and replace existing files)
	-n, --new-only	Only deploy files that don't already exist
	-d, --dry-run	Show deployment plan without making changes

DIRECTORY STRUCTURE:
	home/		-> ~/.*
	home/config/	-> ~/.config/*
	home/vim/	-> ~/.vim/*

SPECIAL FILES:
	filename@hostname	Override for specific host

HOSTNAME-SPECIFIC:
	Current hostname: $HOSTNAME
	Override files ending with @$HOSTNAME will be used instead of base files.

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
	case $1 in
		-h|--help)
			usage
			exit 0
			;;
		-f|--force)
			FORCE_MODE=true
			shift
			;;
		-n|--new-only)
			log_warning "$1 not yet implemented."
			NEW_ONLY_MODE=true
			shift
			;;
		-d|--dry-run)
			log_warning "$1 not yet implemented."
			shift
			;;
		*)
			log_error "Unknown option: $1"
			echo ""
			usage
			exit 1
			;;
	esac
done

# Check if both force and new-only are set
if [ "$FORCE_MODE" = true ] && [ "$NEW_ONLY_MODE" = true ]; then
	log_error "Cannot use --force and --new-only together"
	exit 1
fi

# Run deployment
deploy_all
