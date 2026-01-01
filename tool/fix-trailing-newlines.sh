#!/bin/bash
# Fix trailing newlines in text files, ensuring each file ends with exactly one newline

set -e

# Define file extensions to process
FILE_EXTENSIONS=(
    "*.dart"
    "*.md"
    "*.yaml"
    "*.yml"
    "*.sh"
    "*.kt"
    "*.gradle"
    "*.properties"
    "*.json"
    "*.xml"
    "*.arb"
    "*.txt"
)

# Define directories to exclude
EXCLUDE_DIRS=(
    ".git"
    ".dart_tool"
    "build"
    ".idea"
    "node_modules"
    ".gradle"
    "android/build"
    "ios/Pods"
)

# Build exclusion arguments for find command
EXCLUDE_ARGS=()
for dir in "${EXCLUDE_DIRS[@]}"; do
    EXCLUDE_ARGS+=(-path "*/$dir" -prune -o)
done

# Build file extension arguments for find command
EXTENSION_ARGS=()
for ext in "${FILE_EXTENSIONS[@]}"; do
    if [ ${#EXTENSION_ARGS[@]} -eq 0 ]; then
        EXTENSION_ARGS+=(-name "$ext")
    else
        EXTENSION_ARGS+=(-o -name "$ext")
    fi
done

# Statistics variables
total_files=0
modified_files=0

echo "Scanning text files..."

# Find and process files
while IFS= read -r -d '' file; do
    total_files=$((total_files + 1))

    # Skip empty files
    if [ ! -s "$file" ]; then
        continue
    fi

    # Read last character of file
    last_char=$(tail -c 1 "$file")

    # Create temporary file
    temp_file=$(mktemp)

    # Remove all trailing empty lines
    sed -e :a -e '/^\s*$/d;N;ba' "$file" > "$temp_file"

    # Add one newline to the end (if file is not empty)
    if [ -s "$temp_file" ]; then
        # Check if newline needs to be added
        if [ -n "$(tail -c 1 "$temp_file")" ]; then
            echo "" >> "$temp_file"
        fi
    fi

    # Check if file was modified
    if ! cmp -s "$file" "$temp_file"; then
        mv "$temp_file" "$file"
        modified_files=$((modified_files + 1))
        echo "✓ Fixed: $file"
    else
        rm "$temp_file"
    fi

done < <(find . "${EXCLUDE_ARGS[@]}" \( "${EXTENSION_ARGS[@]}" \) -type f -print0)

echo ""
echo "========================================="
echo "Scan complete!"
echo "Total files: $total_files"
echo "Modified files: $modified_files"
echo "========================================="

