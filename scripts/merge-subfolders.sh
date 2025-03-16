#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

BASE="$1"

if [ ! -d "$BASE" ]; then
    echo "Error: '$BASE' is not a valid directory."
    exit 1
fi

# Create (or use) the MERGE directory in the base directory
MERGE_DIR="$BASE/MERGE"
mkdir -p "$MERGE_DIR"
echo "MERGE directory created/used: $MERGE_DIR"

# Enable nullglob to avoid having undeveloped patterns
shopt -s nullglob

# Use an associative array to group sub-subdirectories by their name
declare -A groups

# Iterate through all directories at two levels of depth
for dir in "$BASE"/*/*; do
    if [ -d "$dir" ]; then
        name=$(basename "$dir")
        # Separate paths with a semicolon
        groups["$name"]+="$dir;"
    fi
done

# Process each group of directories
for name in "${!groups[@]}"; do
    # Split the string into an array
    IFS=';' read -ra directories <<< "${groups[$name]}"
    # If the group contains more than one directory (duplicate)
    if [ ${#directories[@]} -gt 1 ]; then
        echo "Merging directories named '$name'..."
        target="$MERGE_DIR/$name"
        mkdir -p "$target"
        all_success=true
        # Copy the contents of each directory into the target directory
        for src in "${directories[@]}"; do
            if [ -n "$src" ]; then
                echo "Copying contents from '$src' to '$target'..."
                # Use rsync to copy all contents (including hidden files)
                rsync -av "$src/" "$target/" && echo "Copy from '$src' successful." || { echo "Error while copying from '$src'."; all_success=false; }
            fi
        done
        # If all copies were successful, delete the source directories
        if $all_success; then
            echo "All copies for '$name' were successful. Deleting source directories..."
            for src in "${directories[@]}"; do
                if [ -n "$src" ]; then
                    rm -rf "$src" && echo "Directory deleted: $src"
                fi
            done
        else
            echo "The merge for '$name' is not complete. Source directories will not be deleted."
        fi
    fi
done
