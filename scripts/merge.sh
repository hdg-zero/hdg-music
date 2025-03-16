#!/usr/bin/env bash

# Checks if two arguments have been passed
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <directory> <prefix>"
    exit 1
fi

SEARCH_DIR=$1
PREFIX=$2
TARGET_DIR="${SEARCH_DIR}/${PREFIX}/"

# Creates the target directory if it does not exist
mkdir -p "$TARGET_DIR"

# Finds all directories that start with the given prefix in the specified directory
for dir in "${SEARCH_DIR}/${PREFIX}"*/; do
    # Checks if the directory exists
    if [ -d "$dir" ]; then
        echo "Merging: $dir"
        
        # Copies the contents of the directory into the target directory
        cp -r "$dir"* "$TARGET_DIR"
        
        # Checks if the copy was successful
        if [ $? -eq 0 ]; then
            echo "Contents of $dir copied to $TARGET_DIR"
            rm -rf "$dir"
            echo "Directory $dir deleted."
        else
            echo "Error while copying $dir."
        fi
    fi
done

echo "Merge completed in the directory: $TARGET_DIR"
