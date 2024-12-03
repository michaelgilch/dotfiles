#!/bin/bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <csv_file>"
    exit 1
fi
csv_file="$1"

if [[ ! -f "$csv_file" ]]; then
    echo "Error: File '$csv_file' not found."
    exit 1
fi

cwd=$(pwd)

while IFS=',' read -r package file location; do
    if [[ -z "$package" || -z "$file" || -z "$location" ]]; then
        echo "Skipping invalid entry: $package, $file, $location"
        continue
    fi

    location="${location/#\~/$HOME}"

    if [[ "$file" != /* ]]; then
        file="$cwd/$file"
    fi

    if pacman -Q "$package" &>/dev/null; then
        echo "Package '$package' is installed. Processing..."

        mkdir -p "$(dirname "$location")"

	if [ -L ${location} ] && [ -e ${location} ]; then
		echo "Link or file already exists."
	else
        	ln -sf "$file" "$location"
        	echo "Created symlink: $file -> $location"
	fi
    else
        echo "Package '$package' is not installed. Skipping..."
    fi
done < "$csv_file"

echo "Done!"
