#!/bin/bash
# Normalize text files according to .editorconfig rules
#
# Features:
# - Ensure exactly one trailing newline
# - Use LF for most files; CRLF for Windows scripts (.bat/.cmd/.ps1)
# - Remove trailing whitespace from each line (except .md files)
# - By default, process only git tracked + modified files
#
# Usage:
#   bash .vscode/normalize_files.sh
#   bash .vscode/normalize_files.sh --all
#   bash .vscode/normalize_files.sh --paths lib test

set -e

# Directories to exclude
EXCLUDE_DIRS=(
    ".git"
    ".dart_tool"
    "build"
    ".idea"
    "node_modules"
    ".gradle"
    "android/build"
    "ios/Pods"
    ".fvm"
)

# Text file extensions to process
TEXT_EXTENSIONS=(
    # Source code files
    "*.dart"
    "*.kt"
    "*.java"
    "*.swift"
    "*.m"
    "*.mm"
    "*.h"
    "*.c"
    "*.cpp"
    "*.cc"
    # Configuration files
    "*.yaml"
    "*.yml"
    "*.json"
    "*.arb"
    "*.properties"
    "*.gradle"
    "*.xml"
    "*.plist"
    "*.toml"
    "*.ini"
    "*.cfg"
    "*.config"
    # Web files
    "*.html"
    "*.htm"
    "*.css"
    "*.js"
    "*.ts"
    # Documentation
    "*.md"
    "*.txt"
    "LICENSE"
    "NOTICE"
    "README"
    "CHANGELOG"
    "CONTRIBUTING"
    # Script files
    "*.sh"
    "*.bash"
    "*.zsh"
    "*.bat"
    "*.cmd"
    "*.ps1"
    # Build files
    "CMakeLists.txt"
    "Makefile"
    "*.cmake"
    "*.mk"
    # Git files
    ".gitignore"
    ".gitattributes"
    ".editorconfig"
)

# Files that should use CRLF
CRLF_EXTENSIONS=("*.bat" "*.cmd" "*.ps1")

# Files that should NOT trim trailing whitespace
NO_TRIM_EXTENSIONS=("*.md")

# Binary extensions to skip
BINARY_EXTENSIONS=(
    "*.png"
    "*.jpg"
    "*.jpeg"
    "*.gif"
    "*.ico"
    "*.pdf"
    "*.zip"
    "*.tar"
    "*.gz"
    "*.7z"
    "*.exe"
    "*.dll"
    "*.so"
    "*.dylib"
    "*.jks"
    "*.keystore"
    "*.ttf"
    "*.otf"
    "*.woff"
    "*.woff2"
    "*.wav"
    "*.mp3"
    "*.ogg"
)

