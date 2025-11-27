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
PACKAGES_MAP="$DOTFILES_DIR/packages.map"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Deployment mode
FORCE_MODE=false
NEW_ONLY_MODE=false
SKIP_PACKAGE_CHECK=false
DRY_RUN=false

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

# Create backup directory if it doesn't exist
create_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        log_info "Created backup directory: $BACKUP_DIR"
    fi
}

# Backup a file/directory/symlink
backup_path() {
    local path="$1"

    # Nothing to backup if it doesn't exist
    [ ! -e "$path" ] && [ ! -L "$path" ] && return 0

    # In dry-run mode, just show what would be backed up
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY_RUN] Would backup: $path"
        return 0
    fi

    create_backup_dir

    # Create relative path for backup
    local rel_path="${path#$HOME/}"
    local backup_path="$BACKUP_DIR/$rel_path"

    # Create parent directory in backup
    mkdir -p "$(dirname "$backup_path")"

    # Copy (preserving symlinks and attributes)
    if cp --no-dereference --preserve=all --recursive "$path" "$backup_path" 2>/dev/null; then
        log_info "Backed up: $path"
        return 0
    else
        log_warning "Failed to backup: $path"
        return 1
    fi
}

# Remove existing path (after backup if in force mode)
remove_existing() {
    local path="$1"

    # Nothing to remove if it doesn't exist
    [ ! -e "$path" ] && [ ! -L "$path" ] && return 0

    if [ "$FORCE_MODE" = true ]; then
        backup_path "$path"

        if [ "$DRY_RUN" = true ]; then
            log_info "[DRY RUN] Would remove: $path"
        else
            rm -rf "$path"
            log_info "Removed: $path"
        fi
        return 0
    else
        # Not in force mode, destination exists = skip
        return 1
    fi
}

# Check if package is installed
is_package_installed() {
    local package="$1"
    
    # Check with pacman (Arch)
    if command -v pacman &> /dev/null; then
        pacman -Q "$package" &> /dev/null && return 0
    fi
    
    # Check with dpkg (Debian/Ubuntu)
    if command -v dpkg &> /dev/null; then
        dpkg -l "$package" 2> /dev/null | grep -q "^ii" && return 0
    fi
    
    # Check with rpm (RedHat/Fedora)
    if command -v rpm &> /dev/null; then
        rpm -q "$package" &> /dev/null && return 0
    fi
    
    # Check if command exists (fallback)
    command -v "$package" &> /dev/null && return 0
    
    return 1
}

# Get required packages for a config
get_required_packages() {
    local config_name="$1"
    
    # If packages.map doesn't exist, assume no requirements
    [ ! -f "$PACKAGES_MAP" ] && return 0
    
    # Look for config in packages.map
    local line=$(grep "^${config_name}:" "$PACKAGES_MAP" 2>/dev/null)
    
    # If not found in map, assume no requirements
    [ -z "$line" ] && return 0
    
    # Extract packages (everything after the colon)
    local packages="${line#*:}"
    
    # If empty (config: with nothing after), no requirements
    [ -z "$packages" ] && return 0
    
    echo "$packages"
}

# Check if all required packages are installed
should_deploy_config() {
    local config_name="$1"
    
    # If skipping package checks, always deploy
    [ "$SKIP_PACKAGE_CHECK" = true ] && return 0
    
    local required_packages=$(get_required_packages "$config_name")
    
    # No requirements, always deploy
    [ -z "$required_packages" ] && return 0
    
    # Check each package (comma-separated)
    IFS=',' read -ra PACKAGES <<< "$required_packages"
    for package in "${PACKAGES[@]}"; do
        # Trim whitespace
        package=$(echo "$package" | xargs)
        
        if ! is_package_installed "$package"; then
            return 1
        fi
    done
    
    return 0
}

