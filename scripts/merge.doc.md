# merge.sh Documentation

## Overview

`merge.sh` is a Bash script that merges the contents of directories that start with a specified prefix into a target directory. After successfully copying the contents, it deletes the original directories.

## Features

- Takes a directory path and a prefix as input.
- Merges all directories starting with the specified prefix into a new directory.
- Deletes the original directories after successful copying.
- Provides informative logs during execution.

## Usage

### Prerequisites

- A Unix-like operating system (Linux, macOS, etc.) with Bash installed.
- Necessary permissions to read the source directories and write to the target directory.

### Script Creation

1. Open a terminal.
2. Create a new file named `merge.sh`:
   ```bash
   nano merge.sh
   ```
3. Copy the script code into the file.
4. Save and exit the editor.

### Make the Script Executable

Run the following command to make the script executable:
```bash
chmod +x merge.sh
```

### Running the Script

To execute the script, use the following command format:
```bash
./merge.sh <directory> <prefix>
```

- `<directory>`: The path to the directory where the search for folders will be performed.
- `<prefix>`: The prefix that the folders must start with to be included in the merge.

#### Example

To merge all folders starting with "ART" in the directory `/path/to/directory`, run:
```bash
./merge.sh /path/to/directory ART
```

## Script Logic

1. **Input Validation**: The script checks if exactly two arguments are provided. If not, it displays usage instructions and exits.
2. **Target Directory Creation**: It creates a target directory based on the specified prefix if it does not already exist.
3. **Directory Search and Merge**:
   - It searches for all directories in the specified path that start with the given prefix.
   - For each found directory:
     - It copies the contents to the target directory.
     - If the copy operation is successful, it deletes the original directory.
4. **Logging**: The script provides logs indicating the progress of the merging process, including which directories are being merged and whether they were successfully copied and deleted.

## Important Notes

- **Data Loss Warning**: The script uses `rm -rf` to delete directories. Ensure that you do not delete important data inadvertently.
- **Permissions**: Make sure you have the necessary permissions to read from the source directories and write to the target directory.