# Parse arguments
MODE="git-dirty"
PATHS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            MODE="all"
            shift
            ;;
        --paths)
            shift
            while [[ $# -gt 0 ]] && [[ ! $1 =~ ^-- ]]; do
                PATHS+=("$1")
                shift
            done
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--all] [--paths path1 path2 ...]"
            exit 1
            ;;
    esac
done

# Check if file should use CRLF
should_use_crlf() {
    local file="$1"
    for ext in "${CRLF_EXTENSIONS[@]}"; do
        if [[ "$file" == $ext ]]; then
            return 0
        fi
    done
    return 1
}

# Check if file should NOT trim trailing whitespace
should_not_trim() {
    local file="$1"
    for ext in "${NO_TRIM_EXTENSIONS[@]}"; do
        if [[ "$file" == $ext ]]; then
            return 0
        fi
    done
    return 1
}

# Check if file is binary
is_binary() {
    local file="$1"
    for ext in "${BINARY_EXTENSIONS[@]}"; do
        if [[ "$file" == $ext ]]; then
            return 0
        fi
    done

    # Check if file contains null bytes (binary indicator)
    if grep -qI . "$file" 2>/dev/null; then
        return 1  # Text file
    else
        return 0  # Binary file
    fi
}

# Normalize a single file
normalize_file() {
    local file="$1"

    # Skip if file doesn't exist or is not a regular file
    if [[ ! -f "$file" ]]; then
        return 0
    fi

    # Skip binary files
    if is_binary "$file"; then
        return 0
    fi

    # Skip empty files
    if [[ ! -s "$file" ]]; then
        return 0
    fi

    local temp_file
    temp_file=$(mktemp)
    local modified=false

    # Determine processing rules based on file extension
    local use_crlf=false
    local trim_whitespace=true

    if should_use_crlf "$file"; then
        use_crlf=true
    fi

    if should_not_trim "$file"; then
        trim_whitespace=false
    fi

    # Read file and normalize
    # 1. Convert all line endings to LF
    # 2. Remove trailing whitespace from each line (if applicable)
    # 3. Remove all trailing empty lines
    # 4. Add exactly one newline at the end
    # 5. Convert to CRLF if needed

    if [[ "$trim_whitespace" == true ]]; then
        # Remove trailing whitespace from each line
        sed 's/[[:space:]]*$//' "$file" > "$temp_file"
    else
        cp "$file" "$temp_file"
    fi

    # Remove all trailing newlines and add exactly one
    # Using perl for more reliable processing
    perl -i -pe 'chomp if eof' "$temp_file"
    echo "" >> "$temp_file"

    # Convert to CRLF if needed
    if [[ "$use_crlf" == true ]]; then
        unix2dos "$temp_file" 2>/dev/null || sed -i 's/$/\r/' "$temp_file"
    fi

    # Check if file was modified
    if ! cmp -s "$file" "$temp_file"; then
        mv "$temp_file" "$file"
        echo "✓ Normalized: $file"
        return 1  # Modified
    else
        rm -f "$temp_file"
        return 0  # Not modified
    fi
}

# Get list of files to process
get_files_to_process() {
    local files=()

    if [[ "$MODE" == "all" ]]; then
        # Process all text files in specified paths or workspace root
        if [[ ${#PATHS[@]} -eq 0 ]]; then
            PATHS=(".")
        fi

        # Build find exclusion arguments
        local exclude_args=()
        for dir in "${EXCLUDE_DIRS[@]}"; do
            exclude_args+=(-path "*/$dir" -prune -o)
        done

        # Build extension arguments
        local ext_args=()
        for ext in "${TEXT_EXTENSIONS[@]}"; do
            if [[ ${#ext_args[@]} -eq 0 ]]; then
                ext_args+=(-name "$ext")
            else
                ext_args+=(-o -name "$ext")
            fi
        done

        # Find all matching files
        while IFS= read -r -d '' file; do
            files+=("$file")
        done < <(find "${PATHS[@]}" "${exclude_args[@]}" \( "${ext_args[@]}" \) -type f -print0)
    else
        # Process only git modified files
        while IFS= read -r file; do
            if [[ -f "$file" ]]; then
                files+=("$file")
            fi
        done < <(git diff --name-only --diff-filter=M)
    fi

    printf '%s\n' "${files[@]}"
}

# Main processing
main() {
    local fixed=0
    local skipped=0
    local total=0

    echo "Scanning files (mode: $MODE)..."

    # Get list of files
    mapfile -t files < <(get_files_to_process)
    total=${#files[@]}

    if [[ $total -eq 0 ]]; then
        echo "No files to process."
        return 0
    fi

    echo "Processing $total files..."

    # Process each file
    for file in "${files[@]}"; do
        if normalize_file "$file"; then
            skipped=$((skipped + 1))
        else
            fixed=$((fixed + 1))
        fi
    done

    echo ""
    echo "========================================="
    echo "Normalization complete!"
    echo "Total files: $total"
    echo "Modified: $fixed"
    echo "Unchanged: $skipped"
    echo "Mode: $MODE"
    echo "========================================="
}

main