deploy_all() {
	log_info "Starting deployment for host: $HOSTNAME"
	
    if [ "$DRY_RUN" = true ]; then
        log_info "DRY RUN MODE - No changes will be made"
    fi

    if [ "$FORCE_MODE" = true ]; then
        log_warning "FORCE MODE - Existing files will be backed up and replaced"
    fi

	if [ "$SKIP_PACKAGE_CHECK" = false ] && [ -f "$PACKAGES_MAP" ]; then
	    log_info "Package checking enabled (use --skip-package-check to disable)"
	else
	    log_warning "Package checking disabled"
	fi
	
	echo ""

	find "$HOME_DIR" -mindepth 1 -maxdepth 1 | while read -r src; do
		filename="$(basename "$src")"

		if [ "$filename" = "config" ]; then
		        # Special handling for config/ - symlink each subdirectory
		        find "$src" -mindepth 1 -maxdepth 1 -type d | while read -r config_dir; do
		        	app_name="$(basename "$config_dir")"
				dest="$HOME/.config/$app_name"
				
				# Check if destination exists
			    if [ -e "$dest" ] || [ -L "$dest" ]; then
                    # Try to remove (will backup if force mode)
                    if ! remove_existing "$dest"; then
			            echo "Skipped (exists): $dest"
			            continue
                    fi
		        fi

				# Check if required packages are installed
				if ! should_deploy_config "$app_name"; then
				    required=$(get_required_packages "$app_name")
				    log_warning "Skipped (missing packages): $app_name (needs: $required)"
				    continue
				fi

                # DRY RUN: Don't actually create anything
                if [ "$DRY_RUN" = true ]; then
                    log_info "[DRY RUN] Would link: $dest -> $config_dir"
                    continue
                fi
            
		        # Create .config if it doesn't exist
		        mkdir -p "$HOME/.config"
            
		        # Create symlink
		        ln -sf "$config_dir" "$dest"
		        log_success "Linked: $dest"
		    done
		else
            # Regular files/directories in home/ -> ~/.filename
		    dest="$HOME/.$filename"
		        
            # Check if destination exists
		    if [ -e "$dest" ] || [ -L "$dest" ]; then
                # Try to remove (will backup if force mode)
                if ! remove_existing "$dest"; then
                    echo "Skipped (exists): $dest"
	    	        continue
                fi
		    fi

		    # Check if required packages are installed
		    if ! should_deploy_config "$filename"; then
		        required=$(get_required_packages "$filename")
		        log_warning "Skipped (missing packages): $filename (needs: $required)"
		        continue
		    fi
	        
            # DRY RUN: Don't actually create anything
            if [ "$DRY_RUN" = true ]; then
                log_info "[DRY RUN] Would link: $dest -> $src"
                continue
            fi
		        
		    # Only create parent directory if src is a FILE
		    if [ -f "$src" ]; then
		        mkdir -p "$(dirname "$dest")"
		    fi
        
		    # Create symlink
		    ln -sf "$src" "$dest"
		    log_success "Linked: $dest"
		fi
	done

	echo ""

    if [ "$DRY_RUN" = true ]; then
        log_info "Dry run complete - no changes were made"
    elif [ "$FORCE_MODE" = true ] && [ -d "$BACKUP_DIR" ]; then
        log_success "Deployment complete!"
        log_info "Backups saved to: $BACKUP_DIR"
    else
    	log_success "Deployment complete!"
    fi

}

# Usage information
usage() {
	cat << EOF
Usage: $(basename "$0") [OPTIONS]

Deploy dotfiles with automatic path inference and hostname-specific overrides.

OPTIONS:
	-h, --help		Show this help message
	-f, --force		Backup and replace ALL existing files/symlinks
	-n, --new-only		Only deploy files that don't already exist
	-d, --dry-run		Show deployment plan without making changes
	-s, --skip-package-check	Skip package dependency checking

DIRECTORY STRUCTURE:
	home/		-> ~/.*
	home/config/	-> ~/.config/*
	home/vim/	-> ~/.vim/*

FORCE MODE:
    With --force, existing files/directories/symlinks are backed up to
    ~/.dotfiles_backup_YYYYMMDD_HHMMSS/ and **then** replaced.
    This handles:
        - Regular files that conflict with dotfiles
        - Old symlinks from previous deployments
        - Orphaned configs from uninstalled packages

PACKAGE CHECKING:
	By default, configs are only deployed if required packages are installed.
	Edit packages.map to define package requirements for each config.

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
			DRY_RUN=true
			shift
			;;
		-s|--skip-package-check)
			SKIP_PACKAGE_CHECK=true
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
