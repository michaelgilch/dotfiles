#!/bin/bash

# Ensure the script exits on errors
set -euo pipefail

# Usage function for help message
usage() {
    echo "Usage: $0 [-f] <csv_file>"
    echo "  -f    Force overwrite existing symlinks."
    exit 1
}

# Parse options
force_overwrite=false
while getopts ":f" opt; do
    case $opt in
        f)
            force_overwrite=true
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND - 1))

# Ensure the script receives a CSV file as an argument
if [[ $# -ne 1 ]]; then
    usage
fi

csv_file="$1"

# Ensure the CSV file exists
if [[ ! -f "$csv_file" ]]; then
    echo "Error: File '$csv_file' not found."
    exit 1
fi

# Get the current working directory
cwd=$(pwd)

# Read the CSV file line by line
while IFS=',' read -r package file location; do
    # Skip empty lines or lines with missing fields
    if [[ -z "$package" || -z "$file" || -z "$location" ]]; then
        echo "Skipping invalid entry: $package, $file, $location"
        continue
    fi

    # Expand ~ to the home directory if present in the location
    location="${location/#\~/$HOME}"

    # Prepend the current working directory to the file path if it's relative
    if [[ "$file" != /* ]]; then
        file="$cwd/$file"
    fi

    # Check if the package is installed
    if pacman -Q "$package" &>/dev/null; then
        echo "Package '$package' is installed. Processing..."

        # Check if a file or symlink already exists at the location
        if [[ -L "$location" ]]; then
            # If a symlink exists
            if [[ "$force_overwrite" == true ]]; then
                echo "Overwriting existing symlink at $location."
                rm "$location"
                ln -s "$file" "$location"
            else
                echo "Symlink already exists at $location. Skipping."
            fi
        elif [[ -e "$location" ]]; then
            # If a regular file or directory exists
            echo "File already exists at $location. Skipping."
        else
            # Create the symlink
            mkdir -p "$(dirname "$location")"
            ln -s "$file" "$location"
            echo "Created symlink: $file -> $location"
        fi
    else
        echo "Package '$package' is not installed. Skipping..."
    fi
done < "$csv_file"

echo "Done!"
