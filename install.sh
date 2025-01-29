#!/bin/bash

# Ensure the script exits on errors
set -euo pipefail

usage() {
    echo "Usage: $0 [-f] [-d] [-p <package>] <csv_file>"
    echo "  -f          Force overwrite existing files or symlinks."
    echo "  -d          Enable debug output."
    echo "  -p <pkg>    Only process this specific package from CSV."
    exit 1
}

force_overwrite=false
debug=false
target_package=""

while getopts ":fdp:" opt; do
    case $opt in
        f)
            force_overwrite=true
            ;;
        d)
            debug=true
            ;;
        p)
            if [[ -z "${OPTARG:-}" ]]; then
                echo "Error: -p requires a non-empty argument."
                usage
            fi
            target_package="$OPTARG"
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND - 1))

if [[ $# -ne 1 ]]; then
    usage
fi

csv_file="$1"

if [[ ! -f "$csv_file" ]]; then
    echo "Error: File '$csv_file' not found."
    exit 1
fi

cwd=$(pwd)

# Debug print function
debug_print() {
    if [[ "$debug" == true ]]; then
        echo "$@"
    fi
}

# Read the CSV file line by line
while IFS=',' read -r package file location; do

    # Skip comments or invalid lines
    if [[ "$package" =~ ^# ]] || [[ -z "$package" || -z "$file" || -z "$location" ]]; then
        debug_print "Skipping comment/invalid line: $package, $file, $location"
        continue
    fi

    # If a package was specified, only process that package
    if [[ -n "$target_package" && "$package" != "$target_package" ]]; then
        debug_print "Skipping package '$package' (not the target package)."
        continue
    fi

    # Expand ~ to $HOME if present in the location
    location="${location/#\~/$HOME}"

    # Prepend the current working directory to the file path if it's relative
    if [[ "$file" != /* ]]; then
        file="$cwd/$file"
    fi

    # Check if the file has hostname-specific versions
    host="${HOSTNAME^^}" # Convert hostname to uppercase
    file_with_hostname="${file}-${host}"
    if [[ -e "$file_with_hostname" ]]; then
        file="$file_with_hostname"
    fi

    # Check if the package is installed
    if pacman -Q "$package" &>/dev/null; then
        debug_print "Package '$package' is installed. Processing..."

        # Check if a file or symlink already exists at the location
        if [[ -L "$location" ]]; then
            # If a symlink exists
            if [[ "$force_overwrite" == true ]]; then
                debug_print "Overwriting existing symlink at $location."
                rm "$location"
            else
                debug_print "Symlink already exists at $location. Skipping."
                continue
            fi
        elif [[ -e "$location" ]]; then
            # If a regular file or directory exists
            if [[ "$force_overwrite" == true ]]; then
                debug_print "Overwriting existing file at $location."
                rm -rf "$location"
            else
                debug_print "File already exists at $location. Skipping."
                continue
            fi
        fi

        # Create the symlink
        mkdir -p "$(dirname "$location")"
        ln -s "$file" "$location"
        echo "Created symlink: $file -> $location"
    else
        debug_print "Package '$package' is not installed. Skipping..."
    fi
done < "$csv_file"

debug_print "Done!"
