# Documentation for `merge-subfolders.sh`

## Overview

`script.sh` is a Bash script designed to search for sub-subdirectories within a specified directory and merge the contents of directories that share the same name into a single `MERGE` directory. If the merging process is successful, the original directories are deleted.

## Features

- Takes a single directory as input.
- Searches for all sub-subdirectories (two levels deep).
- Merges contents of directories with the same name into a `MERGE` directory (one level deep).
- Deletes original directories if the merging is successful.

## Usage

To run the script, use the following command:

```bash
./script.sh /path/to/directory
```

### Parameters

- `/path/to/directory`: The base directory where the script will search for sub-subdirectories.

## Requirements

- Bash shell
- `rsync` utility (for copying files)

## Script Breakdown

1. **Parameter Check**: The script checks if exactly one parameter is provided. If not, it displays usage instructions and exits.

2. **Directory Validation**: It verifies that the provided parameter is a valid directory. If not, it outputs an error message and exits.

3. **MERGE Directory Creation**: The script creates a `MERGE` directory within the base directory to store merged contents.

4. **Nullglob Option**: The `nullglob` option is enabled to ensure that patterns that do not match any files are removed rather than left as literal strings.

5. **Grouping Directories**: An associative array is used to group sub-subdirectories by their names. The script iterates through all directories at two levels of depth and populates the array.

6. **Merging Process**:
   - For each group of directories with the same name, the script checks if there is more than one directory.
   - If duplicates are found, it creates a target directory in the `MERGE` directory.
   - It then copies the contents of each source directory into the target directory using `rsync`.
   - If all copies are successful, the original directories are deleted. If any copy fails, the original directories are retained.

## Example

Given the following directory structure:

```
/path/to/directory/
├── subdir1/
│   ├── common/
│   │   └── file1.txt
│   └── unique1/
├── subdir2/
│   ├── common/
│   │   └── file2.txt
│   └── unique2/
└── subdir3/
    └── common/
        └── file3.txt
```

If `subdir1`, `subdir2`, and `subdir3` contain a subdirectory named `common`, the script will merge the contents of these `common` directories into:

```
/path/to/directory/MERGE/
└── common/
    ├── file1.txt
    ├── file2.txt
    └── file3.txt
```

After successful merging, the original `common` directories in `subdir1`, `subdir2`, and `subdir3` will be deleted.

## Error Handling

- If the provided directory does not exist or is not a directory, an error message is displayed.
- If any copy operation fails during the merging process, the script will not delete the original directories and will notify the user.